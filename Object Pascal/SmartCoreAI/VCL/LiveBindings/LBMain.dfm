object Frm_LBMain: TFrm_LBMain
  Left = 0
  Top = 0
  Caption = 'LDB (OpenAI)'
  ClientHeight = 376
  ClientWidth = 446
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  TextHeight = 15
  object Edit1: TEdit
    Left = 128
    Top = 25
    Width = 201
    Height = 23
    TabOrder = 0
  end
  object Button1: TButton
    Left = 24
    Top = 24
    Width = 75
    Height = 25
    Caption = 'Try!'
    TabOrder = 1
    OnClick = Button1Click
  end
  object Memo1: TMemo
    Left = 128
    Top = 54
    Width = 201
    Height = 148
    TabOrder = 2
  end
  object AIConnection1: TAIConnection
    Driver = AIOpenAIDriver1
    Left = 152
    Top = 240
  end
  object AIOpenAIDriver1: TAIOpenAIDriver
    Params.Strings = (
      'Model=gpt-4o')
    Left = 249
    Top = 241
  end
  object AIChatBindSource1: TAIChatBindSource
    AutoActivate = True
    ScopeMappings = <>
    Left = 48
    Top = 240
  end
  object AIChatRequest1: TAIChatRequest
    Connection = AIConnection1
    Left = 160
    Top = 312
  end
  object BindingsList1: TBindingsList
    Methods = <>
    OutputConverters = <>
    Left = 48
    Top = 304
    object LinkControlToField1: TLinkControlToField
      Category = 'Quick Bindings'
      DataSource = AIChatBindSource1
      FieldName = 'Text'
      Control = Edit1
      Direction = linkDataToControl
      Track = False
    end
    object LinkControlToField2: TLinkControlToField
      Category = 'Quick Bindings'
      DataSource = AIChatBindSource1
      FieldName = 'Text'
      Control = Memo1
      Direction = linkDataToControl
      Track = False
    end
  end
end
