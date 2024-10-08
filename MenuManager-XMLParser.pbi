; +-----------------------+
; | MenuManager-XMLParser |
; +-----------------------+
; | 2024-10-08 : Creation (PureBasic 6.12)

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

Procedure _MM_AddXMLAttribute(*Node._MM_XMLNode, Name.s, Value.s)
  AddElement(*Node\Attribute())
  *Node\Attribute()\Name = Name
  *Node\Attribute()\Value = Value
EndProcedure

Procedure.s _MM_GetXMLAttribute(*Node._MM_XMLNode, Attribute.s)
  Protected Result.s = ""
  
  If (*Node And Attribute)
    PushListPosition(*Node\Attribute())
    ForEach (*Node\Attribute())
      ;If (*Node\Attribute()\Name = Attribute)
      If (LCase(*Node\Attribute()\Name) = LCase(Attribute))
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
      ChangeCurrentElement(*Node\Parent\Child(), *Node)
      If (NextElement(*Node\Parent\Child()))
        *Child = @*Node\Parent\Child()
      EndIf
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
      If (*ParentNode\Child()\Name)
        *Child = @*ParentNode\Child()
        Break
      EndIf
    Next
    PopListPosition(*ParentNode\Child())
  EndIf
  
  ProcedureReturn (*Child)
EndProcedure

Procedure.i _MM_ParseXMLNode(*Root._MM_XMLNode, *Node._MM_XMLNode, *Start.CHARACTER, *Stop.CHARACTER)
  Protected Result.i = #False
  
  If (*Root And *Node And *Start)
    If (*Start\c = '<')
      
      If (*Stop = #Null)
        *Stop = *Start
        While (*Stop\c <> #NUL)
          *Stop + SizeOf(CHARACTER)
        Wend
      EndIf
      
      ;Debug PeekS(*Start, *Stop - *Start)
      
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
        _MM_AddXMLAttribute(*Root, "Status", Str(#PB_XML_Success))
        _MM_ParseXMLNode(*Root, *Root, @Input, #Null)
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
    FreeMemory(*Node)
  ;EndIf
EndProcedure

Procedure.i _MM_FreeXML(*XML)
  If (*XML)
    _MM_FreeXMLNode(*XML)
  EndIf
  ProcedureReturn (#Null)
EndProcedure

CompilerEndIf
;-
