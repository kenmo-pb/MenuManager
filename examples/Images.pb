; +-----------------------------+
; | MenuManager Example: Images |
; +-----------------------------+

; Options you can define (BEFORE including MenuManager.pbi)
#MenuManager_UseNetworkImages  = #True    ; Allow download images by URL
#MenuManager_IgnoreImageErrors = #True    ; Continue building menu if image fails to load
#MenuManager_SkipFailedDomains = #True    ; Skip domain if a download has already failed

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

UsePNGImageDecoder()
CreateExampleImages()

Procedure ButtonCallback()
  BuildManagedPopupMenu(1, "popup")
  DisplayPopupMenu(1, WindowID(0))
EndProcedure

LoadMenuManager("xml-Images.xml")
Message.s = "Images Example" + #LF$ + #LF$ + "Menu images specified by constant, number, and URL/file" + #LF$ + "(including popup menu)" + "|Display popup menu"
OpenExampleWindow(0, "MenuManager - Images", Message, @ButtonCallback())
BuildManagedMenu(0, 0, "main")

Repeat : Until (WaitWindowEvent() = #PB_Event_CloseWindow)
FreeMenuManager()

