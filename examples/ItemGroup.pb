; +---------------------------------+
; | MenuManager Example: Item Group |
; +---------------------------------+

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

Runtime Procedure RecentFileCallback()
  Debug "Recent File #" + Str(EventMenu())
EndProcedure

LoadMenuManager("xml-ItemGroup.xml")
Message.s = "Item Group Example" + #LF$ + #LF$ + "Recent File group created by specifying 'N'"
OpenExampleWindow(0, "MenuManager - Item Group", Message)
BuildManagedMenu(0, 0, "main")

Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
FreeMenuManager()

