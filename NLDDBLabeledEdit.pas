//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//  NLDDBLabeledEdit - A data aware labeled edit control                    //
//                                                                          //
//  By NLDelphi.com members ®2006                                           //
//                                                                          //
//  Initiator: GeertVNieuw                                                  //
//  Last edit: Sept 24, 2006 by Albert de Weerd (NGLN)                      //
//  See also: http://www.nldelphi.com/Forum/showthread.php?t=14710          //
//            http://www.nldelphi.com/forum/forumdisplay.php?f=115          //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////

unit NLDDBLabeledEdit;

interface

uses
  DBCtrls, ExtCtrls, Controls, Classes, Messages;

const
  DefLabelSuffix = ':';

var
  EditLabelSuffix: String = DefLabelSuffix;

type
  TNLDDBLabeledEdit = class(TDBEdit)
  private
    FEditLabel: TBoundLabel;
    FLabelPosition: TLabelPosition;
    FLabelSpacing: Integer;
    FLabelSuffix: Boolean;
    procedure CMVisiblechanged(var Message: TMessage);
      message CM_VISIBLECHANGED;
    procedure CMEnabledchanged(var Message: TMessage);
      message CM_ENABLEDCHANGED;
    procedure CMBidimodechanged(var Message: TMessage);
      message CM_BIDIMODECHANGED;
    function GetDataField: string;
    function IsLabelSuffixStored: Boolean;
    procedure SetDataField(const Value: string);
    procedure SetLabelPosition(const Value: TLabelPosition);
    procedure SetLabelSpacing(const Value: Integer);
    procedure SetLabelSuffix(const Value: Boolean);
  protected
    function DefaultLabelCaption: Boolean; virtual;
    procedure Notification(AComponent: TComponent; Operation: TOperation);
      override;
    procedure SetName(const Value: TComponentName); override;
    procedure SetParent(AParent: TWinControl); override;
    procedure UpdateEditLabel(const UpdateCaption: Boolean); virtual;
  public
    constructor Create(AOwner: TComponent); override;
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
    procedure SetupEditLabel;
  published
    property DataField: string read GetDataField write SetDataField;
    property EditLabel: TBoundLabel read FEditLabel;
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
  Windows, SysUtils;

procedure Register;
begin
  RegisterComponents('NLDelphi', [TNLDDBLabeledEdit]);
end;

{ TNLDBoundLabel }

type
  TNLDBoundLabel = class(TBoundLabel)
  protected
    procedure AdjustBounds; override;
  end;

procedure TNLDBoundLabel.AdjustBounds;
begin
  inherited AdjustBounds;
  if Owner is TNLDDBLabeledEdit then
    TNLDDBLabeledEdit(Owner).UpdateEditLabel(False);
end;

{ TNLDDBLabeledEdit }

procedure TNLDDBLabeledEdit.CMBidimodechanged(var Message: TMessage);
begin
  inherited;
  FEditLabel.BiDiMode := BiDiMode;
end;

procedure TNLDDBLabeledEdit.CMEnabledchanged(var Message: TMessage);
begin
  inherited;
  FEditLabel.Enabled := Enabled;
end;

procedure TNLDDBLabeledEdit.CMVisiblechanged(var Message: TMessage);
begin
  inherited;
  FEditLabel.Visible := Visible;
end;

constructor TNLDDBLabeledEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FLabelPosition := lpLeft;
  FLabelSpacing := 3;
  FLabelSuffix := True;
  SetupEditLabel;
end;

function TNLDDBLabeledEdit.DefaultLabelCaption: Boolean;
begin
  if not Assigned(FEditLabel) then
    Result := False
  else
    Result := (FEditlabel.GetTextLen = 0)
           or ((DataField = '') and
               (CompareText(FEditLabel.Caption, Name) = 0))
           or (FLabelSuffix and
               (FEditLabel.Caption = DataField + EditLabelSuffix))
           or ((not FLabelSuffix) and (FEditLabel.Caption = DataField));
end;

function TNLDDBLabeledEdit.GetDataField: string;
begin
  Result := inherited DataField;
end;

function TNLDDBLabeledEdit.IsLabelSuffixStored: Boolean;
begin
  Result := FLabelSuffix and (FLabelPosition in [lpRight, lpBelow])
         or (not FLabelSuffix) and (FLabelPosition in [lpLeft, lpAbove]);
end;

procedure TNLDDBLabeledEdit.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (AComponent = FEditLabel) and (Operation = opRemove) then
    FEditLabel := nil;
end;

procedure TNLDDBLabeledEdit.SetBounds(ALeft, ATop, AWidth, AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
  UpdateEditLabel(False);
end;

procedure TNLDDBLabeledEdit.SetDataField(const Value: string);
var
  ChangeLabelCaption: Boolean;
begin
  ChangeLabelCaption := DefaultLabelCaption;
  inherited DataField := Value;
  if ChangeLabelCaption then
    UpdateEditLabel(True);
end;

procedure TNLDDBLabeledEdit.SetLabelPosition(const Value: TLabelPosition);
begin
  if FLabelPosition <> Value then
  begin
    FLabelPosition := Value;
    UpdateEditLabel(False);
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelSpacing(const Value: Integer);
begin
  if FLabelSpacing <> Value then
  begin
    FLabelSpacing := Value;
    UpdateEditLabel(False);
  end;
end;

procedure TNLDDBLabeledEdit.SetLabelSuffix(const Value: Boolean);
var
  ChangeLabelCaption: Boolean;
begin
  if FLabelSuffix <> Value then
  begin
    ChangeLabelCaption := DefaultLabelCaption;
    FLabelSuffix := Value;
    if ChangeLabelCaption then
      UpdateEditLabel(True);
  end;
end;

procedure TNLDDBLabeledEdit.SetName(const Value: TComponentName);
begin
  inherited SetName(Value);
  if csDesigning in ComponentState then
  begin
    if DefaultLabelCaption then
      UpdateEditLabel(True);
    Text := '';
  end;
end;

procedure TNLDDBLabeledEdit.SetParent(AParent: TWinControl);
begin
  inherited SetParent(AParent);
  if Assigned(FEditLabel) then
  begin
    FEditLabel.Parent := AParent;
    FEditLabel.Visible := True;
  end;
end;

procedure TNLDDBLabeledEdit.SetupEditLabel;
begin
  if not Assigned(FEditLabel) then
  begin
    FEditLabel := TNLDBoundLabel.Create(Self);
    FEditLabel.FreeNotification(Self);
    (FEditLabel as TNLDBoundLabel).FocusControl := Self;
  end;
end;

procedure TNLDDBLabeledEdit.UpdateEditLabel(const UpdateCaption: Boolean);
var
  P: TPoint;
begin
  if Assigned(FEditLabel) then
  begin
    if UpdateCaption then
    begin
      if DataField = '' then
        FEditLabel.Caption := Name
      else
        if FLabelSuffix then
          FEditLabel.Caption := DataField + EditLabelSuffix
        else
          FEditLabel.Caption := DataField;
    end;
    case FLabelPosition of
      lpAbove: P := Point(Left, Top - FEditLabel.Height - FLabelSpacing);
      lpBelow: P := Point(Left, Top + Height + FLabelSpacing);
      lpLeft : P := Point(Left - FEditLabel.Width - FLabelSpacing,
                      Top + ((Height - FEditLabel.Height) div 2));
      lpRight: P := Point(Left + Width + FLabelSpacing,
                      Top + ((Height - FEditLabel.Height) div 2));
    end;
    FEditLabel.SetBounds(P.X, P.Y, FEditLabel.Width, FEditLabel.Height);
  end;
end;

end.
