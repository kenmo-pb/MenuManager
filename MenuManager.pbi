; +-------------+
; | MenuManager |
; +-------------+
; | 2020-01-27 : Creation (PureBasic 5.71)

;-
CompilerIf (Not Defined(_MenuManager_Included, #PB_Constant))
#_MenuManager_Included = #True

;- Compile Switches

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;-
;- Includes

XIncludeFile "MenuManager-Shortcuts.pbi"

;-
;- Constants

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

;-
;- Structures

Structure MenuManagerAddedShortcut
  Window.i
  Shortcut.i
EndStructure

Structure MenuManagerItem
  Name.s
  MMID.s
  Number.i
  ImageID.i
  ;
  Shortcut.i
  DefShortcut.i
  DispShortcut.i
EndStructure

Structure MenuManagerAction
  Type.i
  Name.s
  *Item.MenuManagerItem
EndStructure

Structure MenuManagerMenu
  MMID.s
  List Action.MenuManagerAction()
EndStructure

Structure MenuManager
  List Item.MenuManagerItem()
  List Menu.MenuManagerMenu()
  List Added.MenuManagerAddedShortcut()
EndStructure

;-
;- Globals

Global *_MenuManger.MenuManager = #Null

;-
;- Procedures - Private

Procedure.s _MenuManager_Normalize(MMID.s)
  ProcedureReturn (LCase(ReplaceString(Trim(MMID), " ", "-")))
EndProcedure

Procedure _MenuManager_RemoveShortcuts(*MM.MenuManager, Window.i = #PB_All)
  ForEach (*MM\Added())
    If ((Window = #PB_All) Or (*MM\Added()\Window = Window))
      RemoveKeyboardShortcut(*MM\Added()\Window, *MM\Added()\Shortcut)
      DeleteElement(*MM\Added())
    EndIf
  Next
EndProcedure

Procedure _MenuManager_AddShortcut(*MM.MenuManager, *Item.MenuManagerItem, Window.i)
  AddKeyboardShortcut(Window, *Item\Shortcut, *Item\Number)
  AddElement(*MM\Added())
  *MM\Added()\Window = Window
  *MM\Added()\Shortcut = *Item\Shortcut
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

Procedure.i _MenuManager_Free(*MM.MenuManager)
  If (*MM)
    If (#False)
      _MenuManager_RemoveShortcuts(*MM, #PB_All)
    EndIf
    ForEach *MM\Menu()
      ; ...
    Next
    ForEach *MM\Item()
      ; ...
    Next
    ClearList(*MM\Item())
    FreeList(*MM\Item())
    ClearStructure(*MM, MenuManager)
    FreeMemory(*MM)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

Procedure.i _MenuManager_ParseNumber(*MM.MenuManager, Text.s)
  Protected Result.i
  If (Left(Text, 1) = "#")
    Result = GetRuntimeInteger(Text)
  Else
    Result = Val(Text)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseXMLMenu(*MM.MenuManager, *Menu.MenuManagerMenu, *Node)
  Protected Result.i = #True
  Protected *Child = ChildXMLNode(*Node)
  While (*Child)
    If (XMLNodeType(*Child) = #PB_XML_Normal)
      Select (LCase(Trim(GetXMLNodeName(*Child))))
        Case "title"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Title
          *Menu\Action()\Name = GetXMLAttribute(*Child, "name")
          If (Not _MenuManager_ParseXMLMenu(*MM, *Menu, *Child))
            Result = #False
            Break
          EndIf
        Case "item"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Item
          *Menu\Action()\Item = _MenuManager_ItemByMMID(*MM, _MenuManager_Normalize(GetXMLAttribute(*Child, "mmid")))
          If (Not *Menu\Action()\Item)
            Result = #False
            Break
          EndIf
        Case "bar"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Bar
        Case "hidden"
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Hide
          If (Not _MenuManager_ParseXMLMenu(*MM, *Menu, *Child))
            Result = #False
            Break
          EndIf
          AddElement(*Menu\Action())
          *Menu\Action()\Type = #_MMBD_Unhide
      EndSelect
    EndIf
    *Child = NextXMLNode(*Child)
  Wend
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_ParseXML(*MM.MenuManager, Text.s)
  Protected Result.i = #False
  Protected XML.i = ParseXML(#PB_Any, Text)
  If (XML)
    If (XMLStatus(XML) = #PB_XML_Success)
      Protected *Main = XMLNodeFromPath(RootXMLNode(XML), "MenuManager")
      If (*Main)
        Protected Version.i = Val(GetXMLAttribute(*Main, "version"))
        Protected *Items = XMLNodeFromPath(*Main, "items")
        If (*Items)
          Result = #True
          Protected *Child
          *Child = ChildXMLNode(*Items)
          While (*Child)
            If ((XMLNodeType(*Child) = #PB_XML_Normal) And (GetXMLNodeName(*Child) = "item"))
              Protected *Item.MenuManagerItem
              *Item = AddElement(*MM\Item())
              *Item\Name = GetXMLAttribute(*Child, "name")
              *Item\MMID = GetXMLAttribute(*Child, "mmid")
              *Item\Number = _MenuManager_ParseNumber(*MM, GetXMLAttribute(*Child, "number"))
              ;? check for Windows or Mac specific shortcuts
              *Item\DefShortcut = ParseShortcut(GetXMLAttribute(*Child, "shortcut"))
              ;? check for double-used shortcuts?
              *Item\Shortcut = *Item\DefShortcut
              
              If (*Item\MMID = "")
                *Item\MMID = RemoveString(*Item\Name, "_") ;? escape unescape properly
              EndIf
              *Item\MMID = _MenuManager_Normalize(*Item\MMID)
              If (*Item\MMID = "")
                Result = #False
                Break
              EndIf
            EndIf
            *Child = NextXMLNode(*Child)
          Wend
        EndIf
        
        If (Result)
          Protected *Menus = XMLNodeFromPath(*Main, "menus")
          If (*Menus)
            *Child = ChildXMLNode(*Menus)
            While (*Child)
              If ((XMLNodeType(*Child) = #PB_XML_Normal) And (GetXMLNodeName(*Child) = "menu"))
                Protected *Menu.MenuManagerMenu
                *Menu = AddElement(*MM\Menu())
                *Menu\MMID = GetXMLAttribute(*Child, "mmid")
                *Menu\MMID = _MenuManager_Normalize(*Menu\MMID)
                If (*Menu\MMID)
                  If (Not _MenuManager_ParseXMLMenu(*MM, *Menu, *Child))
                    Result = #False
                    Break
                  EndIf
                Else
                  Result = #False
                  Break
                EndIf
              EndIf
              *Child = NextXMLNode(*Child)
            Wend
          EndIf
        EndIf
      EndIf
    EndIf
    FreeXML(XML)
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MenuManager_Load(File.s)
  Protected *MM.MenuManager = #Null
  Protected FN.i = ReadFile(#PB_Any, File, #PB_File_SharedRead)
  If (FN)
    Protected FileText.s = ReadString(FN, #PB_UTF8 | #PB_File_IgnoreEOL)
    CloseFile(FN)
    If (FileText)
      *MM = AllocateMemory(SizeOf(MenuManager))
      If (*MM)
        InitializeStructure(*MM, MenuManager)
        If (_MenuManager_ParseXML(*MM, FileText))
        Else
          *MM = _MenuManager_Free(*MM)
        EndIf
      EndIf
    EndIf
  EndIf
  ProcedureReturn (*MM)
EndProcedure





;-
;- Procedures - Public

Procedure.i BuildManagedMenu(Menu.i, Window.i, MMID.s)
  Protected Result.i = #False
  
  ForEach *_MenuManger\Menu()
    If (*_MenuManger\Menu()\MMID = MMID)
      If CreateMenu(Menu, WindowID(Window))
        Result = #True
        Protected Hidden.i = #False
        ForEach *_MenuManger\Menu()\Action()
          With *_MenuManger\Menu()\Action()
            Select (\Type)
              Case #_MMBD_Title
                If (Not Hidden)
                  MenuTitle(\Name)
                EndIf
              Case #_MMBD_Item
                If (\Item\Shortcut)
                  _MenuManager_AddShortcut(*_MenuManger, \Item, Window)
                EndIf
                If (Not Hidden)
                  Protected Text.s = \Item\Name
                  If (\Item\Shortcut)
                    Text + #TAB$ + ComposeShortcut(\Item\Shortcut)
                  EndIf
                  MenuItem(\Item\Number, Text)
                EndIf
              Case #_MMBD_Bar
                If (Not Hidden)
                  MenuBar()
                EndIf
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
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i FreeMenuManager()
  *_MenuManger = _MenuManager_Free(*_MenuManger)
  ProcedureReturn (#Null)
EndProcedure

Procedure.i LoadMenuManager(File.s)
  FreeMenuManager()
  *_MenuManger = _MenuManager_Load(File)
  ProcedureReturn (Bool(*_MenuManger))
EndProcedure



;-
CompilerEndIf
