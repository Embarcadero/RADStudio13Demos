object Frm_JsonMain: TFrm_JsonMain
  Left = 0
  Top = 0
  Caption = 'VCL JSON (Gemini)'
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
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 48
    Align = alTop
    TabOrder = 0
    object EditText: TEdit
      Left = 1
      Top = 1
      Width = 738
      Height = 46
      Align = alClient
      TabOrder = 0
      Text = 
        'Return array of any 5 cities with fields name (string), average_' +
        'temperture (number), and number_ of_citizens (number). Only JSON' +
        '-array.'
      ExplicitHeight = 23
    end
    object BtnSend: TButton
      AlignWithMargins = True
      Left = 836
      Top = 4
      Width = 160
      Height = 40
      Align = alRight
      Caption = 'Send JSON Request'
      TabOrder = 1
      OnClick = BtnSendClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 742
      Top = 4
      Width = 88
      Height = 40
      Align = alRight
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = BtnCancelClick
    end
  end
  object Grid: TDBGrid
    Left = 0
    Top = 48
    Width = 1000
    Height = 512
    Align = alClient
    DataSource = DataSource1
    TabOrder = 1
    TitleFont.Charset = DEFAULT_CHARSET
    TitleFont.Color = clWindowText
    TitleFont.Height = -12
    TitleFont.Name = 'Segoe UI'
    TitleFont.Style = []
  end
  object MemoRaw: TMemo
    Left = 0
    Top = 560
    Width = 1000
    Height = 160
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 440
    Top = 272
    IndicatorSize = aisXLarge
  end
  object AIConnection: TAIConnection
    Driver = AIGeminiDriver
    Left = 64
    Top = 192
  end
  object AIGeminiDriver: TAIGeminiDriver
    Params.Strings = (
      'Model=gemini-2.5-flash')
    OnCancel = AIGeminiDriverCancel
    Left = 64
    Top = 120
  end
  object JsonReq: TAIJSONRequest
    Connection = AIConnection
    DataSet = FDMemTable1
    OnSuccess = JsonReqSuccess
    OnError = JsonReqError
    Left = 64
    Top = 272
  end
  object DataSource1: TDataSource
    DataSet = FDMemTable1
    Left = 216
    Top = 120
  end
  object FDMemTable1: TFDMemTable
    FetchOptions.AssignedValues = [evMode]
    FetchOptions.Mode = fmAll
    ResourceOptions.AssignedValues = [rvSilentMode]
    ResourceOptions.SilentMode = True
    UpdateOptions.AssignedValues = [uvCheckRequired, uvAutoCommitUpdates]
    UpdateOptions.CheckRequired = False
    UpdateOptions.AutoCommitUpdates = True
    Left = 208
    Top = 232
  end
end
