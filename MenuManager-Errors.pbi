; +--------------------+
; | MenuManager-Errors |
; +--------------------+

;-
CompilerIf (Not Defined(_MenuManager_Errors_Included, #PB_Constant))
#_MenuManager_Errors_Included = #True

;- Constants

Enumeration
  #MenuManager_Error_None = 0
  #MenuManager_Error_CouldNotLoad
  #MenuManager_Error_Empty
  #MenuManager_Error_ParseError
  #MenuManager_Error_FormatInvalid
  #MenuManager_Error_NoItems
  #MenuManager_Error_NoItemID
  #MenuManager_Error_NoMenuID
  #MenuManager_Error_MissingRuntime
  #MenuManager_Error_MissingItem
  #MenuManager_Error_MissingMenu
  #MenuManager_Error_MenuNotAllowed
  #MenuManager_Error_TitleNotAllowed
  #MenuManager_Error_HiddenNotAllowed
  #MenuManager_Error_NetworkDisabled
  #MenuManager_Error_NetworkFailed
  #MenuManager_Error_DownloadFailed
  #MenuManager_Error_DecodeImage
  #MenuManager_Error_DuplicateShortcut
  #MenuManager_Error_GroupSizeInvalid
  #MenuManager_Error_MemoryPointerNull
  #MenuManager_Error_MemorySizeInvalid
  ;
  #_MenuManager_Error_Count
EndEnumeration



;-
;- Globals

Global _MenuManager_LastError.i
Global _MenuManager_LastErrorToken.s

;-
;- Procedures - Private

Procedure _MenuManager_SetLastError(Error.i, Token.s = "")
  _MenuManager_LastError      = Error
  _MenuManager_LastErrorToken = Token
EndProcedure


;-
;- Procedures - Public

Procedure.s MenuManagerErrorString(Error.i)
  Protected Result.s
  Select (Error)
    Case #MenuManager_Error_None
      Result = "No error"
    Case #MenuManager_Error_CouldNotLoad
      Result = "Could not load file: $"
    Case #MenuManager_Error_Empty
      Result = "Input is empty"
    Case #MenuManager_Error_ParseError
      Result = "Parsing error"
    Case #MenuManager_Error_FormatInvalid
      Result = "Format is invalid"
    Case #MenuManager_Error_NoItems
      Result = "No item definitions"
    Case #MenuManager_Error_NoItemID
      Result = "Item has no MMID"
    Case #MenuManager_Error_NoMenuID
      Result = "Menu has no MMID"
    Case #MenuManager_Error_MissingRuntime
      Result = "Missing runtime: $"
    Case #MenuManager_Error_MissingItem
      Result = "No item with MMID: $"
    Case #MenuManager_Error_MissingMenu
      Result = "No menu with MMID: $"
    Case #MenuManager_Error_MenuNotAllowed
      Result = "Menu not allowed here"
    Case #MenuManager_Error_TitleNotAllowed
      Result = "Title not allowed here"
    Case #MenuManager_Error_HiddenNotAllowed
      Result = "Hidden not allowed here"
    Case #MenuManager_Error_NetworkDisabled
      Result = "Network support is disabled: $"
    Case #MenuManager_Error_NetworkFailed
      Result = "Network initialization failed"
    Case #MenuManager_Error_DownloadFailed
      Result = "Could not download: $"
    Case #MenuManager_Error_DecodeImage
      Result = "Could not decode image: $"
    Case #MenuManager_Error_DuplicateShortcut
      Result = "Duplicate shortcut found: $"
    Case #MenuManager_Error_GroupSizeInvalid
      Result = "Group size 'N' is invalid: $"
    Case #MenuManager_Error_MemoryPointerNull
      Result = "Memory pointer is null"
    Case #MenuManager_Error_MemorySizeInvalid
      Result = "Memory size must be greater than 0"
      
    Default
      Result = "Undefined error (" + Str(Error) + ")"
  EndSelect
  Result = ReplaceString(Result, "$", _MenuManager_LastErrorToken)
  ProcedureReturn (Result)
EndProcedure

Procedure.i MenuManagerLastError()
  ProcedureReturn (_MenuManager_LastError)
EndProcedure

Procedure.s MenuManagerLastErrorString()
  ProcedureReturn (MenuManagerErrorString(_MenuManager_LastError))
EndProcedure

CompilerEndIf
;-
