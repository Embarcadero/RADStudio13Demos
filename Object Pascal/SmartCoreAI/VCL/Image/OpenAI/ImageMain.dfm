object Frm_ImageMain: TFrm_ImageMain
  Left = 0
  Top = 0
  Caption = 'VCL Image (OpenAI)'
  ClientHeight = 720
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 15
  object Img: TImage
    Left = 0
    Top = 48
    Width = 1000
    Height = 522
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
    Height = 48
    Align = alTop
    TabOrder = 0
    object EditPrompt: TEdit
      Left = 1
      Top = 1
      Width = 715
      Height = 46
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
      Height = 40
      Align = alRight
      Caption = 'Generate Image'
      TabOrder = 1
      OnClick = BtnGenClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 719
      Top = 4
      Width = 111
      Height = 40
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
    Top = 320
    IndicatorSize = aisXLarge
  end
  object AIConnection: TAIConnection
    Driver = AIOpenAIDriver
    Left = 120
    Top = 288
  end
  object AIOpenAIDriver: TAIOpenAIDriver
    Params.Strings = (
      'N=2'
      'Model=gpt-image-1')
    OnCancel = AIOpenAIDriverCancel
    Left = 120
    Top = 208
  end
  object ImgReq: TAIImageRequest
    Connection = AIConnection
    OnSuccess = ImgReqSuccess
    OnError = ImgReqError
    Left = 120
    Top = 360
  end
end
