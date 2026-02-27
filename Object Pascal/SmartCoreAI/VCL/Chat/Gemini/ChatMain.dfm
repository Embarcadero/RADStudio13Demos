object Frm_ChatMain: TFrm_ChatMain
  Left = 0
  Top = 0
  Caption = 'Frm_ChatMain'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnResize = FormResize
  TextHeight = 15
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 624
    Height = 42
    Align = alTop
    TabOrder = 0
    object EditPrompt: TEdit
      Left = 1
      Top = 1
      Width = 400
      Height = 40
      Align = alClient
      TabOrder = 0
      Text = 'Say hello in one sentence.'
      ExplicitHeight = 23
    end
    object BtnSend: TButton
      AlignWithMargins = True
      Left = 500
      Top = 4
      Width = 120
      Height = 34
      Align = alRight
      Caption = 'Send Chat'
      TabOrder = 1
      OnClick = BtnSendClick
    end
    object BtnCancel: TButton
      AlignWithMargins = True
      Left = 404
      Top = 4
      Width = 90
      Height = 34
      Align = alRight
      Caption = 'Cancel'
      TabOrder = 2
      OnClick = BtnCancelClick
    end
  end
  object MemoLog: TMemo
    Left = 0
    Top = 42
    Width = 624
    Height = 399
    Align = alClient
    Lines.Strings = (
      '')
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ActivityIndicator1: TActivityIndicator
    Left = 256
    Top = 192
    IndicatorSize = aisXLarge
  end
  object AIConnection: TAIConnection
    Driver = AIGeminiDriver1
    Left = 96
    Top = 184
  end
  object AIChatRequest1: TAIChatRequest
    Connection = AIConnection
    OnResponse = AIChatRequest1Response
    OnError = AIChatRequest1Error
    Left = 96
    Top = 320
  end
  object AIGeminiDriver1: TAIGeminiDriver
    Params.Strings = (
      'Model=gemini-2.5-pro')
    OnCancel = AIGeminiDriver1Cancel
    OnChatSuccess = AIGeminiDriver1ChatSuccess
    Left = 96
    Top = 256
  end
end
