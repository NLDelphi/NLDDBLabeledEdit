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
{ Date: June 2, 2008                                                          }
{ Version: 2.0.0.1                                                            }
{                                                                             }
{ *************************************************************************** }

unit NLDDBLabeledEdit;

interface

uses
  Classes, DBCtrls, Messages, Controls, StdCtrls, ExtCtrls, DB;

type
  TNLDBoundLabel = class(TCustomLabel)
  protected
    procedure AdjustBounds; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BiDiMode;
    property Caption;
    property Color;
    property Font;
    property ParentBiDiMode;
    property ParentColor;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowAccelChar;
    property ShowHint;
    property Transparent;
    property Layout;
    property WordWrap;
    property OnClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDock;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnStartDock;
  end;

  TNLDDBLabeledEdit = class(TDBEdit)
  private
    FLabel: TNLDBoundLabel;
    FLabelPosition: TLabelPosition;
    FLabelSpacing: Integer;
    FLabelSuffix: Boolean;
    FGroupIndex: Integer;
    function GetDataField: string;
    function GetDefaultLabelCaption: String;
    function IsDefaultLabelCaption: Boolean;
    function IsLabelSuffixStored: Boolean;
    procedure SetDataField(const Value: string);
    procedure SetGroupIndex(const Value: Integer);
    procedure SetLabelPosition(const Value: TLabelPosition);
    procedure SetLabelSpacing(const Value: Integer);
    procedure SetLabelSuffix(const Value: Boolean);
    procedure UpdateLabel;
    procedure UpdateGroup;
    procedure CMVisiblechanged(var Message: TMessage);
      message CM_VISIBLECHANGED;
    procedure CMEnabledchanged(var Message: TMessage);
      message CM_ENABLEDCHANGED;
    procedure CMBidimodechanged(var Message: TMessage);
      message CM_BIDIMODECHANGED;
  protected
    procedure Loaded; override;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    procedure SetName(const Value: TComponentName); override;
    procedure SetParent(AParent: TWinControl); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft: Integer; ATop: Integer; AWidth: Integer;
      AHeight: Integer); override;
  published
    property DataField: string read GetDataField write SetDataField;
    property EditLabel: TNLDBoundLabel read FLabel;
    property GroupIndex: Integer read FGroupIndex write SetGroupIndex default 0;
    property LabelPosition: TLabelPosition read FLabelPosition
      write SetLabelPosition default lpLeft;
    property LabelSpacing: Integer read FLabelSpacing
      write SetLabelSpacing default 3;
    property LabelSuffix: Boolean read FLabelSuffix write SetLabelSuffix
      stored IsLabelSuffixStored;
  end;

procedure Register;

implementation

uses
  Windows;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDDBLabeledEdit]);
end;

{ TNLDBoundLabel }

procedure TNLDBoundLabel.AdjustBounds;
begin
  inherited AdjustBounds;
  if Owner is TNLDDBLabeledEdit then
    TNLDDBLabeledEdit(Owner).UpdateLabel;
end;

constructor TNLDBoundLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  if AOwner is TNLDDBLabeledEdit then
  begin
    Name := 'SubLabel';
    SetSubComponent(True);
  end;
end;

{ TNLDDBLabeledEdit }

procedure TNLDDBLabeledEdit.CMBidimodechanged(var Message: TMessage);
begin
  inherited;
  FLabel.BiDiMode := BiDiMode;
end;

procedure TNLDDBLabeledEdit.CMEnabledchanged(var Message: TMessage);
begin
  inherited;
  FLabel.Enabled := Enabled;
end;

procedure TNLDDBLabeledEdit.CMVisiblechanged(var Message: TMessage);
begin
  inherited;
  FLabel.Visible := Visible;
end;

constructor TNLDDBLabeledEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLabelPosition := lpLeft;
  FLabelSpacing := 3;
  FLabelSuffix := True;
  FLabel := TNLDBoundLabel.Create(Self);
  FLabel.FreeNotification(Self);
  FLabel.FocusControl := Self;
end;

function TNLDDBLabeledEdit.GetDataField: string;
begin
  Result := inherited DataField;
end;

function TNLDDBLabeledEdit.GetDefaultLabelCaption: String;
begin
  if (DataField = '') or (DataSource = nil) or (DataSource.DataSet = nil) then
    Result := Name
  else
    Result := DataSource.DataSet.FieldByName(DataField).DisplayLabel;
  if FLabelSuffix then
    Result := Result + ':'
end;

function TNLDDBLabeledEdit.IsDefaultLabelCaption: Boolean;
begin
  Result := (FLabel.Caption = GetDefaultLabelCaption) or
    (FLabel.Caption = FLabel.Name);
end;

function TNLDDBLabeledEdit.IsLabelSuffixStored: Boolean;
begin
  Result := (FLabelSuffix and (FLabelPosition in [lpRight, lpBelow])) or
    ((not FLabelSuffix) and (FLabelPosition in [lpLeft, lpAbove]));
end;

procedure TNLDDBLabeledEdit.Loaded;
var
  UpdateLabelCaption: Boolean;
begin
  UpdateLabelCaption := IsDefaultLabelCaption;
  inherited Loaded;
  if UpdateLabelCaption then
    FLabel.Caption := GetDefaultLabelCaption;
end;

procedure TNLDDBLabeledEdit.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FLabel) and (Operation = opRemove) then
    FLabel := nil;
end;

procedure TNLDDBLabeledEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  UpdateLabel;
end;

procedure TNLDDBLabeledEdit.SetDataField(const Value: string);
var
  UpdateLabelCaption: Boolean;
begin
  if DataField <> Value then
  begin
    UpdateLabelCaption := IsDefaultLabelCaption;
    inherited DataField := Value;
    if UpdateLabelCaption then
      FLabel.Caption := GetDefaultLabelCaption;
    try
      Name := Value;
    except
      on EComponentError do {eat exception};
    else
      Raise;
    end;
  end;
end;

procedure TNLDDBLabeledEdit.SetGroupIndex(const Value: Integer);
begin
  if FGroupIndex <> Value then
  begin
    FGroupIndex := Value;
    UpdateGroup;
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelPosition(const Value: TLabelPosition);
begin
  if FLabelPosition <> Value then
  begin
    FLabelPosition := Value;
    UpdateGroup;
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelSpacing(const Value: Integer);
begin
  if FLabelSpacing <> Value then
  begin
    FLabelSpacing := Value;
    UpdateGroup;
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelSuffix(const Value: Boolean);
var
  UpdateLabelCaption: Boolean;
begin
  if FLabelSuffix <> Value then
  begin
    UpdateLabelCaption := IsDefaultLabelCaption;
    FLabelSuffix := Value;
    if UpdateLabelCaption then
      FLabel.Caption := GetDefaultLabelCaption;
  end;
end;

procedure TNLDDBLabeledEdit.SetName(const Value: TComponentName);
var
  UpdateLabelCaption: Boolean;
begin
  if Name <> Value then
  begin
    UpdateLabelCaption := IsDefaultLabelCaption;
    inherited SetName(Value);
    if UpdateLabelCaption then
      FLabel.Caption := GetDefaultLabelCaption;
  end;
end;

procedure TNLDDBLabeledEdit.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if FLabel <> nil then
  begin
    FLabel.Parent := AParent;
    FLabel.Visible := True;
  end;
end;

procedure TNLDDBLabeledEdit.UpdateLabel;
var
  P: TPoint;
begin
  if FLabel <> nil then
  begin
    case FLabelPosition of
      lpAbove: P := Point(Left, Top - FLabel.Height - FLabelSpacing);
      lpBelow: P := Point(Left, Top + Height + FLabelSpacing);
      lpLeft : P := Point(Left - FLabel.Width - FLabelSpacing,
                      Top + ((Height - FLabel.Height) div 2));
      lpRight: P := Point(Left + Width + FLabelSpacing,
                      Top + ((Height - FLabel.Height) div 2));
    end;
    FLabel.SetBounds(P.X, P.Y, FLabel.Width, FLabel.Height);
  end;
end;

procedure TNLDDBLabeledEdit.UpdateGroup;
var
  i: Integer;
  NewLabelRelLeft: Integer;

  function GetEdit(IndexInOwnerComponents: Integer): TNLDDBLabeledEdit;
  begin
    Result := TNLDDBLabeledEdit(Owner.Components[IndexInOwnerComponents]);
  end;

begin
  UpdateLabel;
  if (FGroupIndex <> 0) and (Owner <> nil) and (FLabelPosition = lpLeft) then
  begin
    NewLabelRelLeft := FLabel.Width + FLabelSpacing;
    for i := 0 to Owner.ComponentCount - 1 do
      if (Owner.Components[i] is TNLDDBLabeledEdit) and
        (GetEdit(i).GroupIndex = FGroupIndex) and
        (GetEdit(i).LabelPosition = lpLeft) and (GetEdit(i) <> Self) then
      begin
        GetEdit(i).FLabelSpacing := NewLabelRelLeft - GetEdit(i).FLabel.Width;
        GetEdit(i).UpdateLabel;
      end;
  end;
end;

end.

