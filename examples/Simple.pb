; +-----------------------------------------+
; | MenuManager Example: Simple Window Menu |
; +-----------------------------------------+

XIncludeFile "../MenuManager.pbi"

Runtime Enumeration
  #New  = 5
  #Quit
  #Help
  #About
EndEnumeration




If LoadMenuManager("Simple.xml")
  
  Flags = #PB_Window_ScreenCentered | #PB_Window_SystemMenu
  OpenWindow(0, 0, 0, 320, 240, "MenuManager", Flags)
  
  BuildManagedMenu(0, 0, "main")
  
  Repeat
    Event = WaitWindowEvent()
    If (Event = #PB_Event_Menu)
      Debug "Menu Event: " + Str(EventMenu())
      If (EventMenu() = #Quit)
        Event = #PB_Event_CloseWindow
      EndIf
    EndIf
  Until (Event = #PB_Event_CloseWindow)
  
  FreeMenuManager()
Else
  Debug "Failed to load!"
EndIf
