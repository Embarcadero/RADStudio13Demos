unit KeyboardMouseEvents.Main;

interface

procedure Register;

implementation

uses
  System.Types, System.SysUtils, System.Classes, Winapi.Windows, System.IOUtils,
  System.Generics.Collections, ToolsAPI, ToolsAPI.Editor, Vcl.Graphics,
  Vcl.Controls, Vcl.GraphUtil, Vcl.Forms, Vcl.ExtCtrls, RTTI;

type
  TStatusPanel = class(TCustomPanel)
  strict private
    const ForegroundColor = clWebSnow;
    const BackgroundColor = clWebDarkSlategray;
  private
    FPaintBox: TPaintBox;
    FStatusMsg: string;
    procedure SetStatusMsg(const Value: string);
    procedure PaintBoxPaint(Sender: TObject);
  public
    class function GetStatusPanel(EditWindow: INTAEditWindow): TStatusPanel;
    property StatusMsg: string read FStatusMsg write SetStatusMsg;
    constructor Create(AOwner: TComponent); override;
  end;

  TIDEWizard = class(TNotifierObject, IOTAWizard)
  private
    FEditorEventsNotifier: Integer;
    FLastKeyDownMsg, FLastKeyUpMsg: string;
    FLastCaretPosMsg: string;

    procedure CheckStatusPanel(const Editor: TWinControl);
    procedure UpdatePanelInfo(const Editor: TWinControl);
  protected
    procedure EditorMouseDownEx(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; var Handled: Boolean);
    procedure EditorMouseUpEx(const Editor: TWinControl; Button: TMouseButton; Shift: TShiftState; X, Y: Integer; var Handled: Boolean);
    procedure EditorSetCaretPos(const Editor: TWinControl; X, Y: Integer);
    procedure EditorKeyDown(const Editor: TWinControl; Key: Word; Shift: TShiftState; var Handled: Boolean);
    procedure EditorKeyUp(const Editor: TWinControl; Key: Word; Shift: TShiftState; var Handled: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    function GetIDString: string;
    procedure Execute;
    function GetName: string;
    function GetState: TWizardState;
  end;

  TCodeEditorNotifier = class(TNTACodeEditorNotifier)
  protected
    function AllowedEvents: TCodeEditorEvents; override;
  end;

procedure Register;
begin
  RegisterPackageWizard(TIDEWizard.Create);
end;

{ TIDEWizard }

procedure TIDEWizard.CheckStatusPanel(const Editor: TWinControl);
begin
  var LEditorServices: INTACodeEditorServices;
  if Supports(BorlandIDEServices, INTACodeEditorServices, LEditorServices) then
  begin
    var LEditWindow := LEditorServices.EditorState[Editor].View.GetEditWindow;
    var LPanel := TStatusPanel.GetStatusPanel(LEditWindow);
    if LPanel = nil then
      TStatusPanel.Create(LEditWindow.Form);
  end;
end;

constructor TIDEWizard.Create;
begin
  inherited;
  var LNotifier := TCodeEditorNotifier.Create;
  var LEditorServices: INTACodeEditorServices;
  if Supports(BorlandIDEServices, INTACodeEditorServices, LEditorServices) then
    FEditorEventsNotifier := LEditorServices.AddEditorEventsNotifier(LNotifier)
  else
    FEditorEventsNotifier := -1;

  LNotifier.OnEditorMouseDownEx := EditorMouseDownEx;
  LNotifier.OnEditorMouseUpEx := EditorMouseUpEx;
  LNotifier.OnEditorSetCaretPos := EditorSetCaretPos;
  LNotifier.OnEditorKeyDown := EditorKeyDown;
  LNotifier.OnEditorKeyUp := EditorKeyUp;
  FLastKeyDownMsg := '';
  FLastKeyUpMsg := '';
  FLastCaretPosMsg:= '';
end;


destructor TIDEWizard.Destroy;
begin
  var LEditorServices: INTACodeEditorServices;
  if Supports(BorlandIDEServices, INTACodeEditorServices, LEditorServices) and
    (FEditorEventsNotifier <> -1) and Assigned(LEditorServices) then
    LEditorServices.RemoveEditorEventsNotifier(FEditorEventsNotifier);
  inherited;
end;

procedure TIDEWizard.EditorKeyDown(const Editor: TWinControl; Key: Word;
  Shift: TShiftState; var Handled: Boolean);
begin
  FLastKeyDownMsg := Format('Last KeyDown Event %d $%x Shift %s', [Key, Key, TValue.From(Shift).ToString]);
  UpdatePanelInfo(Editor);
end;

procedure TIDEWizard.EditorKeyUp(const Editor: TWinControl; Key: Word;
  Shift: TShiftState; var Handled: Boolean);
begin
  FLastKeyUpMsg := Format('Last KeyUp Event %d $%x Shift %s', [Key, Key, TValue.From(Shift).ToString]);
  UpdatePanelInfo(Editor);
end;

procedure TIDEWizard.EditorMouseDownEx(const Editor: TWinControl;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  var Handled: Boolean);
begin

end;


procedure TIDEWizard.EditorMouseUpEx(const Editor: TWinControl;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer;
  var Handled: Boolean);
begin

end;

procedure TIDEWizard.EditorSetCaretPos(const Editor: TWinControl; X,
  Y: Integer);
begin
  FLastCaretPosMsg := Format('Last Caret Pos Event Colum %d LineNum %d', [X, Y]);
  UpdatePanelInfo(Editor);
end;

procedure TIDEWizard.Execute;
begin
end;

function TIDEWizard.GetIDString: string;
begin
  Result := '[60DB63CF-0AE7-4865-AF0B-AA2CF0A60A89]';
end;

function TIDEWizard.GetName: string;
begin
  Result := 'CodeEditor.KeyboardMouse.Demo';
end;

function TIDEWizard.GetState: TWizardState;
begin
  Result := [wsEnabled];
end;

procedure TIDEWizard.UpdatePanelInfo(const Editor: TWinControl);
begin
  CheckStatusPanel(Editor);
  var LEditorServices: INTACodeEditorServices;
  if Supports(BorlandIDEServices, INTACodeEditorServices, LEditorServices) then
  begin
    var LView := LEditorServices.EditorState[Editor].View;
    var LStrMsg := Format('%s %s %s', [FLastKeyDownMsg, FLastKeyUpMsg, FLastCaretPosMsg]);
    var LPanel := TStatusPanel.GetStatusPanel(LView.GetEditWindow);
    if LPanel <> nil then
      LPanel.StatusMsg := LStrMsg;
  end;
end;

{ TCodeEditorNotifier }

function TCodeEditorNotifier.AllowedEvents: TCodeEditorEvents;
begin
  Result := [cevMouseEvents, cevKeyboardEvents];
end;

{ TStatusPanel }

constructor TStatusPanel.Create(AOwner: TComponent);
const
  cPanelSize = 28;
begin
  inherited Create(AOwner);
  Name := ClassName;
  Align := alTop;
  BevelOuter := bvNone;
  ShowCaption := False;
  Height := cPanelSize;
  ParentBackground := False;
  StyleElements := StyleElements - [seClient];

  Top := 40; // make sure the panel is align under TEditorNavigationToolbar
  var LForm := AOwner as TCustomForm;
  var LPanel := TPanel(LForm.FindComponent('EditorPanel'));
  // Setting the parent calls to ScaleforDPI
  Parent := LPanel.Parent;

  FPaintBox := TPaintBox.Create(AOwner);
  FPaintBox.Parent := Self;
  FPaintBox.Align := alClient;
  FPaintBox.OnPaint := PaintBoxPaint;

  Visible := True;
  Color := BackgroundColor;
end;

class function TStatusPanel.GetStatusPanel(
  EditWindow: INTAEditWindow): TStatusPanel;
begin
  if EditWindow = nil then
    Exit(nil)
  else
    Result := TStatusPanel(EditWindow.Form.FindComponent(TStatusPanel.ClassName));
end;

procedure TStatusPanel.PaintBoxPaint(Sender: TObject);
const
  cAlignOffset = 8;
begin
  if not FStatusMsg.IsEmpty then
  begin
    var LRect := FPaintBox.ClientRect;
    Inc(LRect.Left, cAlignOffset);
    FPaintBox.Canvas.Font.Color := ForegroundColor;
    FPaintBox.Canvas.TextRect(LRect, FStatusMsg, [tfSingleLine, tfVerticalCenter]);
  end;
end;

procedure TStatusPanel.SetStatusMsg(const Value: string);
begin
  FStatusMsg := Value;
  if Assigned(FPaintBox) then
    FPaintBox.Invalidate;
end;

end.

