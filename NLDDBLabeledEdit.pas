{ *************************************************************************** }
{                                                                             }
{ NLDLabeledEdit  -  www.nldelphi.com Open Source designtime component        }
{                                                                             }
{ Initiator: GeertVNieuw                                                      }
{            See http://www.nldelphi.com/Forum/showthread.php?t=14710         )
{ License: Free to use, free to modify                                        }
{ Website: http://www.nldelphi.com/forum/forumdisplay.php?f=115               }
{ SVN path: http://svn.nldelphi.com/nldelphi/opensource/ngln/NLDDBLabeledEdit }
{                                                                             }
{ *************************************************************************** }
{                                                                             }
{ Edit by: Albert de Weerd (aka NGLN)                                         }
{ Date: September 12, 2010                                                    }
{ Version: 2.0.0.2                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDDBLabeledEdit;

interface

uses
  Classes, Messages, Controls, SysUtils, Windows, Graphics, StdCtrls, DBCtrls,
  DB, ToolsAPI, Math, StrUtils;

type
  TNLDSubLabel = class(TCustomLabel)
  private
    function GetGroupIndex: Integer;
    procedure SetGroupIndex(Value: Integer);
    procedure UnGroup(OldGroupIndex: Integer);
    procedure CMDesignHitTest(var Message: TCMDesignHitTest);
      message CM_DESIGNHITTEST;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    procedure Click; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Update; reintroduce;
    property GroupIndex: Integer read GetGroupIndex write SetGroupIndex;
  public
    property Font;
    property ParentFont;
  end;

  TNLDDBLabeledEdit = class(TDBEdit)
  private
    function DefaultLabelCaption: String;
    function GetDataField: String;
    function GetDataSource: TDataSource;
    function GetLabelCaption: String;
    function GetLabelFont: TFont;
    function GetLabelGroupIndex: Integer;
    function IsLabelCaptionStored: Boolean;
    function IsLabelFontStored: Boolean;
    procedure SetDataField(const Value: String);
    procedure SetDataSource(Value: TDataSource);
    procedure SetLabelCaption(const Value: String);
    procedure SetLabelFont(Value: TFont);
    procedure SetLabelGroupIndex(Value: Integer);
    function SubLabel: TNLDSubLabel;
  protected
    procedure Loaded; override;
    procedure SetName(const NewName: TComponentName); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure WndProc(var Message: TMessage); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  published
    property DataField: String read GetDataField write SetDataField;
    property DataSource: TDataSource read GetDataSource write SetDataSource;
    property LabelCaption: String read GetLabelCaption write SetLabelCaption
      stored IsLabelCaptionStored;
    property LabelFont: TFont read GetLabelFont write SetLabelFont
      stored IsLabelFontStored;
    property LabelGroupIndex: Integer read GetLabelGroupIndex
      write SetLabelGroupIndex default 0;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDDBLabeledEdit]);
end;

type
  TWinControlAccess = class(TWinControl);

function GetActiveFormEditor: IOTAFormEditor;
var
  ModuleServices: IOTAModuleServices;
  Module: IOTAModule;
  Editor: IOTAEditor;
begin
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  Module := ModuleServices.CurrentModule;
  Editor := Module.CurrentEditor;
  Result := Editor as IOTAFormEditor;
end;

function SameFont(Font1, Font2: TFont): Boolean;
begin
  Result := (Font1.Handle = Font2.Handle) and (Font1.Color = Font2.Color);
end;

{ TNLDSubLabel }

const
  SEditNameSuffix = 'Edit';
  SHiddenSpace = '(space)';
  SInvalidSubLabelOwner = 'Owner of SubLabel must be of type TWinControl.';
  SSubLabelCaptionSuffix = ':';

function FindLabel(Parent: TWinControl; ControlIndex: Integer;
  out Lbl: TNLDSubLabel): Boolean;
begin
  if Parent.Controls[ControlIndex] is TNLDSubLabel then
    Lbl := TNLDSubLabel(Parent.Controls[ControlIndex])
  else
    Lbl := nil;
  Result := Lbl <> nil;
end;

procedure TNLDSubLabel.Click;
var
  FocusControl: IOTAComponent;
begin
  if not (csDesigning in ComponentState) then
    TWinControl(Owner).SetFocus
  else
  begin
    FocusControl := GetActiveFormEditor.FindComponent(Owner.Name);
    if FocusControl <> nil then
      FocusControl.Select(False);
  end;
  inherited Click;
end;

procedure TNLDSubLabel.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  inherited;
  Message.Result := HTCLIENT;
end;

procedure TNLDSubLabel.CMFontChanged(var Message: TMessage);
var
  F: TFont;
begin
  inherited;
  if HasParent and (not ParentFont) and (Font.Color = clDefault) then
  begin
    F := TFont.Create;
    try
      F.Assign(Font);
      F.Color := TWinControlAccess(Parent).Font.Color;
      if SameFont(F, TWinControlAccess(Parent).Font) then
        ParentFont := True;
    finally
      F.Free;
    end;
  end;
end;

procedure TNLDSubLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Update;
end;

constructor TNLDSubLabel.Create(AOwner: TComponent);
begin
  if not (AOwner is TWinControl) then
    raise EComponentError.Create(SInvalidSubLabelOwner);
  inherited Create(AOwner);
  AutoSize := True;
  ControlStyle := [csClickEvents, csSetCaption, csOpaque, csParentBackground,
    csDoubleClicks];
  FocusControl := TWinControl(Owner);
  Transparent := True;
end;

function TNLDSubLabel.GetGroupIndex: Integer;
begin
  Result := Tag;
end;

procedure TNLDSubLabel.SetGroupIndex(Value: Integer);
var
  OldGroupIndex: Integer;
begin
  if GroupIndex <> Value then
  begin
    if GroupIndex <> 0 then
    begin
      OldGroupIndex := GroupIndex;
      Tag := Value;
      Ungroup(OldGroupIndex);
    end
    else
    begin
      Tag := Value;
      Update;
    end;
  end;
end;

procedure TNLDSubLabel.UnGroup(OldGroupIndex: Integer);
var
  i: Integer;
  Lbl: TNLDSubLabel;
begin
  AdjustBounds;
  Update;
  if Parent <> nil then
  begin
    for i := 0 to Parent.ControlCount - 1 do
      if FindLabel(Parent, i, Lbl) then
        if Lbl.GroupIndex = OldGroupIndex then
          Lbl.AdjustBounds;
    for i := 0 to Parent.ControlCount - 1 do
      if FindLabel(Parent, i, Lbl) then
        if Lbl.GroupIndex = OldGroupIndex then
        begin
          Lbl.Update;
          Break;
        end;
  end;
end;

procedure TNLDSubLabel.Update;
var
  i: Integer;
  Lbl: TNLDSubLabel;
  NewWidth: Integer;
begin
  Parent := TControl(Owner).Parent;
  Enabled := TControl(Owner).Enabled;
  Visible := TControl(Owner).Visible;
  NewWidth := 0;
  if Parent <> nil then
  begin
    if GroupIndex = 0 then
      with TControl(Owner) do
        Self.SetBounds(Left - Self.Width - 3, Top + 3, Self.Width, Height)
    else
    begin
      for i := 0 to Parent.ControlCount - 1 do
        if FindLabel(Parent, i, Lbl) then
          if (Lbl.GroupIndex <> 0) and (Lbl.GroupIndex = GroupIndex) then
          begin
            Lbl.AdjustBounds;
            NewWidth := Max(NewWidth, Lbl.Width);
          end;
      for i := 0 to Parent.ControlCount - 1 do
        if FindLabel(Parent, i, Lbl) then
          if (Lbl.GroupIndex <> 0) and (Lbl.GroupIndex = GroupIndex) then
            with TControl(Lbl.Owner) do
              Lbl.SetBounds(Left - NewWidth - 3, Top + 3, NewWidth, Height);
    end;
  end;
end;

{ TNLDDBLabeledEdit }

constructor TNLDDBLabeledEdit.Create(AOwner: TComponent);
begin
  TNLDSubLabel.Create(Self);
  inherited Create(AOwner);
end;

function TNLDDBLabeledEdit.DefaultLabelCaption: String;
var
  F: TField;
begin
  if (DataField = '') or (DataSource = nil) or (DataSource.DataSet = nil) then
    F := nil
  else
    F := DataSource.DataSet.FindField(DataField);
  if F <> nil then
    Result := F.DisplayLabel
  else if RightStr(Name, Length(SEditNameSuffix)) = SEditNameSuffix then
    Result := Copy(Name, 1, Length(Name) - Length(SEditNameSuffix))
  else
    Result := Name;
  if Trim(Result) <> '' then
    Result := Result + SSubLabelCaptionSuffix;
end;

function TNLDDBLabeledEdit.GetDataField: String;
begin
  Result := inherited DataField;
end;

function TNLDDBLabeledEdit.GetDataSource: TDataSource;
begin
  Result := inherited DataSource;
end;

function TNLDDBLabeledEdit.GetLabelCaption: String;
begin
  Result := SubLabel.Caption;
  if (Result = ' ') and (csDesigning in ComponentState) then
    Result := SHiddenSpace;
end;

function TNLDDBLabeledEdit.GetLabelFont: TFont;
begin
  Result := SubLabel.Font;
end;

function TNLDDBLabeledEdit.GetLabelGroupIndex: Integer;
begin
  Result := SubLabel.GroupIndex ;
end;

function TNLDDBLabeledEdit.IsLabelCaptionStored: Boolean;
begin
  Result := LabelCaption <> DefaultLabelCaption;
end;

function TNLDDBLabeledEdit.IsLabelFontStored: Boolean;
begin
  Result := not SubLabel.ParentFont;
end;

procedure TNLDDBLabeledEdit.Loaded;
begin
  inherited Loaded;
  if LabelCaption = '' then
    LabelCaption := DefaultLabelCaption;
end;

procedure TNLDDBLabeledEdit.SetBounds(ALeft, ATop, AWidth,
  AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  SubLabel.Update;
end;

procedure TNLDDBLabeledEdit.SetDataField(const Value: String);
var
  SyncCaption: Boolean;
  NewName: String;
begin
  if DataField <> Value then
  begin
    SyncCaption := not (csLoading in ComponentState) and
      (LabelCaption = DefaultLabelCaption);
    inherited DataField := Value;
    if SyncCaption then
      LabelCaption := DefaultLabelCaption;
    if csDesigning in ComponentState then
    begin
      NewName := DataField + SEditNameSuffix;
      if IsValidIdent(NewName) and not SameText(Name, NewName) and
        (Owner <> nil) and (Owner.FindComponent(NewName) = nil) then
      try
        Name := NewName;
      except
        { Eat exception }
      end;
    end;
  end;
end;

procedure TNLDDBLabeledEdit.SetDataSource(Value: TDataSource);
var
  SyncCaption: Boolean;
begin
  if DataSource <> Value then
  begin
    SyncCaption := not (csLoading in ComponentState) and
      (LabelCaption = DefaultLabelCaption);
    inherited DataSource := Value;
    if SyncCaption then
      LabelCaption := DefaultLabelCaption;
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelCaption(const Value: String);
begin
  if LabelCaption <> Value then
  begin
    if Value = SHiddenSpace then
      SubLabel.Caption := ' '
    else if Value = '' then
      SubLabel.Caption := DefaultLabelCaption
    else
      SubLabel.Caption := Value;
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelFont(Value: TFont);
begin
  SubLabel.Font.Assign(Value);
end;

procedure TNLDDBLabeledEdit.SetLabelGroupIndex(Value: Integer);
begin
  SubLabel.GroupIndex := Value;
end;

procedure TNLDDBLabeledEdit.SetName(const NewName: TComponentName);
var
  SyncCaption: Boolean;
begin
  if Name <> NewName then
  begin
    SyncCaption := not (csLoading in ComponentState) and
      (LabelCaption = DefaultLabelCaption);
    inherited SetName(NewName);
    if SyncCaption then
      LabelCaption := DefaultLabelCaption;
  end;
end;

procedure TNLDDBLabeledEdit.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  SubLabel.Update;
end;

function TNLDDBLabeledEdit.SubLabel: TNLDSubLabel;
begin
  Result := TNLDSubLabel(Components[0]);
end;

procedure TNLDDBLabeledEdit.WndProc(var Message: TMessage);
begin
  case Message.Msg of
    CM_ENABLEDCHANGED,
    CM_VISIBLECHANGED,
    WM_WINDOWPOSCHANGED:
      SubLabel.Update;
  end;
  inherited WndProc(Message);
end;

end.

