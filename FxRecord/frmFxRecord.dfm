object frmFxRecord: TfrmFxRecord
  Left = 0
  Top = 0
  Caption = 'FactoryX FxRecord'
  ClientHeight = 441
  ClientWidth = 726
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 17
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 726
    Height = 394
    ActivePage = tabStatus
    Align = alClient
    TabOrder = 0
    ExplicitTop = 2
    object tabStatus: TTabSheet
      Caption = 'Status'
      object memLog: TMemo
        Left = 0
        Top = 55
        Width = 718
        Height = 307
        Align = alClient
        Color = 9216
        Font.Charset = DEFAULT_CHARSET
        Font.Color = 9889633
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object pnlStatusTop: TPanel
        Left = 0
        Top = 0
        Width = 718
        Height = 55
        Align = alTop
        BevelOuter = bvNone
        Color = 5850948
        ParentBackground = False
        TabOrder = 1
        object lblState: TLabel
          Left = 16
          Top = 18
          Width = 58
          Height = 17
          Caption = 'STOPPED'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
        end
        object btnStart: TButton
          Left = 430
          Top = 12
          Width = 90
          Height = 31
          Caption = 'Start'
          TabOrder = 0
          OnClick = btnStartClick
        end
        object btnStop: TButton
          Left = 528
          Top = 12
          Width = 90
          Height = 31
          Caption = 'Stop'
          TabOrder = 1
          OnClick = btnStopClick
        end
        object btnClearLog: TButton
          Left = 624
          Top = 12
          Width = 90
          Height = 31
          Caption = 'Clear Log'
          TabOrder = 2
          OnClick = btnClearLogClick
        end
      end
    end
    object tabRecorder: TTabSheet
      Caption = 'Recorder'
      ImageIndex = 1
      ExplicitTop = 26
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 718
        Height = 362
        Align = alClient
        Color = 5850948
        ParentBackground = False
        TabOrder = 0
        ExplicitTop = -2
        object lblStreamPath: TLabel
          Left = 6
          Top = 24
          Width = 126
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Stream folder'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblArchivePath: TLabel
          Left = 6
          Top = 58
          Width = 126
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Archive folder'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblProfile: TLabel
          Left = 6
          Top = 92
          Width = 126
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Output profile'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblSplitMinutes: TLabel
          Left = 3
          Top = 134
          Width = 129
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Split minutes'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblRetentionDays: TLabel
          Left = 239
          Top = 134
          Width = 106
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Retention days'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblWarningGB: TLabel
          Left = 3
          Top = 180
          Width = 129
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Disk warning free GB'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object lblCriticalGB: TLabel
          Left = 208
          Top = 180
          Width = 137
          Height = 17
          Alignment = taRightJustify
          AutoSize = False
          Caption = 'Disk critical free GB'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentFont = False
        end
        object edStreamPath: TEdit
          Left = 138
          Top = 21
          Width = 534
          Height = 25
          TabOrder = 0
        end
        object btnBrowseStream: TButton
          Left = 680
          Top = 20
          Width = 32
          Height = 27
          Caption = '...'
          TabOrder = 1
          OnClick = btnBrowseStreamClick
        end
        object edArchivePath: TEdit
          Left = 138
          Top = 55
          Width = 534
          Height = 25
          TabOrder = 2
        end
        object btnBrowseArchive: TButton
          Left = 680
          Top = 52
          Width = 32
          Height = 27
          Caption = '...'
          TabOrder = 3
          OnClick = btnBrowseArchiveClick
        end
        object cbOutputProfile: TComboBox
          Left = 138
          Top = 89
          Width = 302
          Height = 25
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 4
          Text = 'SourceCopy'
          Items.Strings = (
            'SourceCopy'
            'MP4-H264-AAC'
            'WMV-WMA'
            'AVI-H264-MP3'
            'MOV-H264-AAC'
            'Audio-MP3'
            'Audio-WMA')
        end
        object edSplitMinutes: TEdit
          Left = 138
          Top = 131
          Width = 60
          Height = 25
          TabOrder = 5
          Text = '60'
        end
        object edRetentionDays: TEdit
          Left = 351
          Top = 131
          Width = 60
          Height = 25
          TabOrder = 6
          Text = '14'
        end
        object edWarningGB: TEdit
          Left = 138
          Top = 177
          Width = 60
          Height = 25
          TabOrder = 7
          Text = '20'
        end
        object edCriticalGB: TEdit
          Left = 351
          Top = 177
          Width = 60
          Height = 25
          TabOrder = 8
          Text = '5'
        end
        object chkRequireLive: TCheckBox
          Left = 138
          Top = 226
          Width = 337
          Height = 21
          Caption = 'Warn when no live stream is present'
          Checked = True
          Color = 5850948
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWhite
          Font.Height = -13
          Font.Name = 'Segoe UI'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          State = cbChecked
          TabOrder = 9
        end
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 394
    Width = 726
    Height = 47
    Align = alBottom
    BevelOuter = bvNone
    Color = 5850948
    ParentBackground = False
    TabOrder = 1
    object btnSave: TButton
      Left = 524
      Top = 8
      Width = 96
      Height = 31
      Caption = 'Save'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnClose: TButton
      Left = 626
      Top = 8
      Width = 92
      Height = 31
      Caption = 'Close'
      TabOrder = 1
      OnClick = btnCloseClick
    end
  end
end
