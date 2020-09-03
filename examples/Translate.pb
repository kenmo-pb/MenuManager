; +--------------------------------+
; | MenuManager Example: Translate |
; +--------------------------------+

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

Global Language.i = 0

Global NewMap English.s()
  English("title-file") = "_File"
  English("title-help") = "_Help"
  English("new")        = "_New"
  English("quit")       = "_Quit"
  English("help")       = "_Help"
  English("about")      = "_About"

Global NewMap German.s()
  German("title-file") = "_Datei"
  German("title-help") = "_Hilfe"
  German("new")        = "_Neu"
  German("quit")       = "_Beenden"
  German("help")       = "_Hilfe"
  German("about")      = "_Uber"

Runtime Procedure.s TranslateProc(Text.s, MMID.s)
  If (Language = 1)
    ProcedureReturn German(MMID)
  Else
    ProcedureReturn English(MMID)
  EndIf
EndProcedure

Runtime Procedure ToggleLanguage()
  Language = 1 - Language
  BuildManagedMenu(0, 0, "main")
EndProcedure

LoadMenuManager("xml-Translate.xml")
Message.s = "Translate Example" + #LF$ + #LF$ + "Press Space to toggle the menu language"
OpenExampleWindow(0, "MenuManager - Translate", Message)
BuildManagedMenu(0, 0, "main")

Repeat
  Event = WaitWindowEvent()
Until (Event = #PB_Event_CloseWindow)
FreeMenuManager()

