; +-----------------------+
; | MenuManager-Requester |
; +-----------------------+

;-
CompilerIf (Not Defined(_MenuManager_Requester_Included, #PB_Constant))
#_MenuManager_Requester_Included = #True

;- Compile Switches

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
  ;XIncludeFile "MenuManager.pbi"
CompilerEndIf

CompilerIf (Not Defined(PB_Window_NoActivate, #PB_Constant))
  #PB_Window_NoActivate = #Null
CompilerEndIf


;-
;- Prototypes

Prototype.s _MenuManager_RequesterTranslator(Text.s, MMID.s)
Prototype.i _MenuManager_RequesterValidator(Shortcut.i)

;-
;- Variables - Private

Global _MenuManager_RequesterTranslate._MenuManager_RequesterTranslator = #Null
Global _MenuManager_RequesterValidate._MenuManager_RequesterValidator   = #Null


;-
;- Procedures - Public

Procedure.i ShortcutRequester(Title.s = "", Message.s = "", InitialShortcut.i = #Null, ParentWindow.i = -1, CancelValue.i = -1, AllowEnterEscape.i = #False)
  Protected Result.i = CancelValue
  
  CompilerIf (Defined(NormalizeShortcut, #PB_Procedure))
    InitialShortcut = NormalizeShortcut(InitialShortcut)
    CancelValue     = NormalizeShortcut(CancelValue)
  CompilerEndIf
  
  ; TODO: Use DPI-aware scaling
  Protected ScalingX.f = 1.0
  Protected ScalingY.f = 1.0
  
  Protected OKCaption.s     = "OK"
  Protected RemoveCaption.s = "Remove"
  Protected CancelCaption.s = "Cancel"
  If (_MenuManager_RequesterTranslate)
    Protected TempS.s
    TempS = _MenuManager_RequesterTranslate(OKCaption, "requester.ok")
    If (TempS)
      OKCaption = TempS
    EndIf
    TempS = _MenuManager_RequesterTranslate(RemoveCaption, "requester.remove")
    If (TempS)
      RemoveCaption = TempS
    EndIf
    TempS = _MenuManager_RequesterTranslate(CancelCaption, "requester.cancel")
    If (TempS)
      CancelCaption = TempS
    EndIf
  EndIf
  
  If (Title = "")
    Title = "Shortcut"
  EndIf
  If (Message = "")
    Message = "Choose a shortcut:"
  EndIf
  
  Protected ButtonWidth.i  = 80 * ScalingX
  Protected ButtonHeight.i = 22 * ScalingY
  
  Protected TextWidth.i  = 3 * ButtonWidth
  Protected TextHeight.i = ButtonHeight
  
  CompilerIf (Defined(PB_Gadget_RequiredSize, #PB_Constant))
    Protected TempWin.i = OpenWindow(#PB_Any, 0, 0, 100, 100, "", #PB_Window_Invisible | #PB_Window_NoActivate)
    If (TempWin)
      Protected TempGad.i = ButtonGadget(#PB_Any, 0, 0, ButtonWidth, ButtonHeight, "")
      Protected TempW.i
      SetGadgetText(TempGad, OKCaption)
      TempW = GadgetWidth(TempGad, #PB_Gadget_RequiredSize)
      If (TempW > ButtonWidth)
        ButtonWidth = TempW
      EndIf
      SetGadgetText(TempGad, RemoveCaption)
      TempW = GadgetWidth(TempGad, #PB_Gadget_RequiredSize)
      If (TempW > ButtonWidth)
        ButtonWidth = TempW
      EndIf
      SetGadgetText(TempGad, CancelCaption)
      TempW = GadgetWidth(TempGad, #PB_Gadget_RequiredSize)
      If (TempW > ButtonWidth)
        ButtonWidth = TempW
      EndIf
      ButtonHeight = GadgetHeight(TempGad, #PB_Gadget_RequiredSize)
      FreeGadget(TempGad)
      
      TempGad    = TextGadget(#PB_Any, 0, 0, 100, 100, Message)
      TextWidth  = GadgetWidth(TempGad, #PB_Gadget_RequiredSize)
      TextHeight = GadgetHeight(TempGad, #PB_Gadget_RequiredSize)
      FreeGadget(TempGad)
      
      CloseWindow(TempWin)
    EndIf
  CompilerEndIf
  
  Protected Padding.i = 10 * ScalingY
  Protected WinW.i = 4 * Padding + 3 * ButtonWidth
  Protected WinH.i = 4 * Padding + 2 * ButtonHeight + TextHeight
  
  If (WinW < TextWidth + 2 * Padding)
    WinW = TextWidth + 2 * Padding
  EndIf
  
  Protected Flags.i = #PB_Window_SystemMenu | #PB_Window_Invisible
  Protected ParentID.i = #Null
  If (ParentWindow <> -1)
    ParentID = WindowID(ParentWindow)
    Flags | #PB_Window_WindowCentered
  Else
    Flags | #PB_Window_ScreenCentered
  EndIf
  Protected Win.i = OpenWindow(#PB_Any, 0, 0, WinW, WinH, Title, Flags, ParentID)
  If (Win)
    If (ParentWindow <> -1)
      DisableWindow(ParentWindow, #True)
    EndIf
    Protected Label.i = TextGadget(#PB_Any, Padding, Padding, WinW - 2*Padding, ButtonHeight, Message, #PB_Text_Center)
    Protected Gadget.i = ShortcutGadget(#PB_Any, WinW/2 - ButtonWidth, 2*Padding + TextHeight, 2*ButtonWidth, ButtonHeight, InitialShortcut)
    Protected OK.i = ButtonGadget(#PB_Any, WinW/2 - ButtonWidth/2 - Padding - ButtonWidth, 3*Padding + TextHeight + ButtonHeight, ButtonWidth, ButtonHeight, OKCaption, #PB_Button_Default)
    Protected Remove.i = ButtonGadget(#PB_Any, WinW/2 - ButtonWidth/2, 3*Padding + TextHeight + ButtonHeight, ButtonWidth, ButtonHeight, RemoveCaption)
    Protected Cancel.i = ButtonGadget(#PB_Any, WinW/2 - ButtonWidth/2 + Padding + ButtonWidth, 3*Padding + TextHeight + ButtonHeight, ButtonWidth, ButtonHeight, CancelCaption)
    
    HideWindow(Win, #False)
    SetActiveGadget(Gadget)
    
    Protected Done.i = #False
    Protected NewState.i, PrevState.i, Chosen.i
    Chosen = InitialShortcut
    PrevState = InitialShortcut
    Repeat
      Protected Event.i = WaitWindowEvent(10)
      If (Event = #PB_Event_CloseWindow)
        Done = #True
      ElseIf (Event = #PB_Event_Gadget)
        Select (EventGadget())
          Case (OK)
            If (_MenuManager_RequesterValidate)
              SetGadgetState(Gadget, Chosen)
              If (_MenuManager_RequesterValidate(Chosen))
                Result = Chosen
                Done = #True
              EndIf
            Else
              Result = Chosen
              Done = #True
            EndIf
          Case (Remove)
            Result = #Null
            Done = #True
          Case (Cancel)
            Done = #True
        EndSelect
      EndIf
      NewState = GetGadgetState(Gadget)
      If (NewState <> PrevState)
        If ((NewState = #PB_Shortcut_Return) And (Not AllowEnterEscape))
          PostEvent(#PB_Event_Gadget, Win, OK)
        ElseIf ((NewState = #PB_Shortcut_Escape) And (Not AllowEnterEscape))
          PostEvent(#PB_Event_Gadget, Win, Cancel)
        ElseIf ((NewState = #PB_Shortcut_F4 | #PB_Shortcut_Alt) And (Not AllowEnterEscape) And (#PB_Compiler_OS = #PB_OS_Windows))
          PostEvent(#PB_Event_Gadget, Win, Cancel)
        Else
          Chosen = NewState
          CompilerIf (Defined(NormalizeShortcut, #PB_Procedure))
            Chosen = NormalizeShortcut(Chosen)
          CompilerEndIf
        EndIf
        PrevState = NewState
      EndIf
    Until (Done)
    CloseWindow(Win)
    If (ParentWindow <> -1)
      DisableWindow(ParentWindow, #False)
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i ShortcutRequesterSimple(Title.s = "", Message.s = "", ParentWindow.i = -1)
  ProcedureReturn (ShortcutRequester(Title, Message, #Null, ParentWindow))
EndProcedure

Procedure SetShortcutRequesterTranslator(*Procedure)
  _MenuManager_RequesterTranslate = *Procedure
EndProcedure

Procedure SetShortcutRequesterValidator(*Procedure)
  _MenuManager_RequesterValidate = *Procedure
EndProcedure



CompilerEndIf
;-
