program kmshell;

uses
  comobj,
  Forms,
  SysUtils,
  ActiveX,
  Dialogs,
  initprog in 'main\initprog.pas',
  RegistryKeys in '..\..\global\delphi\general\RegistryKeys.pas',
  Registry,
  UfrmMain in 'main\UfrmMain.pas' {frmMain},
  kmint in 'util\kmint.pas',
  GetOsVersion in '..\..\global\delphi\general\GetOsVersion.pas',
  DebugPaths in '..\..\global\delphi\general\DebugPaths.pas',
  VersionInfo in '..\..\global\delphi\general\VersionInfo.pas',
  UfrmHTML in 'main\UfrmHTML.pas' {frmHTML},
  HotkeyUtils in '..\..\global\delphi\general\HotkeyUtils.pas',
  Unicode in '..\..\global\delphi\general\Unicode.pas',
  exceptionw in '..\..\global\delphi\general\exceptionw.pas',
  utilkmshell in 'util\utilkmshell.pas',
  custinterfaces in '..\..\global\delphi\cust\custinterfaces.pas',
  UfrmInstallKeyboard in 'install\UfrmInstallKeyboard.pas' {frmInstallKeyboard},
  MessageIdentifiers in '..\..\global\delphi\cust\MessageIdentifiers.pas',
  KeyNames in '..\..\global\delphi\general\KeyNames.pas',
  klog in '..\..\global\delphi\general\klog.pas',
  keymanapi_TLB in '..\..\engine\kmcomapi\keymanapi_TLB.pas',
  UfrmSplash in 'startup\UfrmSplash.pas' {frmSplash},
  UfrmKeymanBase in '..\..\global\delphi\ui\UfrmKeymanBase.pas' {frmKeymanBase},
  httpuploader in '..\..\global\delphi\general\httpuploader.pas',
  httpuploader_messageprocessor_forms in '..\..\global\delphi\general\httpuploader_messageprocessor_forms.pas',
  utildir in '..\..\global\delphi\general\utildir.pas',
  XMLRenderer in '..\..\global\delphi\ui\XMLRenderer.pas',
  KeyboardListXMLRenderer in 'render\KeyboardListXMLRenderer.pas',
  OptionsXMLRenderer in 'render\OptionsXMLRenderer.pas',
  HotkeysXMLRenderer in 'render\HotkeysXMLRenderer.pas',
  SupportXMLRenderer in 'render\SupportXMLRenderer.pas',
  LanguagesXMLRenderer in 'render\LanguagesXMLRenderer.pas',
  utilhttp in '..\..\global\delphi\general\utilhttp.pas',
  UfrmChangeHotkey in 'main\UfrmChangeHotkey.pas' {frmChangeHotkey},
  utilhotkey in '..\..\global\delphi\general\utilhotkey.pas',
  InterfaceHotkeys in '..\..\global\delphi\general\InterfaceHotkeys.pas',
  utilsystem in '..\..\global\delphi\general\utilsystem.pas',
  Upload_Settings in '..\..\global\delphi\general\Upload_Settings.pas',
  UfrmOnlineUpdateNewVersion in 'main\UfrmOnlineUpdateNewVersion.pas' {frmOnlineUpdateNewVersion},
  OnlineUpdateCheck in 'main\OnlineUpdateCheck.pas',
  utilxml in '..\..\global\delphi\general\utilxml.pas',
  UfrmInstallKeyboardFromWeb in 'install\UfrmInstallKeyboardFromWeb.pas' {frmInstallKeyboardFromWeb},
  UfrmWebContainer in '..\..\global\delphi\ui\UfrmWebContainer.pas' {frmWebContainer},
  SystemDebugPath in '..\..\global\delphi\general\SystemDebugPath.pas',
  MessageIdentifierConsts in '..\..\global\delphi\cust\MessageIdentifierConsts.pas',
  UfrmDownloadProgress in 'util\UfrmDownloadProgress.pas' {frmDownloadProgress},
  kmcomapi_errors in '..\..\global\delphi\general\kmcomapi_errors.pas',
  GenericXMLRenderer in 'render\GenericXMLRenderer.pas',
  help in 'main\help.pas',
  UfrmProxyConfiguration in 'main\UfrmProxyConfiguration.pas' {frmProxyConfiguration: TTntForm},
  OnlineUpdateCheckMessages in 'main\OnlineUpdateCheckMessages.pas',
  WelcomeXMLRenderer in 'render\WelcomeXMLRenderer.pas',
  ValidateKeymanInstalledSystemKeyboards in 'main\ValidateKeymanInstalledSystemKeyboards.pas',
  OnlineConstants in '..\..\global\delphi\productactivation\OnlineConstants.pas',
  keymanerrorcodes in '..\..\engine\kmcomapi\util\keymanerrorcodes.pas',
  uninstall in 'install\uninstall.pas',
  KeymanControlMessages in '..\..\global\delphi\general\KeymanControlMessages.pas',
  HintConsts in '..\..\global\delphi\hints\HintConsts.pas',
  UfrmTextEditor in 'startup\help\UfrmTextEditor.pas' {frmTextEditor: TTntForm},
  ttinfo in '..\..\global\delphi\general\ttinfo.pas',
  findfonts in '..\..\global\delphi\general\findfonts.pas',
  KMShellHints in 'util\KMShellHints.pas',
  UfrmHint in '..\..\global\delphi\hints\UfrmHint.pas' {frmHint: TTntForm},
  KeymanTextEditorRichEdit in '..\..\global\delphi\comp\KeymanTextEditorRichEdit.pas',
  Hints in '..\..\global\delphi\hints\Hints.pas',
  utilcheckfonts in '..\..\global\delphi\general\utilcheckfonts.pas',
  wininet5 in '..\..\global\delphi\general\wininet5.pas',
  GlobalProxySettings in '..\..\global\delphi\general\GlobalProxySettings.pas',
  ExternalExceptionHandler in '..\..\global\delphi\general\ExternalExceptionHandler.pas',
  ErrLogPath in '..\..\global\delphi\general\ErrLogPath.pas',
  UFixupMissingFile in '..\..\global\delphi\ui\UFixupMissingFile.pas',
  UImportOlderVersionKeyboards in 'main\UImportOlderVersionKeyboards.pas',
  UImportOlderKeyboardUtils in 'main\UImportOlderKeyboardUtils.pas',
  utiluac in '..\..\global\delphi\general\utiluac.pas',
  DownloadLocale in 'install\DownloadLocale.pas',
  WebSoundControl in '..\..\global\delphi\general\WebSoundControl.pas',
  UserMessages in '..\..\global\delphi\general\UserMessages.pas',
  UILanguages in 'util\UILanguages.pas',
  utilmsxml in '..\..\global\delphi\general\utilmsxml.pas',
  UfrmKeyboardOptions in 'main\UfrmKeyboardOptions.pas' {frmKeyboardOptions},
  UfrmOnlineUpdateIcon in 'main\UfrmOnlineUpdateIcon.pas' {frmOnlineUpdateIcon},
  KeymanTrayIcon in '..\..\engine\keyman\KeymanTrayIcon.pas',
  UImportOlderVersionKeyboards9 in 'main\UImportOlderVersionKeyboards9.pas',
  MSHTML_TLB in '..\..\global\delphi\tlb\MSHTML_TLB.pas',
  FixupLocaleDoctype in '..\..\global\delphi\general\FixupLocaleDoctype.pas',
  VisualKeyboard in '..\..\global\delphi\visualkeyboard\VisualKeyboard.pas',
  VKeyChars in '..\..\global\delphi\general\VKeyChars.pas',
  UfrmPrintOSK in 'util\UfrmPrintOSK.pas' {frmPrintOSK},
  VisualKeyboardExportHTML in '..\..\global\delphi\visualkeyboard\VisualKeyboardExportHTML.pas',
  VisualKeyboardExportXML in '..\..\global\delphi\visualkeyboard\VisualKeyboardExportXML.pas',
  VisualKeyboardParameters in '..\..\global\delphi\visualkeyboard\VisualKeyboardParameters.pas',
  MSXML2_TLB in '..\..\global\delphi\tlb\MSXML2_TLB.pas',
  VKeys in '..\..\global\delphi\general\VKeys.pas',
  ExtShiftState in '..\..\global\delphi\comp\ExtShiftState.pas',
  KeymanEmbeddedWB in '..\..\global\delphi\comp\KeymanEmbeddedWB.pas',
  UImportOlderVersionSettings in 'main\UImportOlderVersionSettings.pas',
  KeymanMutex in '..\..\global\delphi\general\KeymanMutex.pas',
  ErrorControlledRegistry in '..\..\global\delphi\vcl\ErrorControlledRegistry.pas',
  MSXMLDomCreate in '..\..\global\delphi\general\MSXMLDomCreate.pas',
  utilexecute in '..\..\global\delphi\general\utilexecute.pas',
  KeymanVersion in '..\..\global\delphi\general\KeymanVersion.pas',
  UfrmScriptError in '..\..\global\delphi\general\UfrmScriptError.pas' {frmScriptError},
  BaseKeyboards in '..\..\global\delphi\general\BaseKeyboards.pas',
  LoadIndirectStringUnit in '..\..\engine\keyman\langswitch\LoadIndirectStringUnit.pas',
  Glossary in '..\..\global\delphi\general\Glossary.pas',
  UfrmInstallKeyboardLanguage in 'install\UfrmInstallKeyboardLanguage.pas' {frmInstallKeyboardLanguage},
  UfrmBaseKeyboard in 'main\UfrmBaseKeyboard.pas' {frmBaseKeyboard},
  UnicodeBlocks in '..\..\global\delphi\general\UnicodeBlocks.pas',
  TempFileManager in '..\..\global\delphi\general\TempFileManager.pas',
  SHDocVw in '..\..\global\delphi\vcl\SHDocVw.pas',
  EmbeddedWB in '..\..\ext\embeddedwb\Source\EmbeddedWB.pas',
  keyman_msctf in '..\..\global\delphi\winapi\keyman_msctf.pas',
  utiltsf in '..\..\global\delphi\general\utiltsf.pas',
  utilolepicture in '..\..\engine\kmcomapi\util\utilolepicture.pas',
  kmxfile in '..\..\global\delphi\general\kmxfile.pas',
  utilfiletypes in '..\..\global\delphi\general\utilfiletypes.pas',
  CRC32 in '..\..\global\delphi\general\CRC32.pas',
  input_installlayoutortip in '..\..\global\delphi\winapi\input_installlayoutortip.pas',
  KPInstallPackageStartMenu in '..\..\global\delphi\general\KPInstallPackageStartMenu.pas',
  kmpinffile in '..\..\global\delphi\general\kmpinffile.pas',
  PackageFileFormats in '..\..\global\delphi\general\PackageFileFormats.pas',
  PackageInfo in '..\..\global\delphi\general\PackageInfo.pas',
  utilstr in '..\..\global\delphi\general\utilstr.pas',
  utilwow64 in '..\..\global\delphi\general\utilwow64.pas',
  KPUninstallPackageStartMenu in '..\..\global\delphi\general\KPUninstallPackageStartMenu.pas',
  KPInstallFontKMShell in 'util\KPInstallFontKMShell.pas',
  UpgradeMnemonicLayout in 'install\UpgradeMnemonicLayout.pas',
  UfrmKeepInTouch in 'main\UfrmKeepInTouch.pas' {frmKeepInTouch},
  UtilCheckOnline in 'util\UtilCheckOnline.pas',
  KeyboardTIPCheck in 'main\KeyboardTIPCheck.pas',
  utilfocusappwnd in 'util\utilfocusappwnd.pas',
  UImportOlderVersionKeyboards8 in 'main\UImportOlderVersionKeyboards8.pas',
  KeymanPaths in '..\..\global\delphi\general\KeymanPaths.pas',
  utiljclexception in '..\..\global\delphi\general\utiljclexception.pas',
  StockFileNames in '..\..\global\delphi\cust\StockFileNames.pas',
  KeymanEngineControl in '..\..\global\delphi\general\KeymanEngineControl.pas',
  KeymanOptionNames in '..\..\global\delphi\general\KeymanOptionNames.pas',
  VisualKeyboardLoaderBinary in '..\..\global\delphi\visualkeyboard\VisualKeyboardLoaderBinary.pas',
  VisualKeyboardLoaderXML in '..\..\global\delphi\visualkeyboard\VisualKeyboardLoaderXML.pas',
  VisualKeyboardSaverBinary in '..\..\global\delphi\visualkeyboard\VisualKeyboardSaverBinary.pas',
  VisualKeyboardSaverXML in '..\..\global\delphi\visualkeyboard\VisualKeyboardSaverXML.pas',
  UtilWaitForTSF in 'util\UtilWaitForTSF.pas',
  BCP47Tag in '..\..\global\delphi\general\BCP47Tag.pas';

{$R VERSION.RES}
{$R manifest.res}

begin
  CoInitFlags := COINIT_APARTMENTTHREADED;
  try
    Application.Initialize;
    Run;
  except
    on E:Exception do KeymanHandleException(E);
  end;
end.
