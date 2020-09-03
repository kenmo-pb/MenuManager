; +-----------------+
; | Shortcut Tester |
; +-----------------+

XIncludeFile "../MenuManager-Shortcuts.pbi"


OpenWindow(0,
    0, 0, 320, 240,
    "Shortcut Tester",
    #PB_Window_ScreenCentered | #PB_Window_SystemMenu)

TextGadget(0,
    5, 5,
    WindowWidth(0)-10, WindowHeight(0)-10,
    "Press any key")

For i = 1 To 512 ; On Mac, Fn keys > 300
  AddKeyboardShortcut(0, i, i)
  If (i >= $20)
    AddKeyboardShortcut(0, i | #PB_Shortcut_Shift, i)
  EndIf
Next i


Repeat
  Event = WaitWindowEvent()
  If Event = #PB_Event_Menu
    Value = EventMenu() & (~#_MM_ModifierMask)
    
    Text.s = "Shortcut: " + Str(Value)
    Text + #LF$ + "Hex: $" + Hex(Value)
    Text + #LF$ + "Char: " + Chr(Value)
    
    Norm.i = NormalizeShortcut(Value)
    If (Norm <> Value)
      Text + #LF$ + #LF$ + "Normalized: " + Str(Norm)
      Text + #LF$ + "Hex: $" + Hex(Norm)
      Text + #LF$ + "Char: " + Chr(Norm)
    EndIf
    
    Comp.s = ComposeShortcut(Value)
    Text + #LF$ + #LF$ + "ComposeShortcut: " + Comp
    Text + #LF$ + "ParseShortcut: " + Str(ParseShortcut(Comp))
    Text + #LF$ + #LF$ + "IsBareShortcut: " + Str(IsBareShortcut(Value))
    
    SetGadgetText(0, Text)
  EndIf
Until Event = #PB_Event_CloseWindow
