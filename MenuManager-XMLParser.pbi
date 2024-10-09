; +-----------------------+
; | MenuManager-XMLParser |
; +-----------------------+
; | 2024-10-08 : Creation (PureBasic 6.12)

; ==============================================================================
;  WARNING: This is NOT a general purpose XML library!
;   It only provides a small subset of read-only XML functionality, so that
;   the MenuManager can load XML files without requiring the Expat library.
;   It does minimal error checking, and does not support all XML syntax.
;   We recommend enabling the Expat library while developing your application.
;   If you use this IncludeFile anywhere else, use at your own risk!
; ==============================================================================

;-
CompilerIf (Not Defined(_MenuManager_XMLParser_Included, #PB_Constant))
#_MenuManager_XMLParser_Included = #True

CompilerIf (#PB_Compiler_IsMainFile)
  EnableExplicit
CompilerEndIf

;-
;- Structures - Private

Structure _MM_XMLAttribute
  Name.s
  Value.s
EndStructure

Structure _MM_XMLNode
  Type.i
  Name.s
  *Parent._MM_XMLNode
  List Attribute._MM_XMLAttribute()
  List Child._MM_XMLNode()
EndStructure

;-
;- Procedures - Private

;Procedure _MM_AddXMLAttribute(*Node._MM_XMLNode, Name.s, Value.s)
;  AddElement(*Node\Attribute())
;  *Node\Attribute()\Name = Name
;  *Node\Attribute()\Value = Value
;EndProcedure

Procedure.s _MM_GetXMLAttribute(*Node._MM_XMLNode, Attribute.s)
  Protected Result.s = ""
  
  If (*Node And Attribute)
    PushListPosition(*Node\Attribute())
    ForEach (*Node\Attribute())
      ;If (LCase(*Node\Attribute()\Name) = LCase(Attribute))
      If (*Node\Attribute()\Name = Attribute) ; keep it case-sensitive, like PB/Expat
        Result = *Node\Attribute()\Value
        Break
      EndIf
    Next
    PopListPosition(*Node\Attribute())
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_ExamineXMLAttributes(*Node._MM_XMLNode)
  Protected Result.i = 0
  
  If (*Node)
    ResetList(*Node\Attribute())
    Result = ListSize(*Node\Attribute())
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_NextXMLAttribute(*Node._MM_XMLNode)
  Protected Result.i = #False
  
  If (*Node)
    If (NextElement(*Node\Attribute()))
      Result = #True
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s _MM_XMLAttributeName(*Node._MM_XMLNode)
  Protected Result.s = ""
  
  If (*Node)
    Result = *Node\Attribute()\Name
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s _MM_XMLAttributeValue(*Node._MM_XMLNode)
  Protected Result.s = ""
  
  If (*Node)
    Result = *Node\Attribute()\Value
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.s _MM_GetXMLNodeName(*Node._MM_XMLNode)
  Protected Result.s = ""
  
  If (*Node)
    Result = *Node\Name
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_NextXMLNode(*Node._MM_XMLNode)
  Protected *Child._MM_XMLNode = #Null
  If (*Node)
    If (*Node\Parent)
      PushListPosition(*Node\Parent\Child())
      ChangeCurrentElement(*Node\Parent\Child(), *Node)
      If (NextElement(*Node\Parent\Child()))
        *Child = @*Node\Parent\Child()
      EndIf
      PopListPosition(*Node\Parent\Child())
    EndIf
  EndIf
  ProcedureReturn (*Child)
EndProcedure

Procedure.i _MM_XMLNodeType(*Node._MM_XMLNode)
  If (*Node)
    ProcedureReturn (*Node\Type)
  EndIf
  ProcedureReturn (#PB_XML_Normal) ; or, error value?
EndProcedure

Procedure.i _MM_XMLStatus(*XML._MM_XMLNode)
  Protected Result.i = #PB_XML_UnexpectedState
  
  If (*XML)
    If (*XML\Type = #PB_XML_Root)
      Protected Value.s = _MM_GetXMLAttribute(*XML, "Status")
      If (Value)
        Result = Val(Value)
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_ChildXMLNode(*Node._MM_XMLNode, n.i = 1)
  Protected *Child._MM_XMLNode = #Null
  
  If (*Node And (n >= 1))
    PushListPosition(*Node\Child())
    ResetList(*Node\Child())
    Protected i.i
    For i = 1 To n
      If (NextElement(*Node\Child()))
        If (i = n)
          *Child = @*Node\Child()
        EndIf
      Else
        Break
      EndIf
    Next
    PopListPosition(*Node\Child())
  EndIf
  
  ProcedureReturn (*Child)
EndProcedure

Procedure.i _MM_RootXMLNode(*XML._MM_XMLNode)
  Protected *Node._MM_XMLNode = #Null
  
  If (*XML)
    If (*XML\Type = #PB_XML_Root)
      *Node = *XML
    EndIf
  EndIf
  
  ProcedureReturn (*Node)
EndProcedure

Procedure.i _MM_XMLNodeFromPath(*ParentNode._MM_XMLNode, Path.s)
  Protected *Child._MM_XMLNode = #Null
  
  If (*ParentNode And Path)
    PushListPosition(*ParentNode\Child())
    ForEach (*ParentNode\Child())
      ;If (LCase(*ParentNode\Child()\Name) = LCase(Path))
      If (*ParentNode\Child()\Name = Path) ; keep it case-sensitive, like PB/Expat
        *Child = @*ParentNode\Child()
        Break
      EndIf
    Next
    PopListPosition(*ParentNode\Child())
  EndIf
  
  ProcedureReturn (*Child)
EndProcedure

;Procedure.i _MM_AddXMLChild(*Parent._MM_XMLNode, Type.i = #PB_XML_Normal)
;  Protected *Child._MM_XMLNode = #Null
;  
;  If (*Parent)
;    LastElement(*Parent\Child())
;    *Child = AddElement(*Parent\Child())
;    If (*Child)
;      *Child\Parent = *Parent
;      *Child\Type = Type
;    EndIf
;  EndIf
;  
;  ProcedureReturn (*Child)
;EndProcedure

Procedure.s _MM_Unquote(Text.s)
  If ((Left(Text, 1) = #DQUOTE$) And (Right(Text, 1) = #DQUOTE$))
    ProcedureReturn (Mid(Text, 2, Len(Text) - 2))
  ElseIf ((Left(Text, 1) = "'") And (Right(Text, 1) = "'"))
    ProcedureReturn (Mid(Text, 2, Len(Text) - 2))
  EndIf
  ProcedureReturn (Text)
EndProcedure


CompilerIf (#False)

Procedure.s _MM_Quote(Text.s)
  If (FindString(Text, "'"))
    ProcedureReturn (#DQUOTE$ + Text + #DQUOTE$)
  EndIf
  ProcedureReturn ("'" + Text + "'")
EndProcedure

Procedure.s _MM_ComposeXML(*XML, Flags.i = #Null)
  Protected Result.s = ""
  
  If (*XML)
    Protected *Node._MM_XMLNode = *XML
    Protected *Parent._MM_XMLNode
    If ((*Node\Type = #PB_XML_Root) And (ListSize(*Node\Child()) = 1))
      Protected EOL.s = #LF$
      Protected SpacesPerIndent.i = 2
      Protected IndentLevel.i = 0
      Protected StepFlag.i
      
      *Node = _MM_ChildXMLNode(*Node)
      *Parent = *Node\Parent
      While (*Node)
        StepFlag = #True
        Result + Space(IndentLevel * SpacesPerIndent) + "<" + *Node\Name
        If (ListSize(*Node\Attribute()) > 0)
          ForEach (*Node\Attribute())
            Result + " " + *Node\Attribute()\Name + "=" + _MM_Quote(*Node\Attribute()\Value)
          Next
        EndIf
        If (ListSize(*Node\Child()) > 0)
          Result + ">" + EOL
          IndentLevel + 1
          *Node = _MM_ChildXMLNode(*Node)
          *Parent = *Node\Parent
          StepFlag = #False
        Else
          Result + " />" + EOL
        EndIf
        
        While (StepFlag)
          StepFlag = #False
          *Node = _MM_NextXMLNode(*Node)
          If (Not *Node)
            *Node = *Parent
            *Parent = *Node\Parent
            If (*Node\Type = #PB_XML_Root)
              *Node = #Null
            Else
              IndentLevel - 1
              Result + Space(IndentLevel * SpacesPerIndent) + "</" + *Node\Name + ">" + EOL
              StepFlag = #True
            EndIf
          EndIf
        Wend
      Wend
    EndIf
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

CompilerEndIf


Procedure.i _MM_ParseXMLFull(*Root._MM_XMLNode, *Start.CHARACTER)
  Protected Result.i = #False
  
  If (*Root And *Start)
    
    Protected *CurrentParent._MM_XMLNode = *Root
    Protected *Node._MM_XMLNode
    Protected NestedLevel.i = 0
    Protected *Char.CHARACTER = *Start
    Protected *TagOpen.CHARACTER = #Null
    Protected *TagClose.CHARACTER = #Null
    Protected InComment.i = #False
    Protected ParseTagFlag.i = #False
    Protected BuildText.s = ""
    Protected BuildChar.s = ""
    
    Result = #True
    
    Protected ExitFlag.i = #False
    While (Not ExitFlag)
      If (InComment)
        BuildChar = ""
      Else
        BuildChar = Chr(*Char\c)
        If ((BuildChar = #CR$) Or (BuildChar = #LF$))
          BuildChar = " "
        EndIf
      EndIf
      If (InComment)
        Select (*Char\c)
          Case '>'
            If (PeekC(*Char - 1*SizeOf(CHARACTER)) = '-')
              If (PeekC(*Char - 2*SizeOf(CHARACTER)) = '-')
                InComment = #False
              EndIf
            EndIf
          Case #NUL
            ExitFlag = #True
        EndSelect
      Else
        Select (*Char\c)
          Case '<'
            If (PeekC(*Char + 1*SizeOf(CHARACTER)) = '!')
              If (PeekC(*Char + 2*SizeOf(CHARACTER)) = '-')
                If (PeekC(*Char + 3*SizeOf(CHARACTER)) = '-')
                  InComment = #True
                  BuildChar = ""
                  *Char + 3*SizeOf(CHARACTER)
                EndIf
              EndIf
            EndIf
            If (Not InComment)
              If (Not *TagOpen)
                *TagOpen = *Char
              EndIf
            EndIf
          Case '>'
            If (*TagOpen)
              *TagClose = *Char
              ParseTagFlag = #True
            EndIf
          Case #NUL
            ExitFlag = #True
        EndSelect
      EndIf
      If (*TagOpen)
        BuildText + BuildChar
      EndIf
      If (ParseTagFlag)
        If (PeekC(*TagOpen + SizeOf(CHARACTER)) = '?')
          ; ignore
        ElseIf (PeekC(*TagOpen + SizeOf(CHARACTER)) = '/')
          If (NestedLevel > 0)
            NestedLevel - 1
            ;Debug "Nesting -- " + Str(NestedLevel)
            *CurrentParent = *CurrentParent\Parent
            ;Debug "  (close tag)"
          Else
            ; nesting error!
            ;Debug "Nesting error!"
            Result = #False
            ExitFlag = #True
          EndIf
        Else
          ;Debug "Tag to parse: " + BuildText
          LastElement(*CurrentParent\Child())
          *Node = AddElement(*CurrentParent\Child())
          *Node\Parent = *CurrentParent
          *Node\Type = #PB_XML_Normal
          
          Protected InString.i = #False
          Protected QuoteChar.i
          Protected *TermStart.CHARACTER = @BuildText + SizeOf(CHARACTER)
          Protected *TermStop.CHARACTER = *TermStart
          While (#True)
            If (InString)
              If (*TermStop\c = QuoteChar)
                InString = #False
              EndIf
            Else
              Select (*TermStop\c)
                Case '"', Asc("'")
                  InString = #True
                  QuoteChar = *TermStop\c
                Case ' ', #TAB, '/', '>', #NUL
                  If (*TermStart < *TermStop)
                    Protected Term.s = PeekS(*TermStart, (*TermStop - *TermStart)/SizeOf(CHARACTER))
                    ;Debug "  Term to parse: " + Term
                    If (*Node\Name = "")
                      *Node\Name = Term
                    Else
                      AddElement(*Node\Attribute())
                      Protected i.i
                      i = FindString(Term, "=")
                      If (i > 0)
                        *Node\Attribute()\Name = Trim(Left(Term, i-1))
                        *Node\Attribute()\Value = _MM_Unquote(Trim(Mid(Term, i+1)))
                        CompilerIf (Defined(UnescapeString, #PB_Function) And Defined(PB_String_EscapeXML, #PB_Constant))
                          *Node\Attribute()\Value = UnescapeString(*Node\Attribute()\Value, #PB_String_EscapeXML)
                        CompilerElse
                          *Node\Attribute()\Value = ReplaceString(*Node\Attribute()\Value, "&lt;", "<")
                          *Node\Attribute()\Value = ReplaceString(*Node\Attribute()\Value, "&gt;", ">")
                          *Node\Attribute()\Value = ReplaceString(*Node\Attribute()\Value, "&amp;", "&")
                        CompilerEndIf
                      Else
                        *Node\Attribute()\Name = Trim(Term)
                      EndIf
                      ;Debug *Node\Attribute()\Name + " === " + *Node\Attribute()\Value
                    EndIf
                  EndIf
                  *TermStart = *TermStop + SizeOf(CHARACTER)
                Default
                  ; ...
              EndSelect
            EndIf
            If (*TermStop\c = #NUL)
              Break
            EndIf
            *TermStop + SizeOf(CHARACTER)
          Wend
          
          If (PeekC(*TagClose - SizeOf(CHARACTER)) = '/')
            ; standalone item, OK
            ;Debug "  (standalone)"
          Else
            ; parse children nodes...
            NestedLevel + 1
            ;Debug "Nesting ++ " + Str(NestedLevel)
            *CurrentParent = *Node
          EndIf
        EndIf
        *TagOpen = #Null
        *TagClose = #Null
        BuildText = ""
        ParseTagFlag = #False
      EndIf
      *Char + SizeOf(CHARACTER)
    Wend
    
    ; Final validation...
    If (Result)
      If (NestedLevel <> 0)
        Result = #False
      Else
        If (ListSize(*Root\Child()) <> 1)
          Result = #False
        Else
          If (*Root\Child()\Name = "")
            Result = #False
          EndIf
        EndIf
      EndIf
    EndIf
    
  EndIf
  
  ProcedureReturn (Result)
EndProcedure

Procedure.i _MM_ParseXML(Input.s)
  Protected *Root._MM_XMLNode = #Null
  
  Input = Trim(Input)
  
  If (Input)
    Protected SeemsValid.i = #False
    
    If (Left(Input, 1) = "<")
      SeemsValid = #True
    EndIf
    
    If (SeemsValid)
      *Root = AllocateMemory(SizeOf(_MM_XMLNode))
      If (*Root)
        InitializeStructure(*Root, _MM_XMLNode)
        *Root\Type = #PB_XML_Root
        ;_MM_AddXMLAttribute(*Root, "Status", Str(#PB_XML_Success))
        AddElement(*Root\Attribute())
        *Root\Attribute()\Name = "Status"
        *Root\Attribute()\Value = Str(#PB_XML_Success)
        If (_MM_ParseXMLFull(*Root, @Input))
          ; OK
        Else
          ; status error?
          *Root\Attribute()\Value = Str(#PB_XML_Syntax)
        EndIf
      EndIf
    EndIf
  EndIf
  
  ProcedureReturn (*Root)
EndProcedure

Procedure _MM_FreeXMLNode(*Node._MM_XMLNode)
  ;If (*Node)
    ForEach (*Node\Child())
      _MM_FreeXMLNode(@*Node\Child())
    Next
    ClearList(*Node\Child())
    ClearList(*Node\Attribute())
    ClearStructure(*Node, _MM_XMLNode)
    ;FreeMemory(*Node)
  ;EndIf
EndProcedure

Procedure.i _MM_FreeXML(*XML)
  If (*XML)
    _MM_FreeXMLNode(*XML)
    FreeMemory(*XML)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

CompilerEndIf
;-
