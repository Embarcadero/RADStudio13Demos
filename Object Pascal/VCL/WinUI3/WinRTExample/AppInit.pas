{*******************************************************}
{                                                       }
{              Delphi WinUI 3 WinRT XAML App            }
{                                                       }
{ Copyright(c) 1995-2022 Embarcadero Technologies, Inc. }
{                                                       }
{*******************************************************}

unit AppInit;

interface

uses
  System.SysUtils,
  System.Win.WinRT,             // TInspectableObject
  Winapi.WinRT,                 // IInspectable
  Winapi.Microsoft.UI.Xaml,     // IApplicationOverrides
  Winapi.ApplicationModel;      // event handler parameter types

type
  TDerivedApp = class(TInspectableObject, IApplicationOverrides)
  private
    FInner: IApplicationOverrides;
  public
    constructor Create;
    destructor Destroy; override;
    { IApplicationOverrides methods }
    procedure OnLaunched(args: ILaunchActivatedEventArgs); safecall;

    { Pointer event handlers for TextBlock }
    procedure OnPointerEntered(sender: IInspectable; e: Input_IPointerRoutedEventArgs);
    procedure OnPointerExited(sender: IInspectable; e: Input_IPointerRoutedEventArgs);

    { Click event handler for Button }
    procedure OnClick(sender: IInspectable; e: IRoutedEventArgs);
    property Inner: IApplicationOverrides read FInner write FInner;
  end;

{$REGION 'Event handler classes'}
  TPointerEventHandler = class(TInterfacedObject, Input_PointerEventHandler)
  private
    FProc: TProc<IInspectable, Input_IPointerRoutedEventArgs>;
  public
    constructor Create(Proc: TProc<IInspectable, Input_IPointerRoutedEventArgs>);
    { PointerEventHandler method }
    procedure Invoke(sender: IInspectable; e: Input_IPointerRoutedEventArgs); safecall;
  end;

  TClickEventHandler = class(TInterfacedObject, RoutedEventHandler)
  private
    FProc: TProc<IInspectable, IRoutedEventArgs>;
  public
    constructor Create(Proc: TProc<IInspectable, IRoutedEventArgs>);
    { RoutedEventHandler method }
    procedure Invoke(sender: IInspectable; e: IRoutedEventArgs); safecall;
  end;
{$ENDREGION}

implementation

{$INLINE AUTO}

uses
  Winapi.Windows,
  Winapi.Foundation,                   // TPropertyValue
  Winapi.Microsoft.CommonTypes,        // IUIElement, ...
  Winapi.Microsoft.UI,                 // TColors, ...
  Winapi.Microsoft.UI.Xaml.Media,      // TSolidColorBrush, ...
  Winapi.Microsoft.UI.Xaml.ControlsRT; // XAML control types

{ TDerivedApp }

constructor TDerivedApp.Create;
begin
  inherited;
  WriteLn('TDerivedApp.Create');
end;

destructor TDerivedApp.Destroy;
begin
  WriteLn('TDerivedApp.Destroy');
  inherited;
end;

var
  WinInner: IInspectable = nil;

procedure TDerivedApp.OnLaunched(args: ILaunchActivatedEventArgs);
const
  // This is based on the template project in VS2019
  Content1 = '<StackPanel xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Center">' +
               '<Button Name="ClickMeButton" >Click Me</Button>' +
             '</StackPanel>';
  // Quite similar to that used in the simple C++ example at:
  // https://www.interact-sw.co.uk/iangblog/2011/09/25/native-winrt-inheritance
  Content2 = '<Grid xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation">' +
              '<TextBlock Name="Text" TextAlignment="Center" HorizontalAlignment="Center" VerticalAlignment="Center" FontSize="56" Foreground="Red">' +
                '<Run Text="Hello World" />' +
                '<LineBreak/>' +
                '<Run Text="Delphi"/>' +
                '<LineBreak/>' +
                '<Run Text="WinRT Native App (XAML / WinUI 3)" />' +
              '</TextBlock>' +
            '</Grid>';
begin
  WriteLn('TDerivedApp.OnLaunched');
  Inner.OnLaunched(args);
  // Get current window
  var CurrentWindow := TWindow.Current;  // <-- nil
  if CurrentWindow = nil then
  begin
    // This is a packaged app, so TWindow.Current is always nil, so we make a window
    var WinOuter := TInspectableObject.Create; // NOTE: we don't free this in this demo, as it gets passed an as interface ref
    CurrentWindow := TWindow.Factory.CreateInstance(WinOuter, WinInner);
  end;

  var MainStackPanel := TStackPanel.Create;
  MainStackPanel.Orientation_ := Orientation.Vertical;
  (MainStackPanel as IFrameworkElement).HorizontalAlignment_ := HorizontalAlignment.Center;
  (MainStackPanel as IFrameworkElement).VerticalAlignment_ := VerticalAlignment.Center;
  MainStackPanel.Spacing := 20;
  CurrentWindow.Content := MainStackPanel as IUIElement;

  var MainStackPanelChildren := (MainStackPanel as IPanel).Children;
  var MainStackPanelChildrenVector := MainStackPanelChildren as IVector_1__IUIElement;
  // We are ready to add things as MainStackPanel's children now, via the above vector...

  // 1) Create a stack panel and button dynamically (code version of 2)
  var StackPanel := TStackPanel.Create;
  StackPanel.Orientation_ := Orientation.Vertical;
  (StackPanel as IFrameworkElement).HorizontalAlignment_ := HorizontalAlignment.Center;
  (StackPanel as IFrameworkElement).VerticalAlignment_ := VerticalAlignment.Center;
  var Button := TButton.Create;
  (Button as Primitives_IButtonBase).add_Click(TClickEventHandler.Create(self.OnClick));
  var ButtonContentControl := Button as IContentControl;
  ButtonContentControl.Content := TPropertyValue.CreateString(TWindowsString('Click Me'));
  var StackPanelChildren := (StackPanel as IPanel).Children;
  var StackPanelChildrenVector := StackPanelChildren as IVector_1__IUIElement;
  StackPanelChildrenVector.Append(Button as IUIElement);
  MainStackPanelChildrenVector.Append(StackPanel as IUIElement);
  var UIElement := MainStackPanel as IUIElement;
  CurrentWindow.Content := UIElement;

  // 2) Create a stack panel and button via XAML (XAML version of 1)
  var XamlContent := TWindowsString(Content1);
  UIElement := TMarkup_XamlReader.Load(XamlContent) as IUIElement;

  var ControlName := TWindowsString('ClickMeButton');
  var ButtonInsp := (UIElement as IFrameworkElement).FindName(ControlName);
  if ButtonInsp <> nil then
  begin
    Button := ButtonInsp as IButton;
    var ButtonBase := Button as Primitives_IButtonBase;
    var ButtonUIElement := ButtonInsp as IUIElement;
    ButtonBase.add_Click(TClickEventHandler.Create(self.OnClick))
  end
  else
    MessageBox(HWND_DESKTOP, 'Could not find Button in the XAML hierarchy :/', 'WinRT issue', MB_OK or MB_ICONERROR);
  MainStackPanelChildrenVector.Append(UIElement);

  // 3) Create a Grid and TexBlock via XAML
  XamlContent := TWindowsString(Content2);
  UIElement := TMarkup_XamlReader.Load(XamlContent) as IUIElement;

  ControlName := TWindowsString('Text');
  var TextBlockInsp := (UIElement as IFrameworkElement).FindName(ControlName);
  var TextBlock := TextBlockInsp as IUIElement;
  if TextBlock <> nil then
  begin
    TextBlock.add_PointerEntered(TPointerEventHandler.Create(self.OnPointerEntered));
    TextBlock.add_PointerExited(TPointerEventHandler.Create(self.OnPointerExited));
  end
  else
    MessageBox(HWND_DESKTOP, 'Could not find TextBlock in the XAML hierarchy :/', 'WinRT issue', MB_OK or MB_ICONERROR);
  MainStackPanelChildrenVector.Append(UIElement);

  CurrentWindow.Activate;
end;
{$ENDREGION}

{$REGION 'TextBlock event handlers'}
procedure TDerivedApp.OnPointerEntered(sender: IInspectable; e: Input_IPointerRoutedEventArgs);
begin
  //WriteLn('TDerivedApp.OnPointerEntered');
  var Brush := TSolidColorBrush.CreateInstanceWithColor(TColors.Statics.DarkGray);
  (Sender as ITextBlock).Foreground := Brush as IBrush;
end;

procedure TDerivedApp.OnPointerExited(sender: IInspectable; e: Input_IPointerRoutedEventArgs);
begin
  //WriteLn('TDerivedApp.OnPointerExited');
  var Brush := TSolidColorBrush.CreateInstanceWithColor(TColors.Statics.Red);
  (Sender as ITextBlock).Foreground := (Brush as IBrush);
end;
{$ENDREGION}

{$REGION 'Button event handler'}
procedure TDerivedApp.OnClick(sender: IInspectable; e: IRoutedEventArgs);
begin
  //WriteLn('TDerivedApp.OnClick');
  var Button := Sender as IButton;
  var ButtonContentControl := Button as IContentControl;
  // NOTE: This seems to break:
  //ButtonContentControl.Content := TPropertyValue.Statics.CreateString(TWindowsString('Clicked'));

  var ButtonContent := TWindowsString('Clicked');
  ButtonContentControl.Content := TPropertyValue.Statics.CreateString(ButtonContent);
end;
{$ENDREGION}

{$REGION 'Event handler classes'}
{ TPointerEventHandler }

constructor TPointerEventHandler.Create(Proc: TProc<IInspectable, Input_IPointerRoutedEventArgs>);
begin
  inherited Create;
  FProc := Proc;
end;

procedure TPointerEventHandler.Invoke(sender: IInspectable; e: Input_IPointerRoutedEventArgs);
begin
  if Assigned(FProc) then
    FProc(sender,  e);
end;

{ TClickEventHandler }

constructor TClickEventHandler.Create(Proc: TProc<IInspectable, IRoutedEventArgs>);
begin
  inherited Create;
  FProc := Proc;
end;

procedure TClickEventHandler.Invoke(sender: IInspectable; e: IRoutedEventArgs);
begin
  if Assigned(FProc) then
    FProc(sender,  e);
end;
{$ENDREGION}

end.
