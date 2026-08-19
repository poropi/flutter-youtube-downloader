import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'YouTube Downloader'**
  String get appTitle;

  /// No description provided for @toolsReady.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp / ffmpeg / deno detected  ·  high quality MP4 / MP3 ready'**
  String get toolsReady;

  /// No description provided for @toolsMissing.
  ///
  /// In en, this message translates to:
  /// **'Missing: {tools}  ·  downloads unavailable'**
  String toolsMissing(String tools);

  /// No description provided for @toolJsRuntime.
  ///
  /// In en, this message translates to:
  /// **'deno (JS runtime)'**
  String get toolJsRuntime;

  /// No description provided for @urlLabel.
  ///
  /// In en, this message translates to:
  /// **'YouTube URL'**
  String get urlLabel;

  /// No description provided for @urlHint.
  ///
  /// In en, this message translates to:
  /// **'https://www.youtube.com/watch?v=...'**
  String get urlHint;

  /// No description provided for @fetchButton.
  ///
  /// In en, this message translates to:
  /// **'Fetch video info'**
  String get fetchButton;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @downloadButton.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadButton;

  /// No description provided for @openFolderButton.
  ///
  /// In en, this message translates to:
  /// **'Open destination folder'**
  String get openFolderButton;

  /// No description provided for @resetButton.
  ///
  /// In en, this message translates to:
  /// **'Start over'**
  String get resetButton;

  /// No description provided for @logPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get logPanelTitle;

  /// No description provided for @savedPath.
  ///
  /// In en, this message translates to:
  /// **'Saved to: {path}'**
  String savedPath(String path);

  /// No description provided for @formatMp3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get formatMp3Subtitle;

  /// No description provided for @formatMp4Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Video + audio'**
  String get formatMp4Subtitle;

  /// No description provided for @statusFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching video info...'**
  String get statusFetching;

  /// No description provided for @statusFetchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video info retrieved'**
  String get statusFetchSuccess;

  /// No description provided for @statusUrlInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid URL, or the video was not found'**
  String get statusUrlInvalid;

  /// No description provided for @statusDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get statusDownloading;

  /// No description provided for @statusDownloadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {received} / {total} MB'**
  String statusDownloadingProgress(String received, String total);

  /// No description provided for @statusDownloadingUnknownTotal.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {received} MB'**
  String statusDownloadingUnknownTotal(String received);

  /// No description provided for @statusMerging.
  ///
  /// In en, this message translates to:
  /// **'Merging video and audio with ffmpeg...'**
  String get statusMerging;

  /// No description provided for @statusConvertingMp3.
  ///
  /// In en, this message translates to:
  /// **'Converting to MP3...'**
  String get statusConvertingMp3;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done!'**
  String get statusDone;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String statusError(String message);

  /// No description provided for @statusToolsMissing.
  ///
  /// In en, this message translates to:
  /// **'Required commands not found: {tools}'**
  String statusToolsMissing(String tools);

  /// No description provided for @logFetchingInfo.
  ///
  /// In en, this message translates to:
  /// **'Fetching video info with yt-dlp...'**
  String get logFetchingInfo;

  /// No description provided for @logFetchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Retrieved: \"{title}\"'**
  String logFetchSuccess(String title);

  /// No description provided for @logUsingClient.
  ///
  /// In en, this message translates to:
  /// **'yt-dlp client: web_embedded'**
  String get logUsingClient;

  /// No description provided for @logSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved: {path}'**
  String logSaved(String path);

  /// No description provided for @logToolMissing.
  ///
  /// In en, this message translates to:
  /// **'{tool} not found. Install it with: {command}'**
  String logToolMissing(String tool, String command);

  /// No description provided for @logError.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String logError(String message);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
