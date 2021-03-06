unit UframeTextEditor;  // I3323   // I4797

interface

uses
  System.Types,
  System.JSON,
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ImgList,
  MenuImgList, ExtCtrls,

  UserMessages,
  Keyman.Developer.UI.UframeCEFHost,
  TextFileFormat, UfrmTike,
  System.ImageList,
  Vcl.StdCtrls, KMDActionInterfaces;

type
  TParColourLineType = (pcltNone, pcltBreakpoint, pcltExecutionPoint, pcltError);

  TframeTextEditor = class(TTIKEForm, IKMDSearchActions, IKMDEditActions, IKMDTextEditorActions)
    lstImages: TMenuImgList;
    dlgFonts: TFontDialog;
    dlgPrintSetup: TPrinterSetupDialog;
    lstImagesDisabled: TImageList;
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TntFormDestroy(Sender: TObject);
  private
    class var FInitialFilenameIndex: Integer;
  private

    FSelectedRow: Integer;
    FSelectedCol: Integer;
    FCanUndo: Boolean;
    FCanRedo: Boolean;
    FHasSelection: Boolean;
    FLoading: Boolean;
    FEditorFormat: TEditorFormat;
    FOnChanged: TNotifyEvent;
    FTextFileFormat: TTextFileFormat;

    cef: TframeCEFHost;
    FFilename: string;

    procedure RefreshOptions;
    function GetText: WideString;
    procedure SetText(Value: WideString);
    procedure SetEditorFormat(const Value: TEditorFormat);
    procedure Changed;
    procedure UpdateState(ALocation: string);
    procedure ClearError;
    procedure SetCharFont(const Value: TFont);
    procedure SetCodeFont(const Value: TFont);
    function GetCharFont: TFont;
    function GetCodeFont: TFont;
    procedure SetTextFileFormat(const Value: TTextFileFormat);

    procedure cefBeforeBrowse(Sender: TObject; const Url: string; out Result: Boolean);
    procedure cefLoadEnd(Sender: TObject);
    procedure LoadFileInBrowser(const AData: string);
    procedure WMUser_FireCommand(var Message: TMessage); message WM_USER_FireCommand;
    procedure FireCommand(const commands: TStringList);
    procedure UpdateInsertState(const AMode: string);
    procedure ExecuteCommand(const command: string; const parameters: TJSONValue = nil);
    procedure UpdateToken(command: string);
    procedure SetCursorPosition(AColumn, ARow: Integer);
  protected
    function GetHelpTopic: string; override;

    procedure SaveToStream(AStream: TStream);

    { IKMDSearchActions }
    procedure EditFind;
    procedure EditFindNext;
    procedure EditReplace;
    function CanEditFind: Boolean;
    function CanEditFindNext: Boolean;

    { IKMDEditActions }
    procedure CutToClipboard;
    procedure CopyToClipboard;
    procedure PasteFromClipboard;
    procedure Undo;
    procedure Redo;   // I4032
    procedure SelectAll;
    procedure ClearSelection;
    function CanCut: Boolean;
    function CanCopy: Boolean;
    function CanPaste: Boolean;
    function CanUndo: Boolean;
    function CanRedo: Boolean;   // I4032
    function CanSelectAll: Boolean;
    function CanClearSelection: Boolean;

    { IKMDTextEditorActions }
    function GetEditorFormat: TEditorFormat;
    function GetSelectedRow: Integer;

  public
    { Public declarations }
    procedure UpdateParColour(par: Integer; LineType: TParColourLineType);
    procedure SetFocus; override;

    procedure FindError(ln: Integer);
    procedure FindErrorByOffset(offset: Integer);   // I4083
    function OffsetToLine(Offset: Integer): Integer;   // I4083

    procedure SyntaxColourChange;

    function PrintFile(Header: WideString = ''): Boolean;
    function PrintPreview(Header: WideString = ''): Boolean;

    procedure LoadFromFile(AFileName: WideString); overload;   // I4034
    procedure LoadFromStream(AStream: TStream); overload;  // I2964
    procedure SaveToFile(AFileName: WideString);
    procedure LoadFromFile(AFileName: WideString; ATextFileFormat: TTextFileFormat); overload;   // I4034
    procedure LoadFromStream(AStream: TStream; ATextFileFormat: TTextFileFormat); overload;  // I2964

    procedure SetSelectedRow(ARow: Integer);

    property EditorText: WideString read GetText write SetText;
    property EditorFormat: TEditorFormat read GetEditorFormat write SetEditorFormat;
    property OnChanged: TNotifyEvent read FOnChanged write FonChanged;

    property CodeFont: TFont read GetCodeFont write SetCodeFont;
    property CharFont: TFont read GetCharFont write SetCharFont;
    property TextFileFormat: TTextFileFormat read FTextFileFormat write SetTextFileFormat;
  end;

implementation

uses
  System.TypInfo,
  Vcl.Clipbrd,
  Keyman.Developer.System.HelpTopics,

  dmActionsMain,
  dmActionsTextEditor,
  CharacterInfo,
  CharMapDropTool,
  keyboardparser,
  KeymanDeveloperOptions,
  kwhelp,
  ErrorControlledRegistry,
  RegistryKeys,
  UfrmHelp,
  UfrmMain,
  UmodWebHTTPServer,
  Unicode,
  utilhttp,
  utilstr;

{$R *.dfm}

{ TframeTextEditor }

procedure TframeTextEditor.RefreshOptions;
begin
  //TODO: memo.TabStops   := FKeymanDeveloperOptions.IndentSize;
end;

procedure TframeTextEditor.cefBeforeBrowse(Sender: TObject; const Url: string; out Result: Boolean);
var
  params: TStringList;
begin
  Result := False;

  if csDestroying in ComponentState then   // I3983
  begin
    Result := True;
    Exit;
  end;

  if GetParamsFromURL(URL, params) then
  begin
    PostMessage(Handle, WM_USER_FireCommand, 0, Integer(params));
    Result := True;
  end;
end;

procedure TframeTextEditor.cefLoadEnd(Sender: TObject);
begin
  //
end;

procedure TframeTextEditor.Changed;
begin
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

procedure TframeTextEditor.FormCreate(Sender: TObject);
begin
  inherited;

  cef := TframeCEFHost.Create(Self);
  cef.Parent := Self;
  cef.Visible := True;
  cef.OnBeforeBrowse := cefBeforeBrowse;
//  cef.OnLoadEnd := cefLoadEnd;
end;

type
  TAccessWinControl = class(TWinControl);

procedure TframeTextEditor.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
  function ShiftStateToLParam(Shift: TShiftState): Integer;
  const
    AltMask = $20000000;
  begin
    if ssAlt in Shift then
      Result := AltMask
    else
      Result := 0;
  end;
var
  msg: TWMKey;
begin
  if (Owner is TCustomForm) and (Owner as TCustomForm).KeyPreview then
  begin
    msg.Msg := WM_KEYDOWN;
    msg.CharCode := Key;
    msg.KeyData := ShiftStateToLParam(Shift);
    if TAccessWinControl(Owner).DoKeyDown(msg) then Key := 0;
  end;
end;

function TframeTextEditor.GetCharFont: TFont;
begin
Result := Font;
//  if FEditorFormat = efHTML
//    then Result := memo.Font   // I1426 - script tags should be 'code' font
//    else Result := Memo.AltFont;
end;

function TframeTextEditor.GetCodeFont: TFont;
begin
  Result := Font;
//  if FEditorFormat = efHTML
//    then Result := Memo.AltFont  // I1426 - script tags should be 'code' font
//    else Result := Memo.Font;
end;

function TframeTextEditor.GetEditorFormat: TEditorFormat;
begin
  Result := FEditorFormat;
end;

function TframeTextEditor.GetText: WideString;
begin
  Result := modWebHttpServer.AppSource.GetSource(FFileName);
end;

procedure TframeTextEditor.LoadFromFile(AFileName: WideString);
var
  fs: TFileStream;
begin
  FLoading := True;
  try
    FFileName := AFileName;
    if FileExists(AFileName) then
    begin
      fs := TFileStream.Create(AFileName, fmOpenRead);
      try
        LoadFromStream(fs);
      finally
        fs.Free;
      end;
    end
    else
    begin
      TextFileFormat := tffUTF8;
      LoadFileInBrowser('');
    end;
  finally
    FLoading := False;
  end;
end;

procedure TframeTextEditor.LoadFromStream(AStream: TStream; ATextFileFormat: TTextFileFormat);  // I2964
var
  s: TStringList;
begin
  FLoading := True;
  try
    TextFileFormat := ATextFileFormat;

    s := TStringList.Create;
    try
      s.LoadFromStream(AStream, TextFileFormatToEncoding(TextFileFormat));   // I3637
      LoadFileInBrowser(s.Text);
    finally
      s.Free;
    end;

  finally
    FLoading := False;
  end;
end;

procedure TframeTextEditor.LoadFileInBrowser(const AData: string);
  function GenerateNewFilename: string;
  begin
    Inc(FInitialFilenameIndex);
    Result := '*texteditor*'+IntToStr(FInitialFilenameIndex);
  end;
const
  mode: array[TEditorFormat] of string = (
    'keyman', 'xml', 'text', 'html'
  );
begin
  if FFilename = '' then
    FFilename := GenerateNewFilename;
  modWebHTTPServer.AppSource.RegisterSource(FFilename, AData, True);
  cef.Navigate(modWebHttpServer.GetLocalhostURL + '/app/editor/?mode='+mode[FEditorFormat]+'&filename='+URLEncode(FFilename));   // I4195
end;

procedure TframeTextEditor.LoadFromFile(AFileName: WideString;
  ATextFileFormat: TTextFileFormat);   // I4034
var
  fs: TFileStream;
begin
  FLoading := True;
  try
    FFileName := AFileName;
    if FileExists(AFileName) then
    begin
      try
        fs := TFileStream.Create(AFileName, fmOpenRead);
        try
          LoadFromStream(fs, ATextFileFormat);
        finally
          fs.Free;
        end;
      except
        on E:EFOpenError do   // I4616   // I4721
        begin
          ShowMessage(E.Message);
          Exit;
        end;
      end;
    end
    else
    begin
      TextFileFormat := ATextFileFormat;
      LoadFileInBrowser('');
    end;
  finally
    FLoading := False;
  end;
end;

procedure TframeTextEditor.LoadFromStream(AStream: TStream);
var
  s: TStringList;
begin
  FLoading := True;
  try
    s := TStringList.Create;
    try
      s.LoadFromStream(AStream); // prolog determines encoding  // I3337
      if s.Encoding = TEncoding.UTF8 then  // I3337   // I3636
        TextFileFormat := tffUTF8
      else if s.Encoding = TEncoding.Unicode then  // I3337   // I3636
        TextFileFormat := tffUTF16
      else
        TextFileFormat := tffANSI;
      LoadFileInBrowser(s.Text);
    finally
      s.Free;
    end;

  finally
    FLoading := False;
  end;
end;

procedure TframeTextEditor.SaveToFile(AFileName: WideString);
var
  fs: TFileStream;
begin
  fs := TFileStream.Create(AFileName, fmCreate);
  with fs do
  try
    Self.SaveToStream(fs);
  finally
    Free;
  end;
end;


procedure TframeTextEditor.SaveToStream(AStream: TStream);
var
  FSource: string;
  ss: TStringStream;
begin
  FSource := modWebHttpServer.AppSource.GetSource(FFileName);
  case FTextFileFormat of
    tffANSI:  ss := TStringStream.Create(FSource, TEncoding.Default);
    tffUTF8:  ss := TStringStream.Create(FSource, TEncoding.UTF8);
    tffUTF16: ss := TStringStream.Create(FSource, TEncoding.Unicode);
    else raise EAssertionFailed.Create('Unsupported file format');
  end;
  try
    AStream.CopyFrom(ss, 0);
  finally
    ss.Free;
  end;
end;

(*
  with Source as TCharacterDragObject do
    s := Text[cmimText];
{    if IsUnicode
      then s := Format('U+%4.4X', [CharCode])
      else s := Format('d%d', [CharCode]);}

  memo.SelText := s;

  Windows.SetFocus(memo.Handle);

  Accept := (Source is TCharacterDragObject) and (X > 16) and (Y > 16);
  if Accept then
  begin
    memo.SetCaretFromMouse(X - 16, Y - 16);
  end;
 *)

procedure TframeTextEditor.UpdateInsertState(const AMode: string);
begin
  frmKeymanDeveloper.barStatus.Panels[1].Text := AMode;
end;

{ TODO: Cancelling errors with escape key
  if (Key=VK_ESCAPE) and (Shift = []) then
  begin
    ClearError;
  end;

  TODO: right-mouse
  if Button = mbRight then
  begin
    pt := memo.ClientToScreen(Point(X,Y));
    modActionsTextEditor.mnuTextEditor.Popup(pt.X, pt.Y);
  end;

  TODO: caret position change, update state
}

function TframeTextEditor.PrintFile(Header: WideString): Boolean;
begin
  Result := False;
  // TODO: print
end;

function TframeTextEditor.PrintPreview(Header: WideString): Boolean;
begin
  // TODO: print preview
  Result := True;
end;

procedure TframeTextEditor.SetCharFont(const Value: TFont);
begin
// TODO: fonts
//  if FEditorFormat = efHTML
//    then memo.Font := Value  // I1426 - script tags should be 'code' font
//    else memo.AltFont := Value;
end;

procedure TframeTextEditor.SetCodeFont(const Value: TFont);
begin
// TODO: fonts
//  if FEditorFormat = efHTML
//    then memo.AltFont := Value  // I1426 - script tags should be 'code' font
//    else memo.Font := Value;
end;

procedure TframeTextEditor.SetEditorFormat(const Value: TEditorFormat);
begin
  FEditorFormat := Value;
end;

procedure TframeTextEditor.SetFocus;
begin
  cef.SetFocus;
end;

procedure TframeTextEditor.SetSelectedRow(ARow: Integer);
begin
  SetCursorPosition(0, ARow);
end;

procedure TframeTextEditor.SetCursorPosition(AColumn, ARow: Integer);
var
  j: TJSONObject;
begin
  j := TJSONObject.Create;
  try
    j.AddPair('row', TJSONNumber.Create(ARow));
    j.AddPair('column', TJSONNumber.Create(AColumn));
    ExecuteCommand('moveCursor', j);
  finally
    j.Free;
  end;
{TODO:
  if (ALine >= EditorMemo.LineCount) or (ALine < 0) then Exit;
  EditorMemo.SelLine := ALine;
  EditorMemo.SelCol := 0;
  EditorMemo.SelLength := Length(EditorMemo.LinesArray[ALine]);
  EditorMemo.ScrollInView;
}
end;

function TframeTextEditor.GetSelectedRow: Integer;
begin
  Result := FSelectedRow;
end;

procedure TframeTextEditor.SetText(Value: WideString);
begin
  FLoading := True;
  try
    RefreshOptions;
    LoadFileInBrowser(Value);
  finally
    FLoading := False;
  end;
end;

procedure TframeTextEditor.SetTextFileFormat(const Value: TTextFileFormat);
var
  FSource: string;
begin
  if FTextFileFormat <> Value then
  begin
    FTextFileFormat := Value;
    if FTextFileFormat = tffANSI then
    begin
      // Recode to ANSI
      FSource := string(AnsiString(modWebHttpServer.AppSource.GetSource(FFileName)));
      SetText(FSource);
    end;
  end;
end;

procedure TframeTextEditor.SyntaxColourChange;
begin
  // TODO: syntax colouring
end;

procedure TframeTextEditor.UpdateState(ALocation: string);
begin
  if cef.HasFocus then
  begin
    if ALocation <> '' then
    begin
      FSelectedRow := StrToIntDef(StrToken(ALocation, ','),0);
      FSelectedCol := StrToIntDef(ALocation,0);
      frmKeymanDeveloper.barStatus.Panels[0].Text := Format('Line %d, Col %d', [FSelectedRow+1,FSelectedCol+1]);
    end;
  end;
end;

procedure TframeTextEditor.WMUser_FireCommand(var Message: TMessage);
var
  params: TStringList;
begin
  params := TStringList(Message.LParam);
  if (params.Count > 0) and (params[0] = 'command') then
  begin
    params.Delete(0);
    FireCommand(params);
  end;
  params.Free;
end;

{-------------------------------------------------------------------------------
 - Paragraph colour management and errors                                      -
 -------------------------------------------------------------------------------}

procedure TframeTextEditor.ClearError;
begin
  ExecuteCommand('highlightError');
end;

{ IKMDEditActions }

function TframeTextEditor.CanClearSelection: Boolean;
begin
  Result := FHasSelection;
end;

function TframeTextEditor.CanCopy: Boolean;
begin
  Result := FHasSelection;
end;

function TframeTextEditor.CanCut: Boolean;
begin
  Result := FHasSelection;
end;

function TframeTextEditor.CanPaste: Boolean;
begin
  Result := Clipboard.HasFormat(CF_TEXT);
end;

function TframeTextEditor.CanRedo: Boolean;
begin
  Result := FCanRedo;
end;

function TframeTextEditor.CanSelectAll: Boolean;
begin
  Result := True; // TODO: Only if we have text?
end;

function TframeTextEditor.CanUndo: Boolean;
begin
  Result := FCanUndo;
end;

procedure TframeTextEditor.Undo;
begin
  ExecuteCommand('editUndo');
end;

procedure TframeTextEditor.Redo;
begin
  ExecuteCommand('editRedo');
end;

procedure TframeTextEditor.SelectAll;
begin
  ExecuteCommand('editSelectAll');
end;

procedure TframeTextEditor.ClearSelection;
begin
  cef.cef.ClipboardDel;
end;

procedure TframeTextEditor.CopyToClipboard;
begin
  cef.cef.ClipboardCopy;
end;

procedure TframeTextEditor.CutToClipboard;
begin
  cef.cef.ClipboardCut;
end;

procedure TframeTextEditor.PasteFromClipboard;
begin
  cef.cef.ClipboardPaste;
end;

{ IKMDSearchActions }

function TframeTextEditor.CanEditFind: Boolean;
begin
  Result := True;
end;

function TframeTextEditor.CanEditFindNext: Boolean;
begin
  Result := True;
end;

procedure TframeTextEditor.EditFind;
begin
  if not cef.HasFocus then Exit;
  ExecuteCommand('searchFind');
end;

procedure TframeTextEditor.EditFindNext;
begin
  if not cef.HasFocus then Exit;
  ExecuteCommand('searchFindNext');
end;

procedure TframeTextEditor.EditReplace;
begin
  if not cef.HasFocus then Exit;
  ExecuteCommand('searchReplace');
end;

procedure TframeTextEditor.ExecuteCommand(const command: string; const parameters: TJSONValue);
begin
  if Assigned(parameters) then
  begin
    cef.cef.ExecuteJavaScript('window.editorGlobalContext.'+command+'('+parameters.ToJSON+')', '');
  end
  else
  begin
    cef.cef.ExecuteJavaScript('window.editorGlobalContext.'+command+'()', '');
  end;
end;

procedure TframeTextEditor.FindError(ln: Integer);
var
  v: TJSONNumber;
begin
  ClearError;
  if (ln <= 0) then Exit;

  v := TJSONNumber.Create(ln);
  try
    ExecuteCommand('highlightError', v);
  finally
    v.Free;
  end;
end;

function TframeTextEditor.OffsetToLine(Offset: Integer): Integer;   // I4083
begin
  Result := 0;
//  while (Result < memo.ParagraphCount) and (Offset > memo.PargrphOffset[Result]) do
//    Inc(Result);
end;

procedure TframeTextEditor.FindErrorByOffset(offset: Integer);   // I4083
begin
  ClearError;

  {TODO: if offset <= 0 then Exit;

  memo.SelStart := offset;
  memo.SelCol := 0;
  memo.ScrollInView;
  FErrorPar := memo.SelLine;

  UpdateParColour(FErrorPar, pcltError);}
end;

procedure TframeTextEditor.FireCommand(const commands: TStringList);
var
  i: Integer;
  command: string;
begin
  i := 0;
  while i < commands.Count do
  begin
    command := commands[i];
    if command = 'modified' then Changed   // I3948

    else if command = 'undo-disable' then FCanUndo := False
    else if command = 'undo-enable' then FCanUndo := True
    else if command = 'redo-disable' then FCanRedo := False
    else if command = 'redo-enable' then FCanRedo := True
    else if command = 'has-selection' then FHasSelection := True
    else if command = 'no-selection' then FHasSelection := False
    else if command.StartsWith('insert-mode,') then
    begin
      UpdateInsertState(command.Substring('insert-mode,'.Length));
    end
    else if command.StartsWith('location,') then
    begin
      UpdateState(command.Substring('location,'.Length));
    end
    else if command.StartsWith('token,') then
    begin
      UpdateToken(command.Substring('token,'.Length));
    end
    else ShowMessage('keyman:'+commands.Text);
    Inc(i);
  end;
end;

procedure TframeTextEditor.UpdateToken(command: string);
var
  n, col: Integer;
  line: string;
  x, tx: Integer;
  token, prevtoken: WideString;
  FHelpTopic, FPrevHelpTopic: WideString;
begin
  n := command.IndexOf(',');
  if n < 0 then
    Exit;
  if not TryStrToInt(command.Substring(0, n), col) then
    Exit;
  line := command.Substring(n+1);

  x := col+1;

  token := GetTokenAtCursor(line, x, tx, prevtoken);
  if (FHasSelection) and (token <> '') then
  begin
    prevtoken := line;
    if (x > tx) and CharInSet(token[1], ['"', '''']) then
      prevtoken := token[1] + prevtoken + token[1];

    if not TKeyboardParser_Line.GetXStr(prevtoken, token) then
      token := line;

    x := 1;
    tx := 1;
  end
  else
    token := GetTokenAtCursor(line, x, tx, prevtoken);

  UpdateCharacterMap(False, token, x, tx, FHasSelection);

  FHelpTopic := token;
  FPrevHelpTopic := prevtoken;

  if EditorFormat = efKMN then
  begin
    if not IsValidHelpToken(FHelpTopic, False) then
    begin
      if not IsValidHelpToken(FPrevHelpTopic, False)
        then FHelpTopic := ''
        else FHelpTopic := FPrevHelpTopic;
    end;

    if FHelpTopic <> '' then
    begin
      HelpKeyword := FHelpTopic;

      if Assigned(frmHelp) and frmHelp.Showing then
        frmHelp.QueueRefresh;
    end;
  end;
end;

procedure TframeTextEditor.UpdateParColour(par: Integer; LineType: TParColourLineType);
var
  j: TJSONObject;
begin
  if par < 0 then Exit;
  j := TJSONObject.Create;
  try
    j.AddPair('row', TJSONNumber.Create(par));
    if LineType <> pcltNone then
      j.AddPair('style', TJSONString.Create(GetEnumName(TypeInfo(TParColourLineType), Ord(LineType))));
    ExecuteCommand('setRowColor', j);
  finally
    j.Free;
  end;
end;


function TframeTextEditor.GetHelpTopic: string;
begin
  if FEditorFormat <> efKMN then
    Exit(SHelpTopic_Context_TextEditor);

  Result := HelpKeyword;
end;

procedure TframeTextEditor.TntFormDestroy(Sender: TObject);
begin
  inherited;
  if FFileName <> '' then
    modWebHttpServer.AppSource.UnregisterSource(FFileName);
end;

end.
