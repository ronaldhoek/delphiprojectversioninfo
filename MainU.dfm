object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Change version info'
  ClientHeight = 342
  ClientWidth = 369
  Color = clBtnFace
  Constraints.MinHeight = 380
  Constraints.MinWidth = 385
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  ShowHint = True
  OnCreate = FormCreate
  DesignSize = (
    369
    342)
  PixelsPerInch = 96
  TextHeight = 13
  object lblProjectCount: TLabel
    Left = 285
    Top = 23
    Width = 73
    Height = 13
    Alignment = taRightJustify
    Anchors = [akTop, akRight]
    Caption = 'lblProjectCount'
    ExplicitLeft = 293
  end
  object lvProjects: TListView
    Left = 8
    Top = 39
    Width = 353
    Height = 186
    Anchors = [akLeft, akTop, akRight, akBottom]
    Columns = <
      item
        AutoSize = True
        Caption = 'Filename'
      end
      item
        Width = 25
      end>
    MultiSelect = True
    ReadOnly = True
    RowSelect = True
    SortType = stText
    TabOrder = 2
    ViewStyle = vsReport
    OnChange = lvProjectsChange
    OnCustomDrawItem = lvProjectsCustomDrawItem
  end
  object btnAddProjects: TButton
    Left = 8
    Top = 8
    Width = 97
    Height = 25
    Action = actnAddProjects
    TabOrder = 0
  end
  object btnRemoveProjects: TButton
    Left = 111
    Top = 8
    Width = 97
    Height = 25
    Action = actnRemoveProjects
    TabOrder = 1
  end
  object btnExecute: TButton
    Left = 8
    Top = 309
    Width = 97
    Height = 25
    Action = actnExecute
    Anchors = [akLeft, akBottom]
    TabOrder = 4
  end
  object ProgressBar1: TProgressBar
    Left = 111
    Top = 314
    Width = 250
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    TabOrder = 5
  end
  object gbVersionInfo: TGroupBox
    Left = 8
    Top = 231
    Width = 353
    Height = 72
    Anchors = [akLeft, akRight, akBottom]
    Caption = 'Version information'
    TabOrder = 3
    object cbSetVersionBase: TCheckBox
      Left = 8
      Top = 18
      Width = 97
      Height = 17
      Caption = 'Set base version'
      TabOrder = 0
    end
    object edtVerMain: TCANumEdit
      Left = 111
      Top = 16
      Width = 42
      Height = 21
      AutoSize = False
      TabOrder = 1
      OnChange = edtVerBaseChange
    end
    object cbSetVersionRelease: TCheckBox
      Left = 8
      Top = 45
      Width = 97
      Height = 17
      Caption = 'Set release'
      TabOrder = 3
    end
    object edtVerRelease: TCANumEdit
      Left = 111
      Top = 43
      Width = 42
      Height = 21
      AutoSize = False
      TabOrder = 4
      OnChange = edtVerReleaseChange
    end
    object cbIncVersionBuild: TCheckBox
      Left = 159
      Top = 45
      Width = 97
      Height = 17
      Caption = 'Increase build'
      TabOrder = 5
    end
    object edtVerSub: TCANumEdit
      Left = 159
      Top = 16
      Width = 42
      Height = 21
      AutoSize = False
      TabOrder = 2
      OnChange = edtVerBaseChange
    end
  end
  object ActionList1: TActionList
    Left = 184
    Top = 80
    object actnAddProjects: TFileOpen
      Caption = 'Add projects'
      Dialog.DefaultExt = 'dproj'
      Dialog.Filter = 'Delphi project(group) files|*.dproj;*.groupproj'
      Dialog.Options = [ofAllowMultiSelect, ofPathMustExist, ofFileMustExist, ofEnableSizing]
      Dialog.Title = 'Select Delphi projects'
      Hint = 'Add projects to convert'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = actnAddProjectsAccept
    end
    object actnRemoveProjects: TAction
      Caption = 'Remove projects'
      Hint = 'Remove the selected projects'
      ShortCut = 16430
      OnExecute = actnRemoveProjectsExecute
      OnUpdate = actnRemoveProjectsUpdate
    end
    object actnExecute: TAction
      Caption = 'Execute'
      Hint = 'Execute conversion'
      ShortCut = 120
      OnExecute = actnExecuteExecute
      OnUpdate = actnExecuteUpdate
    end
  end
  object XMLDocument1: TXMLDocument
    NodeIndentStr = #9
    Options = [doNodeAutoCreate, doNodeAutoIndent, doAttrNull, doAutoPrefix, doNamespaceDecl]
    ParseOptions = [poPreserveWhiteSpace]
    Left = 96
    Top = 80
    DOMVendorDesc = 'MSXML'
  end
  object JvAppIniFileStorage1: TJvAppIniFileStorage
    StorageOptions.BooleanStringTrueValues = 'TRUE, YES, Y'
    StorageOptions.BooleanStringFalseValues = 'FALSE, NO, N'
    SubStorages = <>
    Left = 280
    Top = 80
  end
  object JvFormStorage1: TJvFormStorage
    AppStorage = JvAppIniFileStorage1
    AppStoragePath = '%FORM_NAME%\'
    OnSavePlacement = JvFormStorage1SavePlacement
    OnRestorePlacement = JvFormStorage1RestorePlacement
    StoredValues = <>
    Left = 280
    Top = 136
  end
end
