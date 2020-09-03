; +-------------------------+
; | MenuManager Example: OS |
; +-------------------------+

; You can "trick" MenuManager for testing purposes
;#_MenuManager_OS = #PB_OS_Linux

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

LoadMenuManager("xml-OS.xml")
Message.s = "OS Example" + #LF$ + #LF$ + "The menu and shortcuts change with the OS"
OpenExampleWindow(0, "MenuManager - OS", Message)
BuildManagedMenu(0, 0, "main")

Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
FreeMenuManager()

