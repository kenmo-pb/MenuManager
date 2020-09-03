; +-----------------------------+
; | MenuManager Example: Common |
; +-----------------------------+

CompilerIf (#PB_Compiler_IsMainFile)
  CompilerError #PB_Compiler_Filename + " is intended to be included in other files"
CompilerEndIf

Runtime Enumeration
  #Img_New
  #Img_Open
  #Img_Delete
  ;
  #Img_Count
EndEnumeration

Procedure.i OpenExampleWindow(Window.i, Title.s, Message.s = "", *ButtonCallback = #Null)
  Protected Flags.i = #PB_Window_ScreenCentered | #PB_Window_SystemMenu
  Protected Result.i = OpenWindow(Window, 0, 0, 360, 240, Title, Flags)
  If (Result)
    TextGadget(0, 0, 10, WindowWidth(Window), 100, StringField(Message, 1, "|"), #PB_Text_Center)
    If (*ButtonCallback)
      ButtonGadget(1, WindowWidth(Window)/2 - 90, GadgetY(0) + GadgetHeight(0), 180, 25, StringField(Message, 2, "|"))
      BindGadgetEvent(1, *ButtonCallback)
    EndIf
  EndIf
  ProcedureReturn (Result)
EndProcedure

Procedure CreateExampleImages()
  LoadFont(0, "Arial", 10)
  For i = 0 To #Img_Count - 1
    If (CreateImage(i, 16, 16, 32, $A0FFA0))
      If (StartDrawing(ImageOutput(i)))
        DrawingMode(#PB_2DDrawing_Transparent)
        DrawingFont(FontID(0))
        Select (i)
          Case #Img_New
            DrawText(2, 0, "N", $000000)
          Case #Img_Open
            DrawText(2, 0, "O", $000000)
          Case #Img_Delete
            DrawText(2, 0, "D", $000000)
          Default
            DrawText(2, 0, Str(i), $000000)
        EndSelect
        StopDrawing()
      EndIf
    EndIf
  Next i
EndProcedure
