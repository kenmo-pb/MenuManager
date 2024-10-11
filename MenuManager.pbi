; +-------------+
; | MenuManager |
; +-------------+
; | 2020-01-27 : Creation (PureBasic 5.71)

;-
CompilerIf (Not Defined(_MenuManager_Included, #PB_Constant))
#_MenuManager_Included = #True

;- Compile Switches

CompilerIf (Not Defined(MenuManager_UseXMLParser, #PB_Constant))
  #MenuManager_UseXMLParser = #True
CompilerEndIf

CompilerIf (Not Defined(MenuManager_UseExpatXMLParser, #PB_Constant))
  #MenuManager_UseExpatXMLParser = #False
CompilerEndIf

CompilerIf (Not Defined(MenuManager_DisableDebugWarnings, #PB_Constant))
  #MenuManager_DisableDebugWarnings = #False
CompilerEndIf

CompilerIf (Not Defined(MenuManager_IncludeShortcutRequester, #PB_Constant))
  #MenuManager_IncludeShortcutRequester = #True
CompilerEndIf

CompilerIf (Not Defined(MenuManager_IgnoreImageErrors, #PB_Constant))
  #MenuManager_IgnoreImageErrors = #False
CompilerEndIf

CompilerIf (Not Defined(MenuManager_UseNetworkImages, #PB_Constant))
  #MenuManager_UseNetworkImages = #False
CompilerEndIf

CompilerIf (Not Defined(MenuManager_SkipFailedDomains, #PB_Constant))
  #MenuManager_SkipFailedDomains = #False
CompilerEndIf

CompilerIf (Not Defined(_MenuManager_OS, #PB_Constant))
  CompilerSelect (#PB_Compiler_OS)
    CompilerCase (#PB_OS_Windows)
      #_MenuManager_OS = #PB_OS_Windows
    CompilerCase (#PB_OS_MacOS)
      #_MenuManager_OS = #PB_OS_MacOS
    CompilerCase (#PB_OS_Linux)
      #_MenuManager_OS = #PB_OS_Linux
  CompilerEndSelect
CompilerEndIf

CompilerSelect (#_MenuManager_OS)
  CompilerCase (#PB_OS_Windows)
    #_MenuManager_OSPrefix = "win"
  CompilerCase (#PB_OS_MacOS)
    #_MenuManager_OSPrefix = "mac"
  CompilerCase (#PB_OS_Linux)
    #_MenuManager_OSPrefix = "linux"
CompilerEndSelect

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf


;-
;- Compiler Checks

CompilerIf (#PB_Compiler_Version < 510)
  CompilerError #PB_Compiler_Filename + " requires PureBasic 5.10+"
CompilerEndIf

;-
;- Includes

XIncludeFile "MenuManager-Errors.pbi"
XIncludeFile "MenuManager-Shortcuts.pbi"
CompilerIf (#MenuManager_IncludeShortcutRequester)
  XIncludeFile "MenuManager-Requester.pbi"
CompilerEndIf
CompilerIf (#MenuManager_UseXMLParser And (Not #MenuManager_UseExpatXMLParser))
  XIncludeFile "MenuManager-XMLParser.pbi"
CompilerEndIf

;-
;- Constants - Public

Enumeration ; MenuManager Item Flags
  #MMIF_Locked    = $01
  #MMIF_DontAdd   = $02
  #MMIF_NoGUI     = $04
  #MMIF_NoPrefs   = $08
  #MMIF_PostClose = $10
EndEnumeration

;-
;- Constants - Private

#_MenuManager_Escape  = "_"
#_MenuManager_Escape2 = #_MenuManager_Escape + #_MenuManager_Escape

Enumeration ; Build Action
  #_MMBD_Title
  #_MMBD_Item
  #_MMBD_Bar
  #_MMBD_OpenSub
  #_MMBD_CloseSub
  #_MMBD_Callback
  #_MMBD_Hide
  #_MMBD_Unhide
EndEnumeration

Enumeration
  #_MM_Assigned
  #_MM_Default
  #_MM_GUI
  ;
  #_MM_ShortcutTypes
EndEnumeration

;-
;- Prototypes

Prototype.s _MenuManager_Translator(Text.s, MMID.s)

;-
;- Structures

Structure MenuManagerAddedShortcut
  Window.i
  Shortcut.i
EndStructure

Structure MenuManagerBind
  Callback.i
  Window.i
  Object.i
EndStructure

Structure MenuManagerItem
  Name.s
  MMID.s
  MMIDOrigCase.s
  Number.i
  ImageID.i
  Group.s
  Flags.i
  ;
  Shortcut.i[#_MM_ShortcutTypes]
  ;
  Callback.i
EndStructure

Structure MenuManagerAction
  Type.i
  Name.s
  MMID.s
  *Item.MenuManagerItem
EndStructure

Structure MenuManagerMenu
  MMID.s
  List Action.MenuManagerAction()
EndStructure

Structure MenuManager
  NextAutoNumber.i
  HasImages.i
  Translate._MenuManager_Translator
  BuildGroup.s
  BuildingPopup.i
  *SelItem.MenuManagerItem
  ;
  List Item.MenuManagerItem()
  List Menu.MenuManagerMenu()
  List Added.MenuManagerAddedShortcut()
  List Bind.MenuManagerBind()
  Map Image.i()
  ;
  CompilerIf (#MenuManager_UseNetworkImages And #MenuManager_SkipFailedDomains)
    Map FailedDomain.i()
  CompilerEndIf
EndStructure

;-
;- Globals

Global *_MenuManager.MenuManager = #Null

Global NewList _MenuManager_GlobalBind.MenuManagerBind()

Global NewMap _MenuManager_Runtime.i()

;-
;- Macros - Private

Macro _MenuManager_Warn(Message)
  CompilerIf (Not #MenuManager_DisableDebugWarnings)
    Debug "MenuManager: Warning: " + Message
  CompilerEndIf
EndMacro

CompilerIf (#PB_Compiler_Version >= 600)
  Macro _MenuManager_InitNetwork()
    (#True)
  EndMacro
CompilerElse
  Macro _MenuManager_InitNetwork()
    InitNetwork()
  EndMacro
CompilerEndIf

;-
;- Procedures - Private

Procedure.s _MenuManager_Normalize(MMID.s, PreserveCase.i = #False)
  MMID = RemoveString(MMID, ".")
  MMID = RemoveString(MMID, "!")
  MMID = RemoveString(MMID, "?")
  MMID = Trim(MMID)
  MMID = ReplaceString(MMID, " ", "-")
  MMID = ReplaceString(MMID, "&", "-")
  If (Not PreserveCase)
    MMID = LCase(MMID)
  EndIf
  ProcedureReturn (MMID)
EndProcedure

Procedure.s _MenuManager_RemoveUnderline(Name.s, ForMenuItem.i)
  Name = ReplaceString(Name, #_MenuManager_Escape2, #DC4$)
  Name = RemoveString(Name, #_MenuManager_Escape)
  If (ForMenuItem)
    CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
      Name = ReplaceString(Name, "&", "&&")
    CompilerEndIf
    CompilerIf (#PB_Compiler_Unicode)
      Name = ReplaceString(Name, "...", Chr($2026))
    CompilerEndIf
  EndIf
  Name = ReplaceString(Name, #DC4$, #_MenuManager_Escape)
  ProcedureReturn (Name)
EndProcedure

Procedure.s _MenuManager_PrepareUnderline(Name.s)
  Name = ReplaceString(Name, #_MenuManager_Escape2, #DC4$)
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Name = ReplaceString(Name, "&", #DC3$)
    Name = ReplaceString(Name, #_MenuManager_Escape, "&")
    Name = ReplaceString(Name, #DC3$, "&&")
  CompilerElse
    Name = RemoveString(Name, #_MenuManager_Escape)
  CompilerEndIf
  CompilerIf (#PB_Compiler_Unicode)
    Name = ReplaceString(Name, "...", Chr($2026))
  CompilerEndIf
  Name = ReplaceString(Name, #DC4$, #_MenuManager_Escape)
  ProcedureReturn (Name)
EndProcedure

Procedure.s _MenuManager_EscapePlainText(Text.s)
  ProcedureReturn (ReplaceString(Text, #_MenuManager_Escape, #_MenuManager_Escape2))
EndProcedure

Procedure _MenuManager_PostCloseCB()
  PostEvent(#PB_Event_CloseWindow, EventWindow(), EventMenu())
EndProcedure

Procedure _MenuManager_RemoveShortcuts(*MM.MenuManager, Window.i = #PB_All)
  ForEach (*MM\Added())
    If ((Window = #PB_All) Or (*MM\Added()\Window = Window))
      RemoveKeyboardShortcut(*MM\Added()\Window, *MM\Added()\Shortcut)
      DeleteElement(*MM\Added())
    EndIf
  Next
EndProcedure

Procedure _MenuManager_RemoveBinds(*MM.MenuManager, Window.i = #PB_All)
  If (*MM)
    ForEach (*MM\Bind())
      If ((Window = #PB_All) Or (*MM\Bind()\Window = Window))
        UnbindEvent(#PB_Event_Menu, *MM\Bind()\Callback, *MM\Bind()\Window, *MM\Bind()\Object)
        DeleteElement(*MM\Bind())
      EndIf
    Next
  EndIf
  ForEach (_MenuManager_GlobalBind())
    If ((Window = #PB_All) Or (_MenuManager_GlobalBind()\Window = Window))
      UnbindEvent(#PB_Event_Menu, _MenuManager_GlobalBind()\Callback, _MenuManager_GlobalBind()\Window, _MenuManager_GlobalBind()\Object)
      DeleteElement(_MenuManager_GlobalBind())
    EndIf
  Next
EndProcedure

Procedure _MenuManager_AddShortcut(*MM.MenuManager, *Item.MenuManagerItem, Window.i)
  If (*Item\Shortcut[#_MM_Assigned])
    AddKeyboardShortcut(Window, *Item\Shortcut[#_MM_Assigned], *Item\Number)
    AddElement(*MM\Added())
    *MM\Added()\Window = Window
    *MM\Added()\Shortcut = *Item\Shortcut[#_MM_Assigned]
  EndIf
EndProcedure

Procedure _MenuManager_AddBind(*MM.MenuManager, *Item.MenuManagerItem, Window.i)
  BindEvent(#PB_Event_Menu, *Item\Callback, Window, *Item\Number)
  AddElement(*MM\Bind())
  *MM\Bind()\Callback = *Item\Callback
  *MM\Bind()\Window = Window
  *MM\Bind()\Object = *Item\Number
EndProcedure

Procedure _MenuManager_CopyShortcuts(*MM.MenuManager, SourceType.i, DestType.i)
  If (*MM)
    ForEach (*MM\Item())
      If (*MM\Item()\Flags & #MMIF_Locked)
        *MM\Item()\Shortcut[DestType] = *MM\Item()\Shortcut[#_MM_Default]
      Else
        *MM\Item()\Shortcut[DestType] = *MM\Item()\Shortcut[SourceType]
      EndIf
    Next
  EndIf
EndProcedure

Procedure.i _MenuManager_IsShortcutUsed(*MM.MenuManager, Shortcut.i, Type.i, IgnoreMMID.s)
  Protected Result.i = #False
  If (Shortcut)
    If (*MM)
      IgnoreMMID = _MenuManager_Normalize(IgnoreMMID)
      ForEach (*MM\Item())
        If (*MM\Item()\Shortcut[Type] = Shortcut)
          If (*MM\Item()\MMID <> IgnoreMMID)
            Result = @*MM\Item();#True
            Break
          EndIf
        EndIf
      Next
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ShortcutsDiffer(*MM.MenuManager, Type1.i, Type2.i)
  Protected Result.i = #False
  If (*MM)
    ForEach (*MM\Item())
      If (*MM\Item()\Shortcut[Type1] <> *MM\Item()\Shortcut[Type2])
        Result = #True
        Break
      EndIf
    Next
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_SetShortcut(*MM.MenuManager, *Item.MenuManagerItem, Shortcut.i, Type.i)
  Protected Result.i = #False ; Return #True if duplicate(s) removed
  
  If (*Item\Flags & #MMIF_Locked)
    Shortcut = *Item\Shortcut[#_MM_Default]
  EndIf
  
  If (Shortcut) ; Shortcut set, so remove duplicates
    ForEach (*MM\Item())
      If (@*MM\Item() = *Item) ; Found item
        *MM\Item()\Shortcut[Type] = Shortcut
      ElseIf (*MM\Item()\Shortcut[Type] = Shortcut) ; Duplicate shortcut found!
        Result = #True
        *MM\Item()\Shortcut[Type] = #Null
      EndIf
    Next
  Else ; Blank (remove shortcut)
    *Item\Shortcut[Type] = #Null
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ItemByMMID(*MM.MenuManager, MMID.s)
  Protected *Item.MenuManagerItem = #Null
  ForEach (*MM\Item())
    If (*MM\Item()\MMID = MMID)
      *Item = @*MM\Item()
      Break
    EndIf
  Next
  ProcedureReturn (*Item)
EndProcedure

Procedure.i _MenuManager_AssignShortcut(*MM.MenuManager, MMID.s, Shortcut.i, GUIOnly.i)
  Protected Result.i = #False
  Protected *Item.MenuManagerItem = _MenuManager_ItemByMMID(*_MenuManager, MMID)
  If (*Item)
    If ((Not (*Item\Flags & #MMIF_Locked)) Or (Shortcut = *Item\Shortcut[#_MM_Default]))
      Protected Type.i
      If (GUIOnly)
        Type = #_MM_GUI
      Else
        Type = #_MM_Assigned
      EndIf
      Protected *Conflict.MenuManagerItem = #Null
      If (Shortcut)
        *Conflict = _MenuManager_IsShortcutUsed(*MM, Shortcut, Type, MMID)
      EndIf
      If ((Shortcut = #Null) Or (*Conflict = #Null) Or (Not (*Conflict\Flags & #MMIF_Locked)))
        *Item\Shortcut[Type] = Shortcut
        Result = #True
        If (*Conflict)
          *Conflict\Shortcut[Type] = #Null
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_Free(*MM.MenuManager)
  If (*MM)
    If (#False)
      _MenuManager_RemoveShortcuts(*MM, #PB_All)
    EndIf
    If (#True)
      _MenuManager_RemoveBinds(*MM, #PB_All)
    EndIf
    
    ForEach *MM\Menu()
      ClearList(*MM\Menu()\Action())
    Next
    ForEach *MM\Item()
      ; ...
    Next
    ForEach *MM\Image()
      FreeImage(*MM\Image())
    Next
    
    *MM\SelItem = #Null
    ClearList(*MM\Menu())
    FreeList(*MM\Menu())
    ClearMap(*MM\Image())
    FreeMap(*MM\Image())
    ClearList(*MM\Item())
    FreeList(*MM\Item())
    
    ClearStructure(*MM, MenuManager)
    FreeMemory(*MM)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i _MenuManager_ParseFlags(Text.s)
  Protected Result.i = #Null
  If (Text)
    Text = LCase("," + ReplaceString(Text, " ", ",") + ",")
    Protected N.i = 1 + CountString(Text, ",")
    Protected i.i
    For i = 1 To N
      Select (StringField(Text, i, ","))
        Case "noadd", "dontadd"
          Result | #MMIF_DontAdd
        Case "locked", "lock", "fixed"
          Result | #MMIF_Locked
        Case "nogui", "notgui", "nongui"
          Result | #MMIF_NoGUI
        Case "noprefs", "nopref"
          Result | #MMIF_NoPrefs
        Case "close", "postclose"
          Result | #MMIF_PostClose
        Case "null", "none"
          ;
        Default
          ;
      EndSelect
    Next i
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseNumber(*MM.MenuManager, Text.s)
  Protected Result.i
  Select (Asc(Text))
    Case 'a' To 'z', 'A' To 'Z', '_', '#'
      If (FindMapElement(_MenuManager_Runtime(), LCase(Text)))
        Result = _MenuManager_Runtime()
      ElseIf (IsRuntime(Text))
        Result = GetRuntimeInteger(Text)
      Else
        _MenuManager_SetLastError(#MenuManager_Error_MissingRuntime, Text)
      EndIf
    Case '0' To '9', '$', '%'
      Result = Val(Text)
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseExpression(Text.s, IsLHS.i, *MM.MenuManager)
  Protected Result.i = #False
  Select (UCase(RemoveString(Text, "!")))
    Case "1", "T", "TRUE", "YES", "Y", "ENABLE", "ENABLED", "ON"
      Result = #True
    Case "0", "F", "FALSE", "NO", "N", "DISABLE", "DISABLED", "OFF"
      Result = #False
    Case "WIN", "WINDOWS"
      If (IsLHS)
        Result = Bool(#_MenuManager_OS = #PB_OS_Windows)
      Else
        Result = #PB_OS_Windows
      EndIf
    Case "MAC", "MACOS", "OSX"
      If (IsLHS)
        Result = Bool(#_MenuManager_OS = #PB_OS_MacOS)
      Else
        Result = #PB_OS_MacOS
      EndIf
    Case "LIN", "LINUX"
      If (IsLHS)
        Result = Bool(#_MenuManager_OS = #PB_OS_Linux)
      Else
        Result = #PB_OS_Linux
      EndIf
    Case "OS"
      Result = #_MenuManager_OS
    Default
      Result = _MenuManager_ParseNumber(*MM, Text)
  EndSelect
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseImage(*MM.MenuManager, Text.s)
  Protected Img.i, ImgID.i
  
  If (Left(Text, 1) = "#")
    If (IsRuntime(Text))
      Img = GetRuntimeInteger(Text)
      ImgID = ImageID(Img)
    Else
      CompilerIf (Not #MenuManager_IgnoreImageErrors)
        _MenuManager_SetLastError(#MenuManager_Error_MissingRuntime, Text)
      CompilerEndIf
    EndIf
  ElseIf ((Left(Text, 1) = "@") Or (FindString(Text, ".")))
    Text = LTrim(Text, "@")
    If ((#True) And (FindMapElement(*MM\Image(), Text)))
      Img = *MM\Image()
      ImgID = ImageID(Img)
    ElseIf (FileSize(Text) >= 0)
      Img = LoadImage(#PB_Any, Text)
      If (Img)
        AddMapElement(*MM\Image(), Text)
        *MM\Image() = Img
        ImgID = ImageID(Img)
      Else
        CompilerIf (Not #MenuManager_IgnoreImageErrors)
          _MenuManager_SetLastError(#MenuManager_Error_DecodeImage, Text)
        CompilerEndIf
      EndIf
    ElseIf (FindString(Text, "://"))
      CompilerIf (#MenuManager_UseNetworkImages)
        If (_MenuManager_InitNetwork())
          Protected Domain.s = LCase(GetURLPart(Text, #PB_URL_Protocol) + "://" + GetURLPart(Text, #PB_URL_Site))
          Protected Skip.i = #False
          CompilerIf (#MenuManager_SkipFailedDomains)
            If (FindMapElement(*MM\FailedDomain(), Domain))
              Skip = #True
            EndIf
          CompilerEndIf
          If (Not Skip)
            Protected TempFile.s = GetFilePart(GetURLPart(Text, #PB_URL_Path))
            TempFile = GetTemporaryDirectory() + TempFile
            If (ReceiveHTTPFile(Text, TempFile))
              Img = LoadImage(#PB_Any, TempFile)
              If (Img)
                AddMapElement(*MM\Image(), Text)
                *MM\Image() = Img
                ImgID = ImageID(Img)
              Else
                CompilerIf (Not #MenuManager_IgnoreImageErrors)
                  _MenuManager_SetLastError(#MenuManager_Error_DecodeImage, Text)
                CompilerEndIf
              EndIf
              DeleteFile(TempFile)
            Else
              CompilerIf (#MenuManager_SkipFailedDomains)
                AddMapElement(*MM\FailedDomain(), Domain)
              CompilerEndIf
              CompilerIf (Not #MenuManager_IgnoreImageErrors)
                _MenuManager_SetLastError(#MenuManager_Error_DownloadFailed, Text)
              CompilerEndIf
            EndIf
          EndIf
        Else
          CompilerIf (Not #MenuManager_IgnoreImageErrors)
            _MenuManager_SetLastError(#MenuManager_Error_NetworkFailed)
          CompilerEndIf
        EndIf
      CompilerElse
        CompilerIf (Not #MenuManager_IgnoreImageErrors)
          _MenuManager_SetLastError(#MenuManager_Error_NetworkDisabled, Text)
        CompilerEndIf
      CompilerEndIf
    EndIf
  Else
    Select (LCase(Text))
      Case "null", "none", ""
        ;
      Default
        Img = Val(Text)
        ImgID = ImageID(Img)
    EndSelect
  EndIf
  
  ProcedureReturn (ImgID)
EndProcedure

Procedure.i _MenuManager_ParseCallback(*MM.MenuManager, Text.s)
  Protected Result.i = #Null
  Select (LCase(Text))
    Case "null", "none", ""
      ;
    Default
      Protected Proc.s = Text
      Proc = RemoveString(Proc, " ")
      Proc = RemoveString(Proc, ";")
      If (Proc)
        If (Not FindString(Proc, "()"))
          Proc + "()"
        EndIf
        If (IsRuntime(Proc))
          Result = GetRuntimeInteger(Proc)
        Else
          _MenuManager_SetLastError(#MenuManager_Error_MissingRuntime, Text)
        EndIf
      EndIf
  EndSelect
  ProcedureReturn (Result)
EndProcedure




;- ______________________________
;- _____  XML Parser Start  _____
CompilerIf (#MenuManager_UseXMLParser)

CompilerIf (#MenuManager_UseExpatXMLParser)

Macro _MM_ChildXMLNode(_Node, _n = 1)
  ChildXMLNode(_Node, _n)
EndMacro

Macro _MM_ComposeXML(_XML, _Flags = 0)
  ComposeXML(_XML, _Flags)
EndMacro

Macro _MM_ExamineXMLAttributes(_Node)
  ExamineXMLAttributes(_Node)
EndMacro

Macro _MM_FreeXML(_XML)
  FreeXML(_XML)
EndMacro

Macro _MM_GetXMLAttribute(_Node, _Attribute)
  GetXMLAttribute(_Node, _Attribute)
EndMacro

Macro _MM_GetXMLNodeName(_Node)
  GetXMLNodeName(_Node)
EndMacro

Macro _MM_NextXMLAttribute(_Node)
  NextXMLAttribute(_Node)
EndMacro

Macro _MM_NextXMLNode(_Node)
  NextXMLNode(_Node)
EndMacro

Macro _MM_ParseXML(_Input)
  ParseXML(#PB_Any, _Input)
EndMacro

Macro _MM_RootXMLNode(_XML)
  RootXMLNode(_XML)
EndMacro

Macro _MM_XMLAttributeName(_Node)
  XMLAttributeName(_Node)
EndMacro

Macro _MM_XMLAttributeValue(_Node)
  XMLAttributeValue(_Node)
EndMacro

Macro _MM_XMLNodeFromPath(_ParentNode, _Path)
  XMLNodeFromPath(_ParentNode, _Path)
EndMacro

Macro _MM_XMLNodeType(_Node)
  XMLNodeType(_Node)
EndMacro

Macro _MM_XMLStatus(_XML)
  XMLStatus(_XML)
EndMacro

CompilerEndIf

Procedure.i _MenuManager_IfTest(*Node, *MM.MenuManager)
  Protected Result.i = #False
  If (_MM_ExamineXMLAttributes(*Node))
    While (_MM_NextXMLAttribute(*Node))
      Protected Name.s = _MM_XMLAttributeName(*Node)
      Protected Value.s = _MM_XMLAttributeValue(*Node)
      If (_MenuManager_ParseExpression(Name, #True, *MM) = _MenuManager_ParseExpression(Value, #False, *MM))
        Result = #True
        Break
      EndIf
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s _MenuManager_GetOSOrGenericAttribute(*Node, Attribute.s)
  Protected Result.s = ""
  If (*Node And Attribute)
    Protected Text.s = _MM_GetXMLAttribute(*Node, #_MenuManager_OSPrefix + Attribute)
    If (Text <> "")
      Result = Text
    Else
      Result = _MM_GetXMLAttribute(*Node, Attribute)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseXMLMenus(*MM.MenuManager, *Menu.MenuManagerMenu, *Node, DisallowTitles.i = #False)
  Protected Result.i = #True
  
  Protected *Child = _MM_ChildXMLNode(*Node)
  Protected ID.s
  While (*Child)
    If (_MM_XMLNodeType(*Child) = #PB_XML_Normal)
      Protected Name.s = LCase(Trim(_MM_GetXMLNodeName(*Child)))
      Select (Name)
        
        Case "menu"
          If (*Menu = #Null)
            *Menu = AddElement(*MM\Menu())
            *Menu\MMID = _MM_GetXMLAttribute(*Child, "mmid")
            *Menu\MMID = _MenuManager_Normalize(*Menu\MMID)
            If (*Menu\MMID)
              If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Child, #False))
                Result = #False
                Break
              EndIf
            Else
              Result = #False
              _MenuManager_SetLastError(#MenuManager_Error_NoMenuID)
              Break
            EndIf
            
            ; Reset *Menu to parse another <menu>
            *Menu = #Null
          Else
            Result = #False
            _MenuManager_SetLastError(#MenuManager_Error_MenuNotAllowed)
            Break
          EndIf
        
        Case "title"
          If (Not DisallowTitles)
            AddElement(*Menu\Action())
            *Menu\Action()\Type = #_MMBD_Title
            *Menu\Action()\Name = _MenuManager_GetOSOrGenericAttribute(*Child, "name")
            *Menu\Action()\MMID = _MM_GetXMLAttribute(*Child, "mmid")
            If (*Menu\Action()\MMID = "")
              *Menu\Action()\MMID = _MenuManager_RemoveUnderline(*Menu\Action()\Name, #False)
            EndIf
            *Menu\Action()\MMID = _MenuManager_Normalize(*Menu\Action()\MMID)
            If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Child, #True))
              Result = #False
              Break
            EndIf
          Else
            Result = #False
            _MenuManager_SetLastError(#MenuManager_Error_TitleNotAllowed)
            Break
          EndIf
          
        Case "hidden"
          If (Not DisallowTitles)
            AddElement(*Menu\Action())
            *Menu\Action()\Type = #_MMBD_Hide
            If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Child, #True))
              Result = #False
              Break
            EndIf
            AddElement(*Menu\Action())
            *Menu\Action()\Type = #_MMBD_Unhide
          Else
            Result = #False
            _MenuManager_SetLastError(#MenuManager_Error_HiddenNotAllowed)
            Break
          EndIf
          
        Case "item"
          Protected N.i
          Protected Value.s = _MenuManager_GetOSOrGenericAttribute(*Child, "N")
          If (Value)
            N = _MenuManager_ParseNumber(*MM, Value)
            If (_MenuManager_LastError)
              Result = #False
              Break 1
            ElseIf (N < 1)
              Result = #False
              _MenuManager_SetLastError(#MenuManager_Error_GroupSizeInvalid, Value)
              Break 1
            EndIf
          Else
            N = 1
          EndIf
          
          Protected i.i
          For i = 1 To N
            AddElement(*Menu\Action())
            *Menu\Action()\Type = #_MMBD_Item
            *Menu\Action()\Name = _MenuManager_GetOSOrGenericAttribute(*Child, "name")
            ID = _MM_GetXMLAttribute(*Child, "mmid")
            If (ID = "")
              ID = _MenuManager_RemoveUnderline(*Menu\Action()\Name, #False)
            EndIf
            If (N > 1)
              If (*Menu\Action()\Name)
                *Menu\Action()\Name + " " + Str(i)
              EndIf
              If (ID)
                ID + Str(i)
              EndIf
            EndIf
            If (ID)
              ID = _MenuManager_Normalize(ID)
              *Menu\Action()\Item = _MenuManager_ItemByMMID(*MM, ID)
            EndIf
            If (Not *Menu\Action()\Item)
              Result = #False
              If (ID)
                _MenuManager_SetLastError(#MenuManager_Error_MissingItem, ID)
              Else
                _MenuManager_SetLastError(#MenuManager_Error_NoItemID)
              EndIf
              Break 2
            EndIf
          Next i
        
        Case "sub"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_OpenSub
          *Menu\Action()\Name = _MenuManager_GetOSOrGenericAttribute(*Child, "name")
          *Menu\Action()\MMID = _MM_GetXMLAttribute(*Child, "mmid")
          If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Child, #True))
            Result = #False
            Break
          EndIf
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_CloseSub
          
        Case "bar"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Bar
        
        Case "call"
          Protected *Callback
          Value = _MenuManager_GetOSOrGenericAttribute(*Child, "callback")
          *Callback = _MenuManager_ParseCallback(*MM, Value)
          If (Not _MenuManager_LastError)
            If (*Callback)
              AddElement(*Menu\Action())
              *Menu\Action()\Type = #_MMBD_Callback
              *Menu\Action()\Item = *Callback
            EndIf
          Else
            Result = #False
            Break
          EndIf
        
        Case "if"
          If (_MenuManager_IfTest(*Child, *MM))
            If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Child, DisallowTitles))
              Result = #False
              Break
            EndIf
          Else
            Protected *Else = _MM_XMLNodeFromPath(*Child, "else")
            If (*Else)
              If (Not _MenuManager_ParseXMLMenus(*MM, *Menu, *Else, DisallowTitles))
                Result = #False
                Break
              EndIf
            EndIf
          EndIf
        
        Case "else"
          ;
        
        Default
          _MenuManager_Warn("Unrecognized node '" + Name + "'")
        
      EndSelect
    EndIf
    *Child = _MM_NextXMLNode(*Child)
  Wend
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseXMLItems(*MM.MenuManager, *Node)
  Protected Result.i = #True
  
  Protected Value.s
  Protected *Child
  *Child = _MM_ChildXMLNode(*Node)
  While (*Child)
    
    If (_MM_XMLNodeType(*Child) = #PB_XML_Normal)
      Protected Name.s = LCase(Trim(_MM_GetXMLNodeName(*Child)))
      
      If (Name = "item")
        Protected N.i
        Value = _MenuManager_GetOSOrGenericAttribute(*Child, "N")
        If (Value)
          N = _MenuManager_ParseNumber(*MM, Value)
          If (_MenuManager_LastError)
            Result = #False
            Break 1
          ElseIf (N < 1)
            Result = #False
            _MenuManager_SetLastError(#MenuManager_Error_GroupSizeInvalid, Value)
            Break 1
          EndIf
        Else
          N = 1
        EndIf
        
        Protected *First.MenuManagerItem
        Protected BaseName.s, BaseMMID.s
        Protected i.i
        For i = 1 To N
          Protected *Item.MenuManagerItem
          *Item = AddElement(*MM\Item())
          *Item\Group = *MM\BuildGroup
          
          If (i = 1) ; This is a standalone item, or the first in a group
            *Item\Name = _MenuManager_GetOSOrGenericAttribute(*Child, "name")
            *Item\MMID = _MM_GetXMLAttribute(*Child, "mmid")
            If (*Item\MMID = "")
              *Item\MMID = _MenuManager_RemoveUnderline(*Item\Name, #False)
            EndIf
            *Item\MMIDOrigCase = _MenuManager_Normalize(*Item\MMID, #True)
            *Item\MMID = _MenuManager_Normalize(*Item\MMID)
            If (*Item\MMID = "")
              Result = #False
              _MenuManager_SetLastError(#MenuManager_Error_NoItemID)
              Break 2
            EndIf
            
            Value = _MenuManager_GetOSOrGenericAttribute(*Child, "number")
            If (Value)
              *Item\Number = _MenuManager_ParseNumber(*MM, Value)
              If (_MenuManager_LastError)
                Result = #False
                Break 2
              EndIf
            Else
              *Item\Number = *MM\NextAutoNumber
              *MM\NextAutoNumber + 1
            EndIf
            
            Value = _MenuManager_GetOSOrGenericAttribute(*Child, "callback")
            If (Value)
              *Item\Callback = _MenuManager_ParseCallback(*MM, Value)
              If (_MenuManager_LastError)
                Result = #False
                Break 2
              EndIf
            EndIf
            
            Value = _MenuManager_GetOSOrGenericAttribute(*Child, "flags")
            If (Value)
              *Item\Flags = _MenuManager_ParseFlags(Value)
            EndIf
            
            Value = _MenuManager_GetOSOrGenericAttribute(*Child, "image")
            If (Value)
              *Item\ImageID = _MenuManager_ParseImage(*MM, Value)
              If (_MenuManager_LastError)
                Result = #False
                Break 2
              ElseIf (*Item\ImageID)
                *MM\HasImages = #True
              EndIf
            EndIf
            
            *Item\Shortcut[#_MM_Default] = ParseShortcut(_MenuManager_GetOSOrGenericAttribute(*Child, "shortcut"))
            If (*Item\Shortcut[#_MM_Default])
              If (_MenuManager_SetShortcut(*MM, *Item, *Item\Shortcut[#_MM_Default], #_MM_Assigned))
                Result = #False
                _MenuManager_SetLastError(#MenuManager_Error_DuplicateShortcut, ComposeShortcut(*Item\Shortcut[#_MM_Assigned]))
                Break 2
              EndIf
            EndIf
            
            *First     = *Item
            BaseName   = *Item\Name
            BaseMMID   = *Item\MMIDOrigCase
          
          Else ; This is a subsequent item in a group (extrapolate from first)
            *Item\Name         = BaseName
            *Item\MMIDOrigCase = BaseMMID
            *Item\MMID         = _MenuManager_Normalize(*Item\MMIDOrigCase)
            *Item\Number       = *First\Number + (i - 1)
            
            *Item\Callback = *First\Callback
            *Item\Flags    = *First\Flags
            *Item\ImageID  = *First\ImageID
            
            *Item\Shortcut[#_MM_Default]  = #Null
            *Item\Shortcut[#_MM_Assigned] = #Null
          EndIf
          
          ; Bump NextAutoNumber
          If (*Item\Number >= *MM\NextAutoNumber)
            *MM\NextAutoNumber = *Item\Number + 1
          EndIf
          
          ; If in a group, append index to Name and MMID
          If (N > 1)
            If (*Item\Name)
              *Item\Name + " " + Str(i)
            EndIf
            *Item\MMIDOrigCase + Str(i)
            *Item\MMID         + Str(i)
          EndIf
          
        Next i
        
      ElseIf (Name = "group")
        *MM\BuildGroup = _MenuManager_GetOSOrGenericAttribute(*Child, "name")
        If (Not _MenuManager_ParseXMLItems(*MM, *Child))
          Result = #False
          Break
        EndIf
        
      ElseIf (Name = "if")
        If (_MenuManager_IfTest(*Child, *MM))
          If (Not _MenuManager_ParseXMLItems(*MM, *Child))
            Result = #False
            Break
          EndIf
        Else
          Protected *Else = _MM_XMLNodeFromPath(*Child, "else")
          If (*Else)
            If (Not _MenuManager_ParseXMLItems(*MM, *Else))
              Result = #False
              Break
            EndIf
          EndIf
        EndIf
      
      ElseIf (Name = "else")
        ;
      
      Else
        _MenuManager_Warn("Unrecognized node '" + Name + "'")
      
      EndIf
    EndIf
    *Child = _MM_NextXMLNode(*Child)
  Wend
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseXML(*MM.MenuManager, Text.s)
  Protected Result.i = #False
  Protected XML.i = _MM_ParseXML(Text)
  If (XML)
    If (_MM_XMLStatus(XML) = #PB_XML_Success)
      Protected *Main = _MM_XMLNodeFromPath(_MM_RootXMLNode(XML), "MenuManager")
      If (*Main)
        Protected Version.i = Val(_MM_GetXMLAttribute(*Main, "version"))
        Result = #True
        
        If (_MM_GetXMLAttribute(*Main, "translate"))
          *MM\Translate = _MenuManager_ParseCallback(*MM, _MM_GetXMLAttribute(*Main, "translate"))
          If (_MenuManager_LastError)
            Result = #False
          EndIf
        EndIf
        
        If (Result)
          Protected *Items = _MM_XMLNodeFromPath(*Main, "items")
          If (*Items)
            Result = _MenuManager_ParseXMLItems(*MM, *Items)
            If (Result)
              If (ListSize(*MM\Item()) = 0)
                Result = #False
                _MenuManager_SetLastError(#MenuManager_Error_NoItems)
              EndIf
            EndIf
          Else
            Result = #False
            _MenuManager_SetLastError(#MenuManager_Error_NoItems)
          EndIf
        EndIf
        
        If (Result)
          Protected *Menus = _MM_XMLNodeFromPath(*Main, "menus")
          If (*Menus)
            Result = _MenuManager_ParseXMLMenus(*MM, #Null, *Menus, #False)
          EndIf
        EndIf
      Else
        _MenuManager_SetLastError(#MenuManager_Error_FormatInvalid)
      EndIf
    Else
      _MenuManager_SetLastError(#MenuManager_Error_ParseError)
    EndIf
    _MM_FreeXML(XML)
  Else
    _MenuManager_SetLastError(#MenuManager_Error_ParseError)
  EndIf
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf
;- _____  XML Parser End  _____
;- ______________________________




Procedure.i _MenuManager_Load(File.s)
  Protected *MM.MenuManager = #Null
  _MenuManager_SetLastError(#MenuManager_Error_None)
  
  Protected FN.i = ReadFile(#PB_Any, File, #PB_File_SharedRead)
  If (FN)
    Protected FileText.s = ReadString(FN, #PB_UTF8 | #PB_File_IgnoreEOL)
    CloseFile(FN)
    If (FileText)
      *MM = AllocateMemory(SizeOf(MenuManager))
      If (*MM)
        InitializeStructure(*MM, MenuManager)
        Protected Parsed.i = #False
        CompilerIf (#MenuManager_UseXMLParser)
          If (Not Parsed)
            If (_MenuManager_ParseXML(*MM, FileText))
              Parsed = #True
            EndIf
          EndIf
        CompilerEndIf
        If (Parsed)
          _MenuManager_CopyShortcuts(*MM, #_MM_Assigned, #_MM_GUI)
        Else
          *MM = _MenuManager_Free(*MM)
        EndIf
      EndIf
    Else
      _MenuManager_SetLastError(#MenuManager_Error_Empty)
    EndIf
  Else
    _MenuManager_SetLastError(#MenuManager_Error_CouldNotLoad, File)
  EndIf
  ProcedureReturn (*MM)
EndProcedure

Procedure.i _MenuManager_Catch(*Memory, Bytes.i)
  Protected *MM.MenuManager = #Null
  _MenuManager_SetLastError(#MenuManager_Error_None)
  
  If (*Memory)
    If (Bytes > 0)
      Protected FileText.s = PeekS(*Memory, Bytes, #PB_UTF8 | #PB_ByteLength)
      If (FileText)
        *MM = AllocateMemory(SizeOf(MenuManager))
        If (*MM)
          InitializeStructure(*MM, MenuManager)
          Protected Parsed.i = #False
          CompilerIf (#MenuManager_UseXMLParser)
            If (Not Parsed)
              If (_MenuManager_ParseXML(*MM, FileText))
                Parsed = #True
              EndIf
            EndIf
          CompilerEndIf
          If (Parsed)
            _MenuManager_CopyShortcuts(*MM, #_MM_Assigned, #_MM_GUI)
          Else
            *MM = _MenuManager_Free(*MM)
          EndIf
        EndIf
      Else
        _MenuManager_SetLastError(#MenuManager_Error_Empty)
      EndIf
    Else
      _MenuManager_SetLastError(#MenuManager_Error_MemorySizeInvalid)
    EndIf
  Else
    _MenuManager_SetLastError(#MenuManager_Error_MemoryPointerNull)
  EndIf
  ProcedureReturn (*MM)
EndProcedure

Procedure.s _MenuManager_Translate(*MM.MenuManager, Text.s, MMID.s)
  Protected Result.s
  If (*MM\Translate)
    Result = *MM\Translate(Text, MMID)
  EndIf
  If (Result = "")
    If (Text)
      Result = Text
    ElseIf (MMID)
      Result = MMID
    Else
      Result = "?"
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_Inject(*MM.MenuManager, MMID.s = "", MenuItemID.i = #PB_Ignore, Text.s = "", ImageID.i = #Null, DontPrepareText.i = #False)
  Protected Result.i = #False
  
  If (*MM)
    Protected *Item.MenuManagerItem = _MenuManager_ItemByMMID(*MM, MMID)
    If ((MMID = "") Or (*Item))
      Protected UseNumber.i   = 0
      Protected UseText.s     = ""
      Protected UseImageID.i  = #Null
      Protected UseShortcut.i = #Null
      If (*Item)
        UseNumber   = *Item\Number
        UseText     = _MenuManager_Translate(*MM, *Item\Name, *Item\MMID)
        UseImageID  = *Item\ImageID
        UseShortcut = *Item\Shortcut[#_MM_Assigned]
      EndIf
      If (MenuItemID <> #PB_Ignore)
        UseNumber = MenuItemID
      EndIf
      If (Text <> "")
        UseText = Text
        If (Not DontPrepareText)
          UseText = _MenuManager_EscapePlainText(UseText)
        EndIf
      EndIf
      If (ImageID <> #Null)
        UseImageID = ImageID
      EndIf
      
      If (Not DontPrepareText)
        If (*MM\BuildingPopup)
          UseText = _MenuManager_RemoveUnderline(UseText, #True)
        Else
          UseText = _MenuManager_PrepareUnderline(UseText)
        EndIf
      EndIf
      
      If (UseShortcut <> #Null)
        UseText + #TAB$ + ComposeShortcut(UseShortcut)
      EndIf
      
      MenuItem(UseNumber, UseText, UseImageID)
      Result = #True
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_BuildMenu(*MM.MenuManager, Menu.i, Window.i, MMID.s)
  Protected Result.i = #False
  
  _MenuManager_RemoveShortcuts(*MM, Window)
  _MenuManager_RemoveBinds(*MM, Window)
  *MM\BuildingPopup = #False
  
  MMID = _MenuManager_Normalize(MMID)
  ForEach (*MM\Menu())
    If (*MM\Menu()\MMID = MMID)
      Protected Created.i
      If (*MM\HasImages)
        Created = CreateImageMenu(Menu, WindowID(Window))
      Else
        Created = CreateMenu(Menu, WindowID(Window))
      EndIf
      If (Created)
        Result = #True
        Protected Hidden.i = #False
        Protected Text.s
        ForEach *MM\Menu()\Action()
          With *MM\Menu()\Action()
            Select (\Type)
              Case #_MMBD_Title
                If (Not Hidden)
                  Text = _MenuManager_Translate(*MM, \Name, \MMID)
                  Text = _MenuManager_PrepareUnderline(Text)
                  MenuTitle(Text)
                EndIf
              Case #_MMBD_Item
                If (\Item\Shortcut[#_MM_Assigned])
                  If (Not (\Item\Flags & #MMIF_DontAdd))
                    _MenuManager_AddShortcut(*MM, \Item, Window)
                  EndIf
                EndIf
                If (\Item\Callback)
                  _MenuManager_AddBind(*MM, \Item, Window)
                EndIf
                If (\Item\Flags & #MMIF_PostClose)
                  AddElement(_MenuManager_GlobalBind())
                  _MenuManager_GlobalBind()\Window = Window
                  _MenuManager_GlobalBind()\Object = \Item\Number
                  _MenuManager_GlobalBind()\Callback = @_MenuManager_PostCloseCB()
                  BindEvent(#PB_Event_Menu, _MenuManager_GlobalBind()\Callback, _MenuManager_GlobalBind()\Window, _MenuManager_GlobalBind()\Object)
                EndIf
                If (Not Hidden)
                  Text = _MenuManager_Translate(*MM, \Item\Name, \Item\MMID)
                  Text = _MenuManager_PrepareUnderline(Text)
                  If (\Item\Shortcut[#_MM_Assigned])
                    Text + #TAB$ + ComposeShortcut(\Item\Shortcut[#_MM_Assigned])
                  EndIf
                  MenuItem(\Item\Number, Text, \Item\ImageID)
                EndIf
              Case #_MMBD_OpenSub
                If (Not Hidden)
                  Text = _MenuManager_Translate(*MM, \Name, \MMID)
                  Text = _MenuManager_PrepareUnderline(Text)
                  OpenSubMenu(Text)
                EndIf
              Case #_MMBD_CloseSub
                If (Not Hidden)
                  CloseSubMenu()
                EndIf
              Case #_MMBD_Bar
                If (Not Hidden)
                  MenuBar()
                EndIf
              Case #_MMBD_Callback
                CallFunctionFast(\Item)
              Case #_MMBD_Hide
                Hidden = #True
              Case #_MMBD_Unhide
                Hidden = #False
            EndSelect
          EndWith
        Next
      EndIf
      Break
    EndIf
  Next
  If (Not Result)
    _MenuManager_SetLastError(#MenuManager_Error_MissingMenu, MMID)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_BuildPopupMenu(*MM.MenuManager, Menu.i, MMID.s)
  Protected Result.i = #False
  Protected Found.i = #False
  
  *MM\BuildingPopup = #True
  
  MMID = _MenuManager_Normalize(MMID)
  ForEach (*MM\Menu())
    If (*MM\Menu()\MMID = MMID)
      Found = #True
      Protected Created.i
      If (*MM\HasImages)
        Created = CreatePopupImageMenu(Menu)
      Else
        Created = CreatePopupMenu(Menu)
      EndIf
      If (Created)
        Result = #True
        Protected Text.s
        ForEach *MM\Menu()\Action()
          With *MM\Menu()\Action()
            Select (\Type)
              Case #_MMBD_Title
                _MenuManager_SetLastError(#MenuManager_Error_TitleNotAllowed)
                Result = #False
                Break
              Case #_MMBD_Item
                Text = _MenuManager_Translate(*MM, \Item\Name, \Item\MMID)
                Text = _MenuManager_RemoveUnderline(Text, #True)
                If (\Item\Shortcut[#_MM_Assigned])
                  Text + #TAB$ + ComposeShortcut(\Item\Shortcut[#_MM_Assigned])
                EndIf
                MenuItem(\Item\Number, Text, \Item\ImageID)
              Case #_MMBD_OpenSub
                Text = _MenuManager_Translate(*MM, \Name, \MMID)
                Text = _MenuManager_RemoveUnderline(Text, #True)
                OpenSubMenu(Text)
              Case #_MMBD_CloseSub
                CloseSubMenu()
              Case #_MMBD_Bar
                MenuBar()
              Case #_MMBD_Callback
                CallFunctionFast(\Item)
              Case #_MMBD_Hide
                Result = #False
                _MenuManager_SetLastError(#MenuManager_Error_HiddenNotAllowed)
                Break
              Case #_MMBD_Unhide
                Result = #False
                _MenuManager_SetLastError(#MenuManager_Error_HiddenNotAllowed)
                Break
            EndSelect
          EndWith
        Next
      EndIf
      Break
    EndIf
  Next
  If (Not Found)
    _MenuManager_SetLastError(#MenuManager_Error_MissingMenu, MMID)
  EndIf
  
  ProcedureReturn (Result)
EndProcedure






;-
;- Procedures - Public

Procedure.i MenuManagerItemFromMMID(MMID.s)
  Protected *Item.MenuManagerItem = #Null
  If (*_MenuManager)
    MMID = _MenuManager_Normalize(MMID)
    ForEach (*_MenuManager\Item())
      If (*_MenuManager\Item()\MMID = MMID)
        *Item = @*_MenuManager\Item()
        Break
      EndIf
    Next
  EndIf
  ProcedureReturn (*Item)
EndProcedure

Procedure.s MenuManagerNameFromMMID(MMID.s)
  If (*_MenuManager)
    MMID = _MenuManager_Normalize(MMID)
    ForEach (*_MenuManager\Item())
      If (*_MenuManager\Item()\MMID = MMID)
        ProcedureReturn (_MenuManager_RemoveUnderline(*_MenuManager\Item()\Name, #False))
      EndIf
    Next
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.s MenuManagerMMIDFromNumber(Number.i)
  If (*_MenuManager)
    ForEach (*_MenuManager\Item())
      If (*_MenuManager\Item()\Number = Number)
        ProcedureReturn (*_MenuManager\Item()\MMID)
      EndIf
    Next
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.s MenuManagerNameFromNumber(Number.i)
  If (*_MenuManager)
    ForEach (*_MenuManager\Item())
      If (*_MenuManager\Item()\Number = Number)
        ProcedureReturn (_MenuManager_RemoveUnderline(*_MenuManager\Item()\Name, #False))
      EndIf
    Next
  EndIf
  ProcedureReturn ("")
EndProcedure

Procedure.i InjectMenuManagerItem(MMID.s = "", MenuItemID.i = #PB_Ignore, Text.s = "", ImageID.i = #Null, DontPrepareText.i = #False)
  Protected Result.i = #False
  If (*_MenuManager)
    Result = _MenuManager_Inject(*_MenuManager, MMID, MenuItemID, Text.s, ImageID.i, DontPrepareText)
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-

Procedure.i ExamineMenuManagerItems()
  Protected Result.i = #False
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (ListSize(*MM\Item()) > 0)
      *MM\SelItem = #Null
      Result = #True
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i NextMenuManagerItem()
  Protected *Item.MenuManagerItem = #Null
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem = #Null)
      *MM\SelItem = FirstElement(*MM\Item())
      *Item = *MM\SelItem
    ElseIf (*MM\SelItem)
      ChangeCurrentElement(*MM\Item(), *MM\SelItem)
      *MM\SelItem = NextElement(*MM\Item())
      *Item = *MM\SelItem
    EndIf
  EndIf
  ProcedureReturn (*Item)
EndProcedure

Procedure.i SelectMenuManagerItem(*ItemPointer)
  Protected Result.i = #Null
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    *MM\SelItem = #Null
    ForEach (*MM\Item())
      If (@*MM\Item() = *ItemPointer)
        *MM\SelItem = *ItemPointer
        Result = *MM\SelItem
        Break
      EndIf
    Next
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s MenuManagerItemName(Translate.i = #False)
  Protected Result.s
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      If (Translate And *MM\Translate)
        Result = _MenuManager_Translate(*MM, *MM\SelItem\Name, *MM\SelItem\MMID)
      Else
        Result = _MenuManager_RemoveUnderline(*MM\SelItem\Name, #False)
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s MenuManagerItemMMID()
  Protected Result.s
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      Result = *MM\SelItem\MMID
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.s MenuManagerItemGroup()
  Protected Result.s
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      Result = *MM\SelItem\Group
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerItemPointer()
  Protected Result.i
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    Result = *MM\SelItem
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerItemFlags()
  Protected Result.i
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      Result = *MM\SelItem\Flags
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerItemImageID()
  Protected Result.i
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      Result = *MM\SelItem\ImageID
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerItemShortcut(GUI.i = #False)
  Protected Result.i
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      If (GUI)
        Result = *MM\SelItem\Shortcut[#_MM_GUI]
      Else
        Result = *MM\SelItem\Shortcut[#_MM_Assigned]
      EndIf
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerItemDefaultShortcut()
  Protected Result.i
  Protected *MM.MenuManager = *_MenuManager
  If (*MM)
    If (*MM\SelItem)
      Result = *MM\SelItem\Shortcut[#_MM_Default]
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-

Procedure ResetGUIShortcuts(Defaults.i = #False)
  If (Defaults)
    _MenuManager_CopyShortcuts(*_MenuManager, #_MM_Default, #_MM_GUI)
  Else
    _MenuManager_CopyShortcuts(*_MenuManager, #_MM_Assigned, #_MM_GUI)
  EndIf
EndProcedure

Procedure.i GUIShortcutsChanged(FromDefaults.i = #False)
  If (FromDefaults)
    ProcedureReturn (_MenuManager_ShortcutsDiffer(*_MenuManager, #_MM_GUI, #_MM_Default))
  Else
    ProcedureReturn (_MenuManager_ShortcutsDiffer(*_MenuManager, #_MM_GUI, #_MM_Assigned))
  EndIf
EndProcedure

Procedure CaptureGUIShortcuts()
  _MenuManager_CopyShortcuts(*_MenuManager, #_MM_GUI, #_MM_Assigned)
EndProcedure

;-

Procedure.i AssignShortcut(MMID.s, Shortcut.i, GUIOnly.i = #False)
  ProcedureReturn (_MenuManager_AssignShortcut(*_MenuManager, MMID, Shortcut, GUIOnly))
EndProcedure

Procedure.i IsShortcutUsed(Shortcut.i, IgnoreMMID.s = "")
  ProcedureReturn (Bool(_MenuManager_IsShortcutUsed(*_MenuManager, Shortcut, #_MM_Assigned, IgnoreMMID)))
EndProcedure

Procedure WritePreferenceShortcuts(OnlyChanged.i = #False, Group.s = "")
  If (*_MenuManager)
    If (Group)
      PreferenceGroup(Group)
    EndIf
    ForEach (*_MenuManager\Item())
      With *_MenuManager\Item()
        If (Not (\Flags & #MMIF_NoPrefs))
          If ((\Shortcut[#_MM_Assigned] <> \Shortcut[#_MM_Default]) Or (Not OnlyChanged))
            WritePreferenceString(\MMIDOrigCase, ComposeShortcut(\Shortcut[#_MM_Assigned]))
          EndIf
        EndIf
      EndWith
    Next
  EndIf
EndProcedure

Procedure ReadPreferenceShortcuts(Group.s = "", Merge.i = #False)
  If (*_MenuManager)
    If (Not Merge)
      _MenuManager_CopyShortcuts(*_MenuManager, #_MM_Default, #_MM_Assigned)
    EndIf
    If (Group)
      PreferenceGroup(Group)
    EndIf
    If (ExaminePreferenceKeys())
      While (NextPreferenceKey())
        Protected Key.s = PreferenceKeyName()
        If (Key)
          Protected *Item.MenuManagerItem = MenuManagerItemFromMMID(Key)
          If (*Item)
            _MenuManager_SetShortcut(*_MenuManager, *Item, ParseShortcut(PreferenceKeyValue()), #_MM_Assigned)
          EndIf
        EndIf
      Wend
    EndIf
  EndIf
EndProcedure

Procedure.i SaveShortcutsToFile(File.s, OnlyChanged.i = #False, Group.s = "")
  Protected Result.i = Bool(CreatePreferences(File))
  If (Result)
    WritePreferenceShortcuts(OnlyChanged, Group)
    ClosePreferences()
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i LoadShortcutsFromFile(File.s, Group.s = "", Merge.i = #False)
  Protected Result.i = Bool(OpenPreferences(File))
  If (Result)
    ReadPreferenceShortcuts(Group, Merge)
    ClosePreferences()
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-

Procedure SetMenuManagerRuntimeInt(Name.s, IntValue.i)
  If (Name)
    _MenuManager_Runtime(LCase(Name)) = IntValue
  EndIf
EndProcedure

;-

Procedure.i BuildManagedMenu(Menu.i, Window.i, MMID.s)
  Protected Result.i = #False
  If (*_MenuManager)
    Result = _MenuManager_BuildMenu(*_MenuManager, Menu, Window, MMID)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i BuildManagedPopupMenu(Menu.i, MMID.s)
  Protected Result.i = #False
  If (*_MenuManager)
    Result = _MenuManager_BuildPopupMenu(*_MenuManager, Menu, MMID)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i FreeMenuManager()
  *_MenuManager = _MenuManager_Free(*_MenuManager)
  ProcedureReturn (#Null)
EndProcedure

Procedure.i LoadMenuManager(File.s)
  FreeMenuManager()
  *_MenuManager = _MenuManager_Load(File)
  ProcedureReturn (Bool(*_MenuManager))
EndProcedure

Procedure.i CatchMenuManager(*Memory, Bytes.i)
  FreeMenuManager()
  *_MenuManager = _MenuManager_Catch(*Memory, Bytes)
  ProcedureReturn (Bool(*_MenuManager))
EndProcedure



;-
CompilerEndIf
