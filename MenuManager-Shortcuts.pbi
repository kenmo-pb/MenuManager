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

;-
;- Compiler Checks

CompilerIf (#PB_Shortcut_Z <> (#PB_Shortcut_A + 25))
  CompilerError "The #PB_Shortcut_A..Z constants are expected to be consecutive!"
CompilerElseIf (#PB_Shortcut_9 <> (#PB_Shortcut_0 + 9))
  CompilerError "The #PB_Shortcut_0..9 constants are expected to be consecutive!"
CompilerElseIf (#PB_Shortcut_F12 <> (#PB_Shortcut_F1 + 11))
  CompilerError "The #PB_Shortcut_F1..F12 constants are expected to be consecutive!"
CompilerElseIf (#PB_Shortcut_F24 <> (#PB_Shortcut_F1 + 23))
  CompilerError "The #PB_Shortcut_F1..F24 constants are expected to be consecutive!"
CompilerEndIf

;-
;- Constants

EnumerationBinary
  #MenuManager_AllowNoBaseKey
  ;
  #MenuManager_UsePlus
  #MenuManager_UseHyphen
  #MenuManager_Spaces
  #MenuManager_UseMacSymbols
EndEnumeration

#_MM_ModifierMask =  #PB_Shortcut_Control | #PB_Shortcut_Command | #PB_Shortcut_Shift | #PB_Shortcut_Alt
#_MM_BaseKeyMask  = ~#_MM_ModifierMask

;-
;- Procedures

Procedure.i GetShortcutModifiers(Shortcut.i)
  ProcedureReturn (Shortcut & #_MM_ModifierMask)
EndProcedure

Procedure.i GetShortcutBaseKey(Shortcut.i)
  ProcedureReturn (Shortcut & #_MM_BaseKeyMask)
EndProcedure

Procedure.i IsReservedShortcut(Shortcut.i)
  Protected Result.i = #False
  
  CompilerIf (#PB_Compiler_OS = #PB_OS_Windows)
    Select (Shortcut)
      Case #PB_Shortcut_Alt | #PB_Shortcut_F4,
          #PB_Shortcut_Alt | #PB_Shortcut_Escape,
          #PB_Shortcut_Alt | #PB_Shortcut_Space,
          #PB_Shortcut_Control | #PB_Shortcut_Escape,
          #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_Escape,
          #PB_Shortcut_Control | #PB_Shortcut_Alt | #PB_Shortcut_Delete
        Result = #True
    EndSelect
  CompilerEndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i ParseShortcut(Text.s, Flags.i = #PB_Default)
  ; Flags:
  ;   #MenuManager_AllowNoBaseKey
  
  Protected Result.i = #Null
  Text = UCase(Text)
  ReplaceString(Text, "+", " ", #PB_String_InPlace)
  ReplaceString(Text, "-", " ", #PB_String_InPlace)
  
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  
  Protected N.i = 1 + CountString(Text, " ")
  Protected i.i
  For i = 1 To N
    Protected Term.s = StringField(Text, i, " ")
    Select (Term)
      Case "CONTROL", "CTRL"
        Result | #PB_Shortcut_Control
      Case "COMMAND", "CMD"
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
          If (Len(Term) = 1)
            Select (Asc(Term))
              Case 'A' To 'Z'
                Result | #PB_Shortcut_A + (Asc(Term) - 'A')
              Case '0' To '9'
                Result | #PB_Shortcut_0 + (Asc(Term) - '0')
              Default
                ; ...
                Debug "Parse char: " + Term
            EndSelect
          Else
            Select (Term)
              Case "DELETE", "DEL"
                Result | #PB_Shortcut_Delete
              Default
                ; ...
                Protected Found.i = #False
                If (Not Found)
                  Protected j.i
                  For j = 1 To 24
                    If (Term = "F" + Str(j))
                      Found = #True
                      Result | (#PB_Shortcut_F1 + (j-1))
                      Break
                    EndIf
                  Next j
                EndIf
                If (Not Found)
                  Debug "Parse term: " + Term
                  Result = #Null
                  Break
                EndIf
            EndSelect
          EndIf
        EndIf
    EndSelect
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
  
  Protected Result.s
  
  If (Flags = #PB_Default)
    Flags = #Null
  EndIf
  
  Protected Separator.s
  If (Flags & #MenuManager_UsePlus)
    Separator = "+"
  ElseIf (Flags & #MenuManager_UseHyphen)
    Separator = "-"
  Else
    Separator = "+" ;? Hyphen default for Mac ??
  EndIf
  If (Flags & #MenuManager_Spaces)
    Separator = " " + Separator + " "
  EndIf
  
  If (#PB_Shortcut_Command <> #PB_Shortcut_Control)
    If (Shortcut & #PB_Shortcut_Control)
      Result + Separator + "Cmd"
    EndIf
  EndIf
  If (Shortcut & #PB_Shortcut_Control)
    Result + Separator + "Ctrl"
  EndIf
  If (Shortcut & #PB_Shortcut_Shift)
    Result + Separator + "Shift"
  EndIf
  If (Shortcut & #PB_Shortcut_Alt)
    Result + Separator + "Alt"
  EndIf
  
  Shortcut = (Shortcut & #_MM_BaseKeyMask)
  Select (Shortcut)
    Case #PB_Shortcut_A To #PB_Shortcut_Z
      Result + Separator + Chr('A' + (Shortcut - #PB_Shortcut_A))
    Case #PB_Shortcut_0 To #PB_Shortcut_9
      Result + Separator + Chr('0' + (Shortcut - #PB_Shortcut_0))
    Case #PB_Shortcut_F1 To #PB_Shortcut_F24
      Result + Separator + "F" + Str(1 + (Shortcut - #PB_Shortcut_F1))
  EndSelect
  
  Result = Mid(Result, 1 + Len(Separator))
  ProcedureReturn (Result)
EndProcedure


CompilerEndIf
;-
