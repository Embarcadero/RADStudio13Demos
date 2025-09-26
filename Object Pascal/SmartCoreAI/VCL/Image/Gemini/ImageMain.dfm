object FormImage: TFormImage
  Left = 0
  Top = 0
  Caption = 'VCL Image (Gemini)'
  ClientHeight = 720
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 15
  object Img: TImage
    Left = 0
    Top = 44
    Width = 1000
    Height = 526
    Align = alClient
    Center = True
    Proportional = True
    Stretch = True
    ExplicitTop = 0
    ExplicitWidth = 105
    ExplicitHeight = 105
  end
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 44
    Align = alTop
    TabOrder = 0
    object EditPrompt: TEdit
      Left = 1
      Top = 1
      Width = 716
      Height = 42
      Align = alClient
      TabOrder = 0
      Text = 
        'a cabin in a forest by a lake with a sunset, realistic, digital ' +
        'painting, artstation'
      ExplicitHeight = 23
    end
    object BtnGen: TButton
      AlignWithMargins = True
      Left = 836
      Top = 4
      Width = 160
      Height = 36
      Align = alRight
      Caption = 'Generate Image'
      TabOrder = 1
      OnClick = BtnGenClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 720
      Top = 4
      Width = 110
      Height = 36
      Align = alRight
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = BtnCancelClick
    end
  end
  object MemoLog: TMemo
    Left = 0
    Top = 570
    Width = 1000
    Height = 150
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 456
    Top = 296
    IndicatorSize = aisXLarge
  end
  object AIConnection: TAIConnection
    Driver = AIGeminiDriver
    Left = 128
    Top = 304
  end
  object AIGeminiDriver: TAIGeminiDriver
    Params.Strings = (
      'Model=gemini-2.5-flash-image-preview')
    OnCancel = AIGeminiDriverCancel
    Left = 128
    Top = 240
  end
  object AIImageRequest1: TAIImageRequest
    Connection = AIConnection
    OnSuccess = AIImageRequest1Success
    OnError = AIImageRequest1Error
    Left = 128
    Top = 368
  end
end
