unit MainU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Forms, Vcl.ComCtrls, Vcl.ActnList, Vcl.StdActns, Vcl.Controls, Vcl.StdCtrls,
  Xml.xmldom, Xml.XMLIntf, Xml.Win.msxmldom, Xml.XMLDoc, JvFormPlacement,
  JvComponentBase, JvAppStorage, JvAppIniStorage, Vcl.Mask, CAStdCtrls,
  CAVerInfo;

type
  TVersionUpdateFlags = (vuBase, vuRelease, vuIncBuild, vuSetCopyright);

  TVersionUpdateInfo = record
    Version: TVersion;
    Copyright: string;
    Flags: set of TVersionUpdateFlags;
  end;

  TProcessResult = (prNotEdited, prEdited, prError);

  TfrmMain = class(TForm)
    ActionList1: TActionList;
    actnAddProjects: TFileOpen;
    actnExecute: TAction;
    actnRemoveProjects: TAction;
    btnAddProjects: TButton;
    btnExecute: TButton;
    btnRemoveProjects: TButton;
    cbIncVersionBuild: TCheckBox;
    cbSetVersionBase: TCheckBox;
    cbSetVersionRelease: TCheckBox;
    edtVerMain: TCANumEdit;
    edtVerRelease: TCANumEdit;
    edtVerSub: TCANumEdit;
    gbVersionInfo: TGroupBox;
    JvAppIniFileStorage1: TJvAppIniFileStorage;
    JvFormStorage1: TJvFormStorage;
    lblProjectCount: TLabel;
    lvProjects: TListView;
    ProgressBar1: TProgressBar;
    XMLDocument1: TXMLDocument;
    cbSetCopyright: TCheckBox;
    edtCopyright: TEdit;
    cbSelectedOnly: TCheckBox;
    procedure actnAddProjectsAccept(Sender: TObject);
    procedure actnExecuteExecute(Sender: TObject);
    procedure actnExecuteUpdate(Sender: TObject);
    procedure actnRemoveProjectsExecute(Sender: TObject);
    procedure actnRemoveProjectsUpdate(Sender: TObject);
    procedure cbSelectedOnlyClick(Sender: TObject);
    procedure edtCopyrightChange(Sender: TObject);
    procedure edtVerBaseChange(Sender: TObject);
    procedure edtVerReleaseChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JvFormStorage1RestorePlacement(Sender: TObject);
    procedure JvFormStorage1SavePlacement(Sender: TObject);
    procedure lvProjectsChange(Sender: TObject; Item: TListItem; Change:
        TItemChange);
    procedure lvProjectsCustomDrawItem(Sender: TCustomListView; Item: TListItem;
        State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure WMDropFiles(var Message: TWMDropFiles); message WM_DROPFILES;
  private
    FBasePath: string;
    FUpdatingVersionControls: Boolean;
    procedure AddFile(const aFilename: string);
    procedure AddGroupProjects(const aFilename: string);
    procedure AddProject(const aFilename: string);
    procedure FormatProject(const aFilename: string);
    function GetFullFilename(const aFilename: string): string;
    function GetShortPath(const aFilename: string): string;
    function GetVerUpdateInfo: TVersionUpdateInfo;
    function OpenProject(const aFilename: string; out aBaseConfigNode: IXMLNode):
        Boolean;
    function ProcessProject(const aFilename: string; const aVerUpdatInfo:
        TVersionUpdateInfo): TProcessResult;
    procedure ProjectCountUpdated;
  protected
    function CreateVerInfoKeyList(aNode: IXMLNode): TStrings;
    procedure ListItemsDeleteItem(Sender: TJvCustomAppStorage; const Path: string;
        const List: TObject; const First, Last: Integer; const ItemName: string);
    procedure ListItemsReadItem(Sender: TJvCustomAppStorage; const Path: string;
        const List: TObject; const Index: Integer; const ItemName: string);
    procedure ListItemsWriteItem(Sender: TJvCustomAppStorage; const Path: string;
        const List: TObject; const Index: Integer; const ItemName: string);
  end;

var
  frmMain: TfrmMain;

implementation

uses
  Dialogs, ShellApi, System.UITypes;

{$R *.dfm}

procedure TfrmMain.actnAddProjectsAccept(Sender: TObject);
var
  s: string;
begin
  with (Sender as TFileOpen).Dialog do
    for S in Files do AddFile(S);
  ProjectCountUpdated;
end;

procedure TfrmMain.actnExecuteExecute(Sender: TObject);
var
  _Info: TVersionUpdateInfo;
  I: Integer;
begin
  _Info := GetVerUpdateInfo;
  ProgressBar1.Position := 0;
  ProgressBar1.Max := lvProjects.Items.Count;
  for I := 0 to lvProjects.Items.Count - 1 do
  begin
    lvProjects.Items[I].SubItems.Clear;
    if (not lvProjects.Checkboxes) or lvProjects.Items[I].Checked then
      case ProcessProject(lvProjects.Items[I].Caption, _Info) of
        prEdited: lvProjects.Items[I].SubItems.Add('*');
        prError : lvProjects.Items[I].SubItems.Add('!');
      end;
    ProgressBar1.StepBy(1);
  end;
  lvProjects.Invalidate;
end;

procedure TfrmMain.actnExecuteUpdate(Sender: TObject);
begin
  (Sender as TCustomAction).Enabled := lvProjects.Items.Count > 0;
end;

procedure TfrmMain.actnRemoveProjectsExecute(Sender: TObject);
begin
  lvProjects.DeleteSelected;
  ProjectCountUpdated;
end;

procedure TfrmMain.actnRemoveProjectsUpdate(Sender: TObject);
begin
  (Sender as TCustomAction).Enabled := lvProjects.SelCount > 0;
end;

procedure TfrmMain.AddFile(const aFilename: string);
begin
  if SameText(ExtractFileExt(aFilename), '.dproj') then
    AddProject(aFilename)
  else if SameText(ExtractFileExt(aFilename), '.groupproj') then
    AddGroupProjects(aFilename);
end;

procedure TfrmMain.AddGroupProjects(const aFilename: string);
var
  xmlGroup: IXMLDocument;
  xmlNode: IXMLNode;
  I: Integer;
begin
  xmlGroup := LoadXMLDocument(aFilename);
  xmlNode := xmlGroup.ChildNodes.FindNode('Project');
  if xmlNode = nil then Exit;
  xmlNode := xmlNode.ChildNodes.FindNode('ItemGroup');
  if xmlNode = nil then Exit;

  for I := 0 to xmlNode.ChildNodes.Count - 1 do
    if xmlNode.ChildNodes[I].NodeName = 'Projects' then
      AddProject(ExtractFilePath(aFilename) + VarTosTr(xmlNode.ChildNodes[I].Attributes['Include']));
end;

procedure TfrmMain.AddProject(const aFilename: string);
begin
  if FileExists(aFilename) and
     (lvProjects.FindCaption(0, aFilename, False, True, False) = nil) then
    lvProjects.Items.Add.Caption := aFilename;
end;

procedure TfrmMain.cbSelectedOnlyClick(Sender: TObject);
begin
  lvProjects.Checkboxes := (Sender as TCheckBox).Checked;
end;

function TfrmMain.CreateVerInfoKeyList(aNode: IXMLNode): TStrings;
begin
  Result := TStringList.Create;
  try
    Result.StrictDelimiter := True;
    Result.Delimiter := ';';
    if Assigned(aNode) then
      Result.DelimitedText := aNode.Text;
  except
    Result.Free;
    raise;
  end;
end;

procedure TfrmMain.edtCopyrightChange(Sender: TObject);
begin
  if FUpdatingVersionControls then Exit;
  cbSetCopyright.Checked := True;
end;

procedure TfrmMain.edtVerBaseChange(Sender: TObject);
begin
  if FUpdatingVersionControls then Exit;
  cbSetVersionBase.Checked := True;
end;

procedure TfrmMain.edtVerReleaseChange(Sender: TObject);
begin
  if FUpdatingVersionControls then Exit;
  cbSetVersionRelease.Checked := True;
end;

procedure TfrmMain.FormatProject(const aFilename: string);
const
  sBadProjectLinePrefix = '<Project ';
  sBadPropertyGroupCloseTag = #9'</PropertyGroup>';
var
  I: Integer;
  _FileStrings: TStrings;
begin
  _FileStrings := TStringList.Create;
  try
    _FileStrings.LoadFromFile(aFilename);

    for I := 0 to _FileStrings.Count - 1 do
    begin
      if Copy(_FileStrings[I], 1, Length(sBadProjectLinePrefix)) = sBadProjectLinePrefix then
        _FileStrings[I] := #9 + _FileStrings[I] // Extra tab toevoegen voor elke regel
      else if _FileStrings[I] = sBadPropertyGroupCloseTag then
        _FileStrings[I] := #9 + _FileStrings[I] // Extra tab toevoegen voor elke regel
    end;
    _FileStrings.SaveToFile(aFilename);
  finally
    _FileStrings.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  DragAcceptFiles(Handle, True);
  JvAppIniFileStorage1.FileName := ChangeFileExt(Application.ExeName, '.ini');
  // Basismap is op dit moment de map van de applicatie
  FBasePath := ExcludeTrailingPathDelimiter(ExtractFilePath(Application.ExeName));
end;

function TfrmMain.GetFullFilename(const aFilename: string): string;
begin
  if Copy(aFilename, 1, 2) = '.\' then
    Result := FBasePath + Copy(aFilename, 2, Length(aFilename))
  else
    Result := aFilename;
end;

function TfrmMain.GetShortPath(const aFilename: string): string;
begin
  // Haal de huidige locatie van de applicatie uit het path, mits
  // dat er in opgenomen!
  if SameText(Copy(aFilename, 1, Length(FBasePath)), FBasePath) then
    Result := '.' + Copy(aFileName, Length(FBasePath) + 1, Length(aFilename))
  else
    Result := aFilename;
end;

function TfrmMain.GetVerUpdateInfo: TVersionUpdateInfo;
begin
  FillChar(Result, SizeOf(Result), 0);
  // Base version
  if cbSetVersionBase.Checked then
  begin
    Include(Result.Flags, vuBase);
    if edtVerMain.Text = '' then
    begin
      edtVerMain.SetFocus;
      raise Exception.Create('Major version not specified');
    end;
    Result.Version.Main := edtVerMain.AsInteger;
    if edtVerSub.Text = '' then
    begin
      edtVerSub.SetFocus;
      raise Exception.Create('Minor version not specified');
    end;
    Result.Version.Sub := edtVerSub.AsInteger;
  end;
  // Release
  if cbSetVersionRelease.Checked then
  begin
    Include(Result.Flags, vuRelease);
    if edtVerRelease.Text = '' then
    begin
      edtVerRelease.SetFocus;
      raise Exception.Create('Release not specified');
    end;
    Result.Version.Release := edtVerRelease.AsInteger;
  end;
  // Build
  if cbIncVersionBuild.Checked then
  begin
    Include(Result.Flags, vuIncBuild);
  end;
  // Copyright
  if cbSetCopyright.Checked then
  begin
    Include(Result.Flags, vuSetCopyright);
    Result.Copyright := edtCopyright.Text;
  end;



  if Result.Flags = [] then
    raise Exception.Create('No version option set');
end;

procedure TfrmMain.JvFormStorage1RestorePlacement(Sender: TObject);
var
  FormStore: TJvFormStorage;
  sPath: String;
begin
  FormStore := (Sender as TJvFormStorage);
  sPath := FormStore.AppStorage.ConcatPaths([FormStore.AppStoragePath, FormStore.StoredPropsPath, 'LastItems']);

  lvProjects.Items.BeginUpdate;
  try
    FormStore.AppStorage.ReadList(sPath, lvProjects.Items, ListItemsReadItem);
  finally
    lvProjects.Items.EndUpdate;
  end;
  ProjectCountUpdated;
end;

procedure TfrmMain.JvFormStorage1SavePlacement(Sender: TObject);
var
  FormStore: TJvFormStorage;
  sPath: String;
begin
  FormStore := (Sender as TJvFormStorage);
  sPath := FormStore.AppStorage.ConcatPaths([FormStore.AppStoragePath, FormStore.StoredPropsPath, 'LastItems']);
  FormStore.AppStorage.WriteList(sPath, lvProjects.Items, lvProjects.Items.Count, ListItemsWriteItem, ListItemsDeleteItem);
end;

procedure TfrmMain.ListItemsDeleteItem(Sender: TJvCustomAppStorage; const Path:
    string; const List: TObject; const First, Last: Integer; const ItemName:
    string);
var
  I: Integer;
begin
  if List is TListItems then
    for I := First to Last do
      Sender.DeleteValue(Sender.ConcatPaths([Path, ItemName + IntToStr(I)]));
end;

procedure TfrmMain.ListItemsReadItem(Sender: TJvCustomAppStorage; const Path:
    string; const List: TObject; const Index: Integer; const ItemName: string);
var
  NewItem: TListItem;
  NewPath, sFileName: String;
begin
  if List is TListItems then
  begin
    NewPath := Sender.ConcatPaths([Path, Sender.ItemNameIndexPath (ItemName, Index)]);
    sFileName := GetFullFilename(Sender.ReadString(NewPath));
    NewItem := TListItems(List).Add;
    NewItem.Caption := sFilename;
    if not FileExists(sFilename) then
      NewItem.SubItems.Add('!');
    // Sender.ReadPersistent(NewPath, NewItem);
  end;
end;

procedure TfrmMain.ListItemsWriteItem(Sender: TJvCustomAppStorage; const Path:
    string; const List: TObject; const Index: Integer; const ItemName: string);
var
  Item: TListItem;
begin
  if List is TListItems then
  begin
    Item := TListItems(List).Item[Index];
    if Assigned(Item) then
      Sender.WriteString(Sender.ConcatPaths([Path, Sender.ItemNameIndexPath (ItemName, Index)]), GetShortPath(Item.Caption));
      // Sender.WritePersistent(Sender.ConcatPaths([Path, Sender.ItemNameIndexPath (ItemName, Index)]), TPersistent(Item));
  end;
end;

procedure TfrmMain.lvProjectsChange(Sender: TObject; Item: TListItem; Change:
    TItemChange);
var
  _BaseConfigNode, _CurSubNode: IXMLNode;

  function GetVerInfoKey(const aKeyName: string): string;
  var
    _VerKeys: TStrings;
  begin
    _VerKeys := CreateVerInfoKeyList(_BaseConfigNode.ChildNodes['VerInfo_Keys']);
    try
      Result := _VerKeys.Values[aKeyName];
    finally
      _VerKeys.Free;
    end;
  end;

  procedure UpdateEditValue(aEdit: TCustomEdit; aNode: IXMLNode);
  begin
    if Assigned(aNode) and (aNode.Text <> '') then
      aEdit.Text := aNode.Text;
  end;

begin
  // Clone version info to edits?
  if OpenProject(Item.Caption, _BaseConfigNode) then
  try
    FUpdatingVersionControls := True;
    UpdateEditValue(edtVerMain, _BaseConfigNode.ChildNodes.FindNode('VerInfo_MajorVer'));
    UpdateEditValue(edtVerSub, _BaseConfigNode.ChildNodes.FindNode('VerInfo_MinorVer'));
    UpdateEditValue(edtVerRelease, _BaseConfigNode.ChildNodes.FindNode('VerInfo_Release'));
    edtCopyright.Text := GetVerInfoKey('LegalCopyright');
  finally
    FUpdatingVersionControls := False;
    XMLDocument1.Active := False; // Close
  end;
end;

procedure TfrmMain.lvProjectsCustomDrawItem(Sender: TCustomListView; Item:
    TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  if not FileExists(Item.Caption) then
    Sender.Canvas.Font.Color := TColors.Grey
  else
    Sender.Canvas.Font.Color := TColors.SysWindowText; // Sender.Font.Color;
end;

function TfrmMain.OpenProject(const aFilename: string; out aBaseConfigNode:
    IXMLNode): Boolean;
var
  I: Integer;
  _Root, _PropertyNode, _CurSubNode: IXMLNode;
begin
  Result := False;
  try
    XMLDocument1.LoadFromFile(aFilename);
  except
    Exit;
  end;

  try
    _Root := XMLDocument1.DocumentElement;
    if _Root.NodeName <> 'Project' then Exit;

    // Loop thru PropertyGroups
    for I := 0 to _Root.ChildNodes.Count - 1 do
    begin
      _PropertyNode := _Root.ChildNodes[I];
      // Find base build configuration
      if (_PropertyNode.NodeName = 'PropertyGroup') and
         SameText(VarToStr(_PropertyNode.Attributes['Condition']), '''$(Base)''!=''''') then
      begin
        _CurSubNode := _PropertyNode.ChildNodes.FindNode('VerInfo_IncludeVerInfo');
        if Assigned(_CurSubNode) and (_CurSubNode.Text = 'true') then
        begin
          aBaseConfigNode := _PropertyNode;
          Result := True;
        end;
        // Found base config node
        Break;
      end;
    end;
  finally
    if not Result then
      XMLDocument1.Active := False; // Close
  end;
end;

function TfrmMain.ProcessProject(const aFilename: string; const aVerUpdatInfo:
    TVersionUpdateInfo): TProcessResult;

  procedure UpdateNodeValue(aNode: IXMLNode; aValue: Variant);
  begin
    if not VarSameValue(aNode.NodeValue, aValue) then
    begin
      aNode.NodeValue := aValue;
      Result := prEdited; // ProcessProject
    end;
  end;

var
  _BaseConfigNode, _CurSubNode: IXMLNode;
  _VerKeys: TStrings;
  _ver: TVersion;
begin
  // Open file
  Result := prNotEdited;
  if not OpenProject(aFilename, _BaseConfigNode) then
    Exit(prError);

  try
    _VerKeys := CreateVerInfoKeyList(_BaseConfigNode.ChildNodes['VerInfo_Keys']);
    try
      // Version number checks

      _ver := StringToVersion(_VerKeys.Values['FileVersion']);

      if vuBase in aVerUpdatInfo.Flags then
      begin
        UpdateNodeValue(_BaseConfigNode.ChildNodes['VerInfo_MajorVer'], aVerUpdatInfo.Version.Main);
        UpdateNodeValue(_BaseConfigNode.ChildNodes['VerInfo_MinorVer'], aVerUpdatInfo.Version.Sub);
        _ver.Main := aVerUpdatInfo.Version.Main;
        _ver.Sub := aVerUpdatInfo.Version.Sub;
      end;

      if vuRelease in aVerUpdatInfo.Flags then
      begin
        UpdateNodeValue(_BaseConfigNode.ChildNodes['VerInfo_Release'], aVerUpdatInfo.Version.Release);
        _ver.Release := aVerUpdatInfo.Version.Release;
      end;

      if vuIncBuild in aVerUpdatInfo.Flags then
      begin
        _CurSubNode := _BaseConfigNode.ChildNodes['VerInfo_Build'];
        if VarIsEmpty(_CurSubNode.NodeValue) or VarIsNull(_CurSubNode) then
          _CurSubNode.NodeValue := 1
        else
          _CurSubNode.NodeValue := _CurSubNode.NodeValue + 1;
        Result := prEdited;
        _ver.Build := _CurSubNode.NodeValue;
      end;

      if Result = prEdited then
      begin
        _VerKeys.Values['FileVersion'] := VersionToString(_ver);
        if vuBase in aVerUpdatInfo.Flags then
          _VerKeys.Values['ProductVersion'] := Format('%d.%d', [_ver.Main, _ver.Sub]);
      end;

      // Copyright update?

      if (vuSetCopyright in aVerUpdatInfo.Flags) and
         (_VerKeys.Values['LegalCopyright'] <> aVerUpdatInfo.Copyright) then
      begin
        _VerKeys.Values['LegalCopyright'] := aVerUpdatInfo.Copyright;
        Result := prEdited;
      end;

      // Update version info key (when data has changed)
      if Result = prEdited then
        _BaseConfigNode.ChildNodes['VerInfo_Keys'].Text := _VerKeys.DelimitedText;
    finally
      _VerKeys.Free;
    end;

    // Are there modifications?
    if Result = prEdited then
    begin
      // If file is readonly, ask to overwrite it and remove readonly attribute...
      if (FileGetAttr(aFilename, False) and faReadOnly) <> 0 then
      begin
        if Application.MessageBox(PChar(Format('Overwrite readonly file "%s"', [ExtractFileName(aFilename)])), 'Confirm', MB_ICONQUESTION or MB_YESNO) = ID_YES then
          FileSetAttr(aFilename, FileGetAttr(aFilename, False) - faReadOnly, False)
        else
          Exit(prNotEdited); // Exit
      end;

      // Create backup?
//      if (coCreateBackup in aCleanupOptions) and not CopyFile(PChar(aFilename), PChar(aFilename + '.bak'), False) then
//          raise Exception.Create('Cannot create backup!');

      // Save log
//      if (coCreateLog in aCleanupOptions) then
//        _Log.SaveToFile(aFilename + '.log');

      // Save file again
      XMLDocument1.SaveToFile();
    end;
  finally
    XMLDocument1.Active := False; // Close
  end;

  // Even format van Delphi hanteren (extra tab voor elke regel)
  if Result = prEdited then
    FormatProject(aFilename);
end;

procedure TfrmMain.ProjectCountUpdated;
begin
  lblProjectCount.Caption := Format('Number of  projects: %d', [lvProjects.Items.Count]);
  // Resize forceren
  lvProjects.Width := lvProjects.Width + 1;
  lvProjects.Width := lvProjects.Width - 1;
end;

procedure TfrmMain.WMDropFiles(var Message: TWMDropFiles);
var
  num: integer;
  aFileName: array[0..MAX_PATH] of char;
  i: Integer;
begin
  num := DragQueryFile(Message.Drop, $FFFFFFFF, aFileName, 0);
  if num < 1 then Exit;

  for i:=0 to num-1 do
  begin
    DragQueryFile(Message.Drop, i, aFileName, MAX_PATH-1);
    AddFile(aFileName);
  end;
  DragFinish(Message.Drop);
  ProjectCountUpdated;
end;

end.
