; +-----------------------+
; | MenuManager-Shortcuts |
; +-----------------------+

;-
CompilerIf (Not Defined(_MenuManager_Shortcuts_Included, #PB_Constant))
#_MenuManager_Shortcuts_Included = #True

;- Compile Switches

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
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

;-
;- Compiler Checks

CompilerIf (#PB_Shortcut_Z <> #PB_Shortcut_A + 25)
  CompilerError #PB_Compiler_Filename + " expects #PB_Shortcut_A..Z to be sequential!"
CompilerElseIf (#PB_Shortcut_9 <> #PB_Shortcut_0 + 9)
  CompilerError #PB_Compiler_Filename + " expects #PB_Shortcut_0..9 to be sequential!"
CompilerElseIf (#PB_Shortcut_Pad9 <> #PB_Shortcut_Pad0 + 9)
  CompilerError #PB_Compiler_Filename + " expects #PB_Shortcut_Pad0..9 to be sequential!"
CompilerEndIf

;-
;- Constants - Public

Enumeration
  #MenuManager_AllowNoBaseKey = $01
  ;
  #MenuManager_UsePlus        = $02
  #MenuManager_UseHyphen      = $04
  #MenuManager_Spaces         = $08
  #MenuManager_UseMacSymbols  = $10
  #MenuManager_UseReturnName  = $20
EndEnumeration

#MenuManager_CommandIsControl = Bool(#PB_Shortcut_Command = #PB_Shortcut_Control)

;-
;- Constants - Private

#_MM_ModifierMask =  #PB_Shortcut_Control | #PB_Shortcut_Command | #PB_Shortcut_Shift | #PB_Shortcut_Alt
#_MM_BaseKeyMask  = ~#_MM_ModifierMask

#_MM_MacCtrl  = Chr($2303) ; UP ARROWHEAD
#_MM_MacCmd   = Chr($2318) ; PLACE OF INTEREST SIGN
#_MM_MacAlt   = Chr($2325) ; OPTION KEY
#_MM_MacShift = Chr($21E7) ; UPWARDS WHITE ARROW
#_MM_MacCaps  = Chr($21EA) ; UPWARDS WHITE ARROW FROM BAR

;-
;- Structures - Private

Structure _MenuManagerShortcutDefinition
  Value.l
  Name.s
EndStructure

;-
;- Procedures - Private

Procedure.s _MM_ShortcutNameByValue(Value.i)
  Protected Result.s
  If (Value)
    Protected *SD._MenuManagerShortcutDefinition = ?_MenuManager_ShortcutList
    While (*SD\Value <> -1)
      If (*SD\Value = 0)
        ;Debug "Null shortcut: " + *SD\Name
      EndIf
      If (*SD\Value = Value)
        Result = *SD\Name
        Break
      EndIf
      *SD + SizeOf(_MenuManagerShortcutDefinition)
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_ShortcutValueByName(Name.s, Mask.i = #Null)
  Protected Result.i = #Null
  Name = UCase(RemoveString(Name, " "))
  If (Name)
    If (Mask = #Null)
      Mask = -1
    EndIf
    Protected *SD._MenuManagerShortcutDefinition = ?_MenuManager_ShortcutList
    While (*SD\Value <> -1)
      If (*SD\Value = 0)
        ;Debug "Null shortcut: " + *SD\Name
      EndIf
      If (UCase(*SD\Name) = Name)
        If (*SD\Value & Mask <> #Null)
          Result = *SD\Value
          Break
        EndIf
      EndIf
      *SD + SizeOf(_MenuManagerShortcutDefinition)
    Wend
  EndIf
  ProcedureReturn (Result)
EndProcedure

;-
;- Procedures - Public

Procedure.i GetShortcutModifiers(Shortcut.i)
  ProcedureReturn (Shortcut & #_MM_ModifierMask)
EndProcedure

Procedure.i GetShortcutBaseKey(Shortcut.i)
  ProcedureReturn (Shortcut & #_MM_BaseKeyMask)
EndProcedure

Procedure.i NormalizeShortcut(Shortcut.i)
  If ((Shortcut = 0) Or (Shortcut = -1))
    ProcedureReturn (Shortcut)
  EndIf
  
  Protected Modifiers.i = GetShortcutModifiers(Shortcut)
  Protected BaseKey.i   = GetShortcutBaseKey(Shortcut)
  
  CompilerIf (#_MenuManager_OS <> #PB_OS_Windows) ; Normalize uppercase/lowercase to #PB_Shortcut_*
    CompilerIf ((#PB_Shortcut_A = 'A') And (#PB_Shortcut_Z = 'Z'))
      If ((BaseKey >= 'a') And (BaseKey <= 'z'))
        BaseKey = 'A' + (BaseKey - 'a')
      EndIf
    CompilerElseIf ((#PB_Shortcut_A = 'a') And (#PB_Shortcut_Z = 'z'))
      If ((BaseKey >= 'A') And (BaseKey <= 'Z'))
        BaseKey = 'a' + (BaseKey - 'A')
      EndIf
    CompilerEndIf
  CompilerEndIf
  
  CompilerIf (#_MenuManager_OS = #PB_OS_MacOS)
    
    If (#True);(Modifiers & #PB_Shortcut_Shift)
      CompilerIf (#True) ; US English Layout
        Select (BaseKey)
          Case '!'
            BaseKey = #PB_Shortcut_1
          Case '@'
            BaseKey = #PB_Shortcut_2
          Case '#'
            BaseKey = #PB_Shortcut_3
          Case '$'
            BaseKey = #PB_Shortcut_4
          Case '%'
            BaseKey = #PB_Shortcut_5
          Case '^'
            BaseKey = #PB_Shortcut_6
          Case '&'
            BaseKey = #PB_Shortcut_7
          Case '*'
            CompilerIf (#_MenuManager_OS <> #PB_OS_MacOS) ; Shift+8 ('*') conflicts with PadMult
              If (Modifiers & #PB_Shortcut_Shift)
                BaseKey = #PB_Shortcut_8
              EndIf
            CompilerEndIf
          Case '('
            BaseKey = #PB_Shortcut_9
          Case ')'
            BaseKey = #PB_Shortcut_0
        EndSelect
      CompilerEndIf
    EndIf
    
  CompilerEndIf
  
  ProcedureReturn (BaseKey | Modifiers)
EndProcedure

Procedure.i IsBareShortcut(Shortcut.i)
  Protected Result.i = #False
  
  Shortcut = NormalizeShortcut(Shortcut)
  
  If ((Shortcut & #_MM_ModifierMask) = #Null)
    Select (Shortcut)
      Case #PB_Shortcut_A To #PB_Shortcut_Z
        Result = #True
      Case #PB_Shortcut_0 To #PB_Shortcut_9
        Result = #True
      Case #PB_Shortcut_Pad0 To #PB_Shortcut_Pad9
        Result = #True
      Case #PB_Shortcut_Space
        Result = #True
      ;Case #PB_Shortcut_Return
      ;  Result = #True
      Case #PB_Shortcut_Tab
        CompilerIf (#True)
          Result = #True
        CompilerEndIf
      Default
        CompilerIf (#PB_Shortcut_Capital <> #Null)
          If (Shortcut = #PB_Shortcut_Capital)
            Result = #True
          EndIf
        CompilerEndIf
        CompilerIf (Defined(VK_OEM_PLUS, #PB_Constant))
          Select (Shortcut)
            Case #VK_OEM_PLUS, #VK_OEM_MINUS
              Result = #True
            Case #VK_OEM_COMMA, #VK_OEM_PERIOD
              Result = #True
          EndSelect
        CompilerEndIf
        CompilerIf (Defined(VK_OEM_1, #PB_Constant))
          Select (Shortcut)
            Case #VK_OEM_1, #VK_OEM_2, #VK_OEM_3,
                #VK_OEM_4, #VK_OEM_5, #VK_OEM_6,
                #VK_OEM_7;, #VK_OEM_8, #VK_OEM_102
              Result = #True
          EndSelect
        CompilerEndIf
    EndSelect
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i IsReservedShortcut(Shortcut.i)
  Protected Result.i = #False
  
  Shortcut = NormalizeShortcut(Shortcut)
  
  Select (Shortcut)
    Case #PB_Shortcut_Alt | #PB_Shortcut_Tab,
        #PB_Shortcut_Alt | #PB_Shortcut_Shift | #PB_Shortcut_Tab
      Result = #True
  EndSelect
  
  CompilerIf (#_MenuManager_OS = #PB_OS_Windows)
    Select (Shortcut)
      Case #PB_Shortcut_Alt | #PB_Shortcut_F4,
          #PB_Shortcut_Alt  | #PB_Shortcut_Escape,
          #PB_Shortcut_Alt  | #PB_Shortcut_Space,
          #PB_Shortcut_Control | #PB_Shortcut_Escape,
          #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_Escape,
          #PB_Shortcut_Control | #PB_Shortcut_Alt   | #PB_Shortcut_Delete
        Result = #True
    EndSelect
    Select (Shortcut & #_MM_BaseKeyMask)
      Case #PB_Shortcut_LeftWindows, #PB_Shortcut_RightWindows
        Result = #True
    EndSelect
  CompilerEndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i ParseShortcut(Text.s, Flags.i = #PB_Default)
  ; Flags:
  ;   #MenuManager_AllowNoBaseKey
  
  Protected Result.i = #Null
  
  CompilerIf (#True)
    Text = ReplaceString(Text, #_MM_MacCmd,   "Cmd+")
    Text = ReplaceString(Text, #_MM_MacCtrl,  "Ctrl+")
    Text = ReplaceString(Text, #_MM_MacShift, "Shift+")
    Text = ReplaceString(Text, #_MM_MacAlt,   "Alt+")
    Text = ReplaceString(Text, #_MM_MacCaps,  "CapsLock")
  CompilerEndIf
  
  Text = RemoveString(Text, " ")
  ReplaceString(Text, "+", " ", #PB_String_InPlace)
  ReplaceString(Text, "-", " ", #PB_String_InPlace)
  Text = UCase(Text)
  
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  
  Protected N.i = 1 + CountString(Text, " ")
  Protected i.i
  For i = 1 To N
    Protected Term.s = StringField(Text, i, " ")
    If (Term)
      Select (Term)
        Case "CONTROL", "CTRL", "CTR"
          Result | #PB_Shortcut_Control
        Case "COMMAND", "COMM", "CMD"
          Result | #PB_Shortcut_Command
        Case "ALT"
          Result | #PB_Shortcut_Alt
        Case "SHIFT", "SHI"
          Result | #PB_Shortcut_Shift
        
        Default
          If (Result & #_MM_BaseKeyMask)
            ; Conflicting base keys - fail out!
            Result = #Null
            Break
          Else
            If ((Term = "NONE") Or (Term = "NULL"))
              Result = #Null
              Break
            Else
              Protected Value.i = _MM_ShortcutValueByName(Term, #_MM_BaseKeyMask)
              If (Value)
                Result | Value
              ElseIf ((Left(Term, 2) = "0X") And (Len(Term) >= 3)) ; accept raw hex value, "0x" prefix
                Result | Val("$" + Mid(Term, 3))
              ElseIf ((Left(Term, 1) = "$") And (Len(Term) >= 2)) ; accept raw hex value, "$" prefix
                Result | Val(Term)
              Else
                Debug #PB_Compiler_Filename + ": " + #PB_Compiler_Procedure + "() term: " + Term
                Result = #Null
                Break
              EndIf
            EndIf
          EndIf
      EndSelect
    EndIf
  Next i
  
  If (Not (Flags & #MenuManager_AllowNoBaseKey))
    If ((Result & #_MM_BaseKeyMask) = #Null)
      Result = #Null
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s ComposeShortcut(Shortcut.i, Flags.i = #PB_Default)
  ; Flags:
  ;   #MenuManager_UsePlus
  ;   #MenuManager_UseHyphen
  ;   #MenuManager_Spaces
  ;   #MenuManager_UseMacSymbols
  ;   #MenuManager_UseReturnName
  
  Protected Result.s
  
  If (Shortcut = -1)
    Shortcut = #Null
  EndIf
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  
  Shortcut = NormalizeShortcut(Shortcut)
  
  Protected Separator.s
  If (Flags & #MenuManager_UseMacSymbols)
    Separator = ""
  ElseIf (Flags & #MenuManager_UsePlus)
    Separator = "+"
  ElseIf (Flags & #MenuManager_UseHyphen)
    Separator = "-"
  Else
    Separator = "+"
  EndIf
  If (Flags & #MenuManager_Spaces)
    If (Separator <> "")
      Separator = " " + Separator + " "
    Else
      Separator = " "
    EndIf
  EndIf
  
  Protected CmdString.s   = "Cmd"
  Protected CtrlString.s  = "Ctrl"
  Protected ShiftString.s = "Shift"
  Protected AltString.s   = "Alt"
  If (Flags & #MenuManager_UseMacSymbols)
    CmdString   = #_MM_MacCmd
    CtrlString  = #_MM_MacCtrl
    ShiftString = #_MM_MacShift
    AltString   = #_MM_MacAlt
  EndIf
  
  CompilerIf (#True)
    If (Not #MenuManager_CommandIsControl)
      If (Shortcut & #PB_Shortcut_Command)
        Result + Separator + CmdString
      EndIf
    EndIf
    If (Shortcut & #PB_Shortcut_Control)
      Result + Separator + CtrlString
    EndIf
    If (Shortcut & #PB_Shortcut_Shift)
      Result + Separator + ShiftString
    EndIf
    If (Shortcut & #PB_Shortcut_Alt)
      Result + Separator + AltString
    EndIf
  CompilerEndIf
  
  Shortcut = (Shortcut & #_MM_BaseKeyMask)
  If (Shortcut)
    Protected Base.s = _MM_ShortcutNameByValue(Shortcut)
    If (Shortcut = #PB_Shortcut_Return)
      If (Flags & #MenuManager_UseReturnName)
        Base = "Return"
      EndIf
    EndIf
    
    If (Base)
      Result + Separator + Base
    ElseIf ((Shortcut >= $20) And (Shortcut <= $7E)) ; fall back to ASCII character
      Result + Separator + Chr(Shortcut)
    Else
      CompilerIf (#True) ; finally: fall back to raw hex value
        If (#True)
          Result + Separator + "0x" + UCase(Hex(Shortcut))
        Else
          Result + Separator + "$" + UCase(Hex(Shortcut))
        EndIf
      CompilerElse
        Result + Separator + "?"
      CompilerEndIf
    EndIf
    
    Result = Mid(Result, 1 + Len(Separator))
  ElseIf (#True)
    Result = "None"
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

;-
;- Data Section

DataSection
  _MenuManager_DQUOTE:
  Data.s #DQUOTE$
  _MenuManager_MACCMD:
  Data.s #_MM_MacCmd
  _MenuManager_MACCTRL:
  Data.s #_MM_MacCtrl
  _MenuManager_MACALT:
  Data.s #_MM_MacAlt
  _MenuManager_MACSHIFT:
  Data.s #_MM_MacShift
  _MenuManager_MACCAPS:
  Data.s #_MM_MacCaps
  
  _MenuManager_ShortcutList:
  ;
  CompilerIf (#_MenuManager_OS = #PB_OS_MacOS) ; Mac, priority over #PB constants
    Data.l ';' : Data.i @";"
    Data.l ';' : Data.i @":"
    Data.l $27 : Data.i @"'"
    
    Data.l $27
    CompilerIf (#True)
      Data.i ?_MenuManager_DQUOTE
    CompilerElse
      ; PB 6.00b3 C Backend requires this to be patched at runtime
      _MenuManager_DQUOTEPatch1:
      Data.i #Null
    CompilerEndIf
    
    Data.l '-' : Data.i @"Minus"
    Data.l '=' : Data.i @"Plus"
    Data.l ',' : Data.i @","
    Data.l ',' : Data.i @"<"
    Data.l '.' : Data.i @"."
    Data.l '.' : Data.i @">"
    Data.l '/' : Data.i @"/"
    ;Data.l '/' : Data.i @"?"
    Data.l '\' : Data.i @"\"
    Data.l '\' : Data.i @"|"
    Data.l '`' : Data.i @"~"
    Data.l '`' : Data.i @"`"
    Data.l '[' : Data.i @"["
    Data.l '[' : Data.i @"{"
    Data.l ']' : Data.i @"]"
    Data.l ']' : Data.i @"}"
  CompilerEndIf
  ;
  Data.l #PB_Shortcut_Back : Data.i @"Back"
  Data.l #PB_Shortcut_Back : Data.i @"Backspace"
  Data.l #PB_Shortcut_Back : Data.i @"Bk"
  Data.l #PB_Shortcut_Tab : Data.i @"Tab"
  Data.l #PB_Shortcut_Clear : Data.i @"Clear"
  Data.l #PB_Shortcut_Return : Data.i @"Enter"
  Data.l #PB_Shortcut_Return : Data.i @"Return"
  Data.l #PB_Shortcut_Menu : Data.i @"Menu"
  Data.l #PB_Shortcut_Pause : Data.i @"Pause"
  Data.l #PB_Shortcut_Pause : Data.i @"Break"
  Data.l #PB_Shortcut_Print : Data.i @"Print"
  Data.l #PB_Shortcut_Print : Data.i @"PrintScreen"
  Data.l #PB_Shortcut_Print : Data.i @"PrntScr"
  CompilerIf (#True)
    Data.l #PB_Shortcut_Capital : Data.i @"CapsLock"
    Data.l #PB_Shortcut_Capital : Data.i @"CapLock"
    Data.l #PB_Shortcut_Capital : Data.i @"Caps"
    Data.l #PB_Shortcut_Capital : Data.i @"Cap"
    Data.l #PB_Shortcut_Capital : Data.i @"Capital"
    Data.l #PB_Shortcut_Capital : Data.i ?_MenuManager_MACCAPS
  CompilerEndIf
  Data.l #PB_Shortcut_Escape : Data.i @"Esc"
  Data.l #PB_Shortcut_Escape : Data.i @"Escape"
  Data.l #PB_Shortcut_Space : Data.i @"Space"
  Data.l #PB_Shortcut_Space : Data.i @"Spc"
  Data.l #PB_Shortcut_Space : Data.i @"Sp"
  Data.l #PB_Shortcut_PageUp : Data.i @"PgUp"
  Data.l #PB_Shortcut_PageUp : Data.i @"PageUp"
  Data.l #PB_Shortcut_PageUp : Data.i @"Prior"
  Data.l #PB_Shortcut_PageDown : Data.i @"PgDown"
  Data.l #PB_Shortcut_PageDown : Data.i @"PgDn"
  Data.l #PB_Shortcut_PageDown : Data.i @"PageDown"
  Data.l #PB_Shortcut_PageDown : Data.i @"PageDn"
  Data.l #PB_Shortcut_PageDown : Data.i @"Next"
  Data.l #PB_Shortcut_End : Data.i @"End"
  Data.l #PB_Shortcut_Home : Data.i @"Home"
  Data.l #PB_Shortcut_Left : Data.i @"Left"
  Data.l #PB_Shortcut_Up : Data.i @"Up"
  Data.l #PB_Shortcut_Right : Data.i @"Right"
  Data.l #PB_Shortcut_Right : Data.i @"Rt"
  Data.l #PB_Shortcut_Down : Data.i @"Down"
  Data.l #PB_Shortcut_Down : Data.i @"Dn"
  Data.l #PB_Shortcut_Select : Data.i @"Select"
  Data.l #PB_Shortcut_Select : Data.i @"Sel"
  Data.l #PB_Shortcut_Execute : Data.i @"Execute"
  Data.l #PB_Shortcut_Execute : Data.i @"Exe"
  Data.l #PB_Shortcut_Snapshot : Data.i @"Snapshot"
  Data.l #PB_Shortcut_Snapshot : Data.i @"Snap"
  Data.l #PB_Shortcut_Insert : Data.i @"Ins"
  Data.l #PB_Shortcut_Insert : Data.i @"Insert"
  Data.l #PB_Shortcut_Delete : Data.i @"Del"
  Data.l #PB_Shortcut_Delete : Data.i @"Delete"
  Data.l #PB_Shortcut_Help : Data.i @"Help"
  ;
  Data.l #PB_Shortcut_0 : Data.i @"0"
  Data.l #PB_Shortcut_1 : Data.i @"1"
  Data.l #PB_Shortcut_2 : Data.i @"2"
  Data.l #PB_Shortcut_3 : Data.i @"3"
  Data.l #PB_Shortcut_4 : Data.i @"4"
  Data.l #PB_Shortcut_5 : Data.i @"5"
  Data.l #PB_Shortcut_6 : Data.i @"6"
  Data.l #PB_Shortcut_7 : Data.i @"7"
  Data.l #PB_Shortcut_8 : Data.i @"8"
  Data.l #PB_Shortcut_9 : Data.i @"9"
  ;
  Data.l #PB_Shortcut_A : Data.i @"A"
  Data.l #PB_Shortcut_B : Data.i @"B"
  Data.l #PB_Shortcut_C : Data.i @"C"
  Data.l #PB_Shortcut_D : Data.i @"D"
  Data.l #PB_Shortcut_E : Data.i @"E"
  Data.l #PB_Shortcut_F : Data.i @"F"
  Data.l #PB_Shortcut_G : Data.i @"G"
  Data.l #PB_Shortcut_H : Data.i @"H"
  Data.l #PB_Shortcut_I : Data.i @"I"
  Data.l #PB_Shortcut_J : Data.i @"J"
  Data.l #PB_Shortcut_K : Data.i @"K"
  Data.l #PB_Shortcut_L : Data.i @"L"
  Data.l #PB_Shortcut_M : Data.i @"M"
  Data.l #PB_Shortcut_N : Data.i @"N"
  Data.l #PB_Shortcut_O : Data.i @"O"
  Data.l #PB_Shortcut_P : Data.i @"P"
  Data.l #PB_Shortcut_Q : Data.i @"Q"
  Data.l #PB_Shortcut_R : Data.i @"R"
  Data.l #PB_Shortcut_S : Data.i @"S"
  Data.l #PB_Shortcut_T : Data.i @"T"
  Data.l #PB_Shortcut_U : Data.i @"U"
  Data.l #PB_Shortcut_V : Data.i @"V"
  Data.l #PB_Shortcut_W : Data.i @"W"
  Data.l #PB_Shortcut_X : Data.i @"X"
  Data.l #PB_Shortcut_Y : Data.i @"Y"
  Data.l #PB_Shortcut_Z : Data.i @"Z"
  ;
  Data.l #PB_Shortcut_LeftWindows : Data.i @"LWin"
  Data.l #PB_Shortcut_LeftWindows : Data.i @"LeftWin"
  Data.l #PB_Shortcut_LeftWindows : Data.i @"LeftWindows"
  Data.l #PB_Shortcut_LeftWindows : Data.i @"LWindows"
  Data.l #PB_Shortcut_RightWindows : Data.i @"RWin"
  Data.l #PB_Shortcut_RightWindows : Data.i @"RightWin"
  Data.l #PB_Shortcut_RightWindows : Data.i @"RightWindows"
  Data.l #PB_Shortcut_RightWindows : Data.i @"RWindows"
  Data.l #PB_Shortcut_Apps : Data.i @"Apps"
  Data.l #PB_Shortcut_Apps : Data.i @"App"
  Data.l #PB_Shortcut_Pad0 : Data.i @"Pad0"
  Data.l #PB_Shortcut_Pad1 : Data.i @"Pad1"
  Data.l #PB_Shortcut_Pad2 : Data.i @"Pad2"
  Data.l #PB_Shortcut_Pad3 : Data.i @"Pad3"
  Data.l #PB_Shortcut_Pad4 : Data.i @"Pad4"
  Data.l #PB_Shortcut_Pad5 : Data.i @"Pad5"
  Data.l #PB_Shortcut_Pad6 : Data.i @"Pad6"
  Data.l #PB_Shortcut_Pad7 : Data.i @"Pad7"
  Data.l #PB_Shortcut_Pad8 : Data.i @"Pad8"
  Data.l #PB_Shortcut_Pad9 : Data.i @"Pad9"
  Data.l #PB_Shortcut_Pad0 : Data.i @"Num0"
  Data.l #PB_Shortcut_Pad1 : Data.i @"Num1"
  Data.l #PB_Shortcut_Pad2 : Data.i @"Num2"
  Data.l #PB_Shortcut_Pad3 : Data.i @"Num3"
  Data.l #PB_Shortcut_Pad4 : Data.i @"Num4"
  Data.l #PB_Shortcut_Pad5 : Data.i @"Num5"
  Data.l #PB_Shortcut_Pad6 : Data.i @"Num6"
  Data.l #PB_Shortcut_Pad7 : Data.i @"Num7"
  Data.l #PB_Shortcut_Pad8 : Data.i @"Num8"
  Data.l #PB_Shortcut_Pad9 : Data.i @"Num9"
  Data.l #PB_Shortcut_Multiply : Data.i @"PadMult"
  Data.l #PB_Shortcut_Multiply : Data.i @"Mult"
  Data.l #PB_Shortcut_Multiply : Data.i @"Multiply"
  Data.l #PB_Shortcut_Add : Data.i @"PadPlus"
  Data.l #PB_Shortcut_Add : Data.i @"PadAdd"
  Data.l #PB_Shortcut_Add : Data.i @"Add"
  Data.l #PB_Shortcut_Separator : Data.i @"Sep"
  Data.l #PB_Shortcut_Separator : Data.i @"PadSep"
  Data.l #PB_Shortcut_Separator : Data.i @"Separator"
  Data.l #PB_Shortcut_Subtract : Data.i @"PadMinus"
  Data.l #PB_Shortcut_Subtract : Data.i @"PadSub"
  Data.l #PB_Shortcut_Subtract : Data.i @"PadSubtract"
  Data.l #PB_Shortcut_Subtract : Data.i @"Subtract"
  Data.l #PB_Shortcut_Decimal : Data.i @"PadDec"
  Data.l #PB_Shortcut_Decimal : Data.i @"PadDecimal"
  Data.l #PB_Shortcut_Decimal : Data.i @"Decimal"
  Data.l #PB_Shortcut_Divide : Data.i @"PadDiv"
  Data.l #PB_Shortcut_Divide : Data.i @"Div"
  Data.l #PB_Shortcut_Divide : Data.i @"Divide"
  ;
  Data.l #PB_Shortcut_F1 : Data.i @"F1"
  Data.l #PB_Shortcut_F2 : Data.i @"F2"
  Data.l #PB_Shortcut_F3 : Data.i @"F3"
  Data.l #PB_Shortcut_F4 : Data.i @"F4"
  Data.l #PB_Shortcut_F5 : Data.i @"F5"
  Data.l #PB_Shortcut_F6 : Data.i @"F6"
  Data.l #PB_Shortcut_F7 : Data.i @"F7"
  Data.l #PB_Shortcut_F8 : Data.i @"F8"
  Data.l #PB_Shortcut_F9 : Data.i @"F9"
  Data.l #PB_Shortcut_F10 : Data.i @"F10"
  Data.l #PB_Shortcut_F11 : Data.i @"F11"
  Data.l #PB_Shortcut_F12 : Data.i @"F12"
  CompilerIf (Defined(PB_Shortcut_F13, #PB_Constant) And Defined(PB_Shortcut_F24, #PB_Constant))
    CompilerIf ((#PB_Shortcut_F13 <> #Null) And (#PB_Shortcut_F24 <> #Null))
      Data.l #PB_Shortcut_F13 : Data.i @"F13"
      Data.l #PB_Shortcut_F14 : Data.i @"F14"
      Data.l #PB_Shortcut_F15 : Data.i @"F15"
      Data.l #PB_Shortcut_F16 : Data.i @"F16"
      Data.l #PB_Shortcut_F17 : Data.i @"F17"
      Data.l #PB_Shortcut_F18 : Data.i @"F18"
      Data.l #PB_Shortcut_F19 : Data.i @"F19"
      Data.l #PB_Shortcut_F20 : Data.i @"F20"
      Data.l #PB_Shortcut_F21 : Data.i @"F21"
      Data.l #PB_Shortcut_F22 : Data.i @"F22"
      Data.l #PB_Shortcut_F23 : Data.i @"F23"
      Data.l #PB_Shortcut_F24 : Data.i @"F24"
    CompilerEndIf
  CompilerEndIf
  ;
  Data.l #PB_Shortcut_Numlock : Data.i @"NumLock"
  Data.l #PB_Shortcut_Numlock : Data.i @"Num"
  Data.l #PB_Shortcut_Scroll : Data.i @"ScrlLock"
  Data.l #PB_Shortcut_Scroll : Data.i @"Scroll"
  Data.l #PB_Shortcut_Scroll : Data.i @"ScrollLock"
  Data.l #PB_Shortcut_Scroll : Data.i @"Scrl"
  ;
  CompilerIf (Defined(VK_OEM_PLUS, #PB_Constant)) ; Any region
    Data.l #VK_OEM_PLUS : Data.i @"Plus"
    Data.l #VK_OEM_PLUS : Data.i @"="
    Data.l #VK_OEM_MINUS : Data.i @"Minus"
    Data.l #VK_OEM_MINUS : Data.i @"-"
    Data.l #VK_OEM_COMMA : Data.i @","
    Data.l #VK_OEM_COMMA : Data.i @"Comma"
    Data.l #VK_OEM_PERIOD : Data.i @"."
    Data.l #VK_OEM_PERIOD : Data.i @"Period"
    Data.l #VK_OEM_PERIOD : Data.i @"Decimal"
    Data.l #VK_OEM_PERIOD : Data.i @"Dec"
  CompilerEndIf
  CompilerIf (Defined(VK_OEM_1, #PB_Constant)) ; US region!
    Data.l #VK_OEM_1 : Data.i @";"
    Data.l #VK_OEM_1 : Data.i @":"
    Data.l #VK_OEM_2 : Data.i @"/"
    ;Data.l #VK_OEM_2 : Data.i @"?"
    Data.l #VK_OEM_3 : Data.i @"~"
    Data.l #VK_OEM_3 : Data.i @"`"
    Data.l #VK_OEM_4 : Data.i @"["
    Data.l #VK_OEM_4 : Data.i @"{"
    Data.l #VK_OEM_5 : Data.i @"\"
    Data.l #VK_OEM_5 : Data.i @"|"
    Data.l #VK_OEM_6 : Data.i @"]"
    Data.l #VK_OEM_6 : Data.i @"}"
    Data.l #VK_OEM_7 : Data.i @"'"
    
    Data.l #VK_OEM_7
    CompilerIf (#True)
      Data.i ?_MenuManager_DQUOTE
    CompilerElse
      ; PB 6.00b3 C Backend requires this to be patched at runtime
      _MenuManager_DQUOTEPatch2:
      Data.i #Null
    CompilerEndIf
    
    ;Data.l #VK_OEM_8 : Data.i "OEM_8"
    ;Data.l #VK_OEM_102 : Data.i "OEM_102"
  CompilerEndIf
  ;
  Data.l #PB_Shortcut_Control : Data.i @"Ctrl"
  Data.l #PB_Shortcut_Control : Data.i @"Control"
  Data.l #PB_Shortcut_Control : Data.i @"Ctr"
  Data.l #PB_Shortcut_Control : Data.i ?_MenuManager_MACCTRL
  Data.l #PB_Shortcut_Command : Data.i @"Cmd"
  Data.l #PB_Shortcut_Command : Data.i @"Comm"
  Data.l #PB_Shortcut_Command : Data.i @"Command"
  Data.l #PB_Shortcut_Command : Data.i ?_MenuManager_MACCMD
  Data.l #PB_Shortcut_Alt     : Data.i @"Alt"
  Data.l #PB_Shortcut_Alt     : Data.i ?_MenuManager_MACALT
  Data.l #PB_Shortcut_Shift   : Data.i @"Shift"
  Data.l #PB_Shortcut_Shift   : Data.i @"Shi"
  Data.l #PB_Shortcut_Shift   : Data.i ?_MenuManager_MACSHIFT
  ;
  Data.l -1 : Data.i #Null
EndDataSection

CompilerIf (Defined(_MenuManager_DQUOTEPatch1, #PB_Label))
  PokeI(?_MenuManager_DQUOTEPatch1, ?_MenuManager_DQUOTE)
CompilerEndIf
CompilerIf (Defined(_MenuManager_DQUOTEPatch2, #PB_Label))
  PokeI(?_MenuManager_DQUOTEPatch2, ?_MenuManager_DQUOTE)
CompilerEndIf


CompilerEndIf
;-
