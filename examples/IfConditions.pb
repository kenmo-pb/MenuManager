; +------------------------------------+
; | MenuManager Example: If Conditions |
; +------------------------------------+

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

; Set a custom runtime integer which affect the menu build
;   (You could PureBasic's SetRuntimeInteger() but
;   that requires a created variable for each one)
CompilerIf (#PB_Compiler_Processor = #PB_Processor_x64)
  SetMenuManagerRuntimeInt("Is64Bit", #True)
CompilerElse
  SetMenuManagerRuntimeInt("Is64Bit", #False)
CompilerEndIf

LoadMenuManager("xml-IfConditions.xml")
Message.s = "'If' Conditions Example" + #LF$ + #LF$ + "Menus and Menu Items defined by" + #LF$ + "If conditions and Runtime values"
OpenExampleWindow(0, "MenuManager - If Conditions", Message)
BuildManagedMenu(0, 0, "main")

Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
FreeMenuManager()
