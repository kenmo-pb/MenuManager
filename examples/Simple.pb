; +-----------------------------+
; | MenuManager Example: Simple |
; +-----------------------------+

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

Procedure DebugCallback()
  Debug MenuManagerNameFromNumber(EventMenu())
EndProcedure

LoadMenuManager("xml-Simple.xml")
Message.s = "Simple Example" + #LF$ + #LF$ + "Try the menu and keyboard shorcuts" + #LF$ + "(including the hidden F1 shortcut)"
OpenExampleWindow(0, "MenuManager - Simple", Message)
BuildManagedMenu(0, 0, "main")
BindEvent(#PB_Event_Menu, @DebugCallback())

Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
FreeMenuManager()

