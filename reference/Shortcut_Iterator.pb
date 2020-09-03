; +-------------------+
; | Shortcut Iterator |
; +-------------------+

XIncludeFile "../MenuManager.pbi"

Restore _MenuManager_ShortcutList
While (#True)
  Read.l Value
  Read.i *Name
  If (Value >= 0) And (*Name)
    Name.s = PeekS(*Name)
    If (Value = #Null)
      Debug Name + " is NULL"
    ElseIf (Value = 'A')
      Debug Name + " is 'A'"
    ElseIf (Value = 'a')
      Debug Name + " is 'a'"
    EndIf
  Else
    Break
  EndIf
Wend
