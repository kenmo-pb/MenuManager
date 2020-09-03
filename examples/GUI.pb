; +--------------------------+
; | MenuManager Example: GUI |
; +--------------------------+

XIncludeFile "../MenuManager.pbi"
XIncludeFile "Examples-Common.pbi"

CompilerIf (Not Defined(PB_MessageRequester_Warning, #PB_Constant))
  #PB_MessageRequester_Warning = #Null
CompilerEndIf

Enumeration ; Gadgets
  #ShortcutList
  #Label
  #Reset
  #Defaults
  #Apply
EndEnumeration

LoadMenuManager("xml-GUI.xml")
OpenWindow(0, 0, 0, 360, 300, "GUI Example",
    #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
ListIconGadget(#ShortcutList, 10, 10, WindowWidth(0)-20, 200, "Action", 160, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#ShortcutList, 1, "Shortcut", 160)
TextGadget(#Label, 10, GadgetY(#ShortcutList) + GadgetHeight(#ShortcutList) + 5, GadgetWidth(#ShortcutList), 25,
    "Double-click to edit a shortcut", #PB_Text_Center)

ButtonGadget(#Reset, 10, 240, 100, 25, "Reset")
ButtonGadget(#Defaults, 130, 240, 100, 25, "Defaults")
ButtonGadget(#Apply, 250, 240, 100, 25, "Apply")

BuildManagedMenu(0, 0, "main")

Procedure.i ExampleValidator(Shortcut.i)
  If (IsBareShortcut(Shortcut))
    MessageRequester("Invalid: " + ComposeShortcut(Shortcut), "In this example, bare keys (without modifiers) are not allowed!", #PB_MessageRequester_Warning)
    ProcedureReturn (#False)
  EndIf
  ProcedureReturn (#True)
EndProcedure

Procedure UpdateButtons()
  DisableGadget(#Reset, 1-GUIShortcutsChanged())
  DisableGadget(#Defaults, 1-GUIShortcutsChanged(#True))
  DisableGadget(#Apply, 1-GUIShortcutsChanged())
EndProcedure

Procedure UpdateShortcuts()
  n = CountGadgetItems(#ShortcutList)
  For i = 0 To n - 1
    *Item = GetGadgetItemData(#ShortcutList, i)
    If *Item
      SelectMenuManagerItem(*Item)
      SetGadgetItemText(#ShortcutList, i, ComposeShortcut(MenuManagerItemShortcut(#True)), 1)
    EndIf
  Next i
EndProcedure

If ExamineMenuManagerItems()
  i.i = 0
  While NextMenuManagerItem()
    AddGadgetItem(#ShortcutList, i, MenuManagerItemGroup() + " -> " + MenuManagerItemName())
    SetGadgetItemData(#ShortcutList, i, MenuManagerItemPointer())
    i + 1
  Wend
EndIf

SetShortcutRequesterValidator(@ExampleValidator())
UpdateShortcuts()
UpdateButtons()
Repeat
  Event = WaitWindowEvent()
  
  If (Event = #PB_Event_Gadget)
    Select (EventGadget())
      Case #ShortcutList
        If (EventType() = #PB_EventType_LeftDoubleClick)
          i = GetGadgetState(#ShortcutList)
          If (i >= 0)
            *Item = GetGadgetItemData(#ShortcutList, i)
            If (*Item)
              SelectMenuManagerItem(*Item)
              New = ShortcutRequesterSimple("", "Choose a shortcut for '" + MenuManagerItemName() + "':", 0)
              If (New <> -1)
                AssignShortcut(MenuManagerItemMMID(), New, #True)
                UpdateShortcuts()
                UpdateButtons()
              EndIf
            EndIf
          EndIf
        EndIf
      Case #Defaults
        ResetGUIShortcuts(#True)
        UpdateShortcuts()
        UpdateButtons()
      Case #Reset
        ResetGUIShortcuts(#False)
        UpdateShortcuts()
        UpdateButtons()
      Case #Apply
        CaptureGUIShortcuts()
        BuildManagedMenu(0, 0, "main") ; Rebuild menu to display and apply new assignments
        UpdateShortcuts()
        UpdateButtons()
    EndSelect
  
  ElseIf (Event = #PB_Event_Menu)
    Debug MenuManagerNameFromNumber(EventMenu())
    If (MenuManagerMMIDFromNumber(EventMenu()) = "quit")
      Event = #PB_Event_CloseWindow
    EndIf
  
  EndIf
Until (Event = #PB_Event_CloseWindow)
FreeMenuManager()
