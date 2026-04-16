import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

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
    Locale('zh'),
  ];

  /// App name
  ///
  /// In en, this message translates to:
  /// **'PR Dating'**
  String get appName;

  /// Confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// Cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// Save button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// Next button
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// Back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// Generic loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// Generic saving loading text
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get commonSaving;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get commonError;

  /// Skip button
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// Welcome screen main title
  ///
  /// In en, this message translates to:
  /// **'Date people who take care of themselves.'**
  String get authWelcomeTitle;

  /// Welcome screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Apply to join PR Dating. We review every profile.'**
  String get authWelcomeSubtitle;

  /// Welcome page badge label (exclusivity marker)
  ///
  /// In en, this message translates to:
  /// **'BY APPLICATION'**
  String get welcomeBadge;

  /// Welcome page main headline
  ///
  /// In en, this message translates to:
  /// **'You\'re serious. So are they.'**
  String get welcomeHeadline;

  /// Welcome page body copy
  ///
  /// In en, this message translates to:
  /// **'Every account is human-reviewed.'**
  String get welcomeBody;

  /// Apply CTA button
  ///
  /// In en, this message translates to:
  /// **'Apply to Join'**
  String get authApplyButton;

  /// Login button
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign In'**
  String get authLoginButton;

  /// Google OAuth sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// Apple OAuth sign-in button
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get authContinueWithApple;

  /// Email login entry button
  ///
  /// In en, this message translates to:
  /// **'Sign in with Email'**
  String get welcomeEmailLoginButton;

  /// Email login bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Sign In with Email'**
  String get emailLoginTitle;

  /// Email login bottom sheet subtitle
  ///
  /// In en, this message translates to:
  /// **'This is for existing beta accounts only.\nEnter your registered email and we\'ll send you a sign-in link.'**
  String get emailLoginSubtitle;

  /// Email input label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLoginLabel;

  /// Magic link send button
  ///
  /// In en, this message translates to:
  /// **'Send Login Link'**
  String get emailLoginSendLink;

  /// Magic link resend button
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get emailLoginResend;

  /// Magic link cooldown countdown text
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String emailLoginResendIn(int seconds);

  /// Hint guiding unregistered users and OAuth users back to the correct entry
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account yet? Go back and sign up with Google or Apple.\nIf you previously signed in with Google or Apple, please use those buttons instead.'**
  String get emailLoginOAuthHint;

  /// Invalid email error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get betaAccountEmailInvalid;

  /// Magic link sent success title
  ///
  /// In en, this message translates to:
  /// **'Login Link Sent'**
  String get betaAccountSentTitle;

  /// Shows the email address the magic link was sent to
  ///
  /// In en, this message translates to:
  /// **'Sent to {email}'**
  String betaAccountSentTo(String email);

  /// Magic link sent body text
  ///
  /// In en, this message translates to:
  /// **'Check your inbox and tap the link — the app will open automatically.\nThe link expires in 60 minutes.'**
  String get betaAccountSentBody;

  /// Consent text suffix (appended after authConsentPrefix + termsLabel)
  ///
  /// In en, this message translates to:
  /// **' and {privacy}'**
  String authConsentSuffix(String privacy);

  /// Approval gate page badge text
  ///
  /// In en, this message translates to:
  /// **'REVIEW COMPLETE'**
  String get approvedGateBadge;

  /// Approval gate page main title
  ///
  /// In en, this message translates to:
  /// **'You\'re In'**
  String get approvedGateTitle;

  /// Approval gate page body text (generic fallback)
  ///
  /// In en, this message translates to:
  /// **'Congratulations! You\'ve been approved to join PR Dating — welcome aboard.\nNext, link your phone number to complete your account setup.'**
  String get approvedGateBody;

  /// Approval gate page body — top tier (lifetime free)
  ///
  /// In en, this message translates to:
  /// **'Your profile meets PR Dating\'s community standards — welcome aboard.\nYou\'ll have free access to all features for life.\nOne last step — link your phone number to finish setting up your account.'**
  String get approvedGateBodyTop;

  /// Approval gate page body — standard tier (5-day free)
  ///
  /// In en, this message translates to:
  /// **'You\'ve passed our review. We look forward to seeing you in the community.\nYou\'ll enjoy a 5-day free trial, after which you can subscribe to continue.\nOne last step — link your phone number to finish setting up your account.'**
  String get approvedGateBodyStandard;

  /// Approval gate page — top tier label
  ///
  /// In en, this message translates to:
  /// **'Member · Free Forever'**
  String get approvedGateTierLabelTop;

  /// Approval gate page — standard tier label
  ///
  /// In en, this message translates to:
  /// **'5-Day Free Trial'**
  String get approvedGateTierLabelStandard;

  /// Approval gate page CTA button
  ///
  /// In en, this message translates to:
  /// **'Link Phone Number'**
  String get approvedGateCta;

  /// Approval gate page phone number disclaimer
  ///
  /// In en, this message translates to:
  /// **'Your number is only used for verification and won\'t appear on your profile'**
  String get approvedGateNote;

  /// Post-approval phone linking page title
  ///
  /// In en, this message translates to:
  /// **'Link Your Phone'**
  String get verifyPhoneTitle;

  /// Post-approval phone linking page subtitle
  ///
  /// In en, this message translates to:
  /// **'One last step! Link your phone number to verify your identity.'**
  String get verifyPhoneSubtitle;

  /// Phone uniqueness note
  ///
  /// In en, this message translates to:
  /// **'Each phone number can only be linked to one account'**
  String get verifyPhoneUniqueNote;

  /// Phone verification page title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get authPhoneTitle;

  /// Phone verification page subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number and we\'ll send you a verification code'**
  String get authPhoneSubtitle;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get authPhoneLabel;

  /// Phone number field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authPhoneHint;

  /// Send OTP button
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get authSendCode;

  /// OTP verification page title
  ///
  /// In en, this message translates to:
  /// **'Enter Verification Code'**
  String get authOtpTitle;

  /// OTP sent confirmation text
  ///
  /// In en, this message translates to:
  /// **'Code sent to {phone}'**
  String authOtpSentTo(String phone);

  /// OTP verify button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get authOtpVerify;

  /// Resend OTP button
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get authOtpResend;

  /// Resend OTP countdown
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authOtpResendIn(int seconds);

  /// OTP error message
  ///
  /// In en, this message translates to:
  /// **'Invalid verification code. Please try again.'**
  String get authOtpInvalid;

  /// OTP expired message
  ///
  /// In en, this message translates to:
  /// **'Code expired. Please request a new one.'**
  String get authOtpExpired;

  /// Invalid phone number error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get authPhoneInvalid;

  /// Shown when user selects an unsupported country code
  ///
  /// In en, this message translates to:
  /// **'This country/region is not yet supported. Stay tuned!'**
  String get phoneCountryUnsupported;

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authLoginTitle;

  /// Login page subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number to sign in'**
  String get authLoginSubtitle;

  /// Apply step indicator
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String applyStep(int current, int total);

  /// Apply Step 2 title
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get applyInfoTitle;

  /// Apply Step 2 subtitle
  ///
  /// In en, this message translates to:
  /// **'Let others know you'**
  String get applyInfoSubtitle;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get applyNameLabel;

  /// Display name placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get applyNameHint;

  /// Display name helper text
  ///
  /// In en, this message translates to:
  /// **'Up to 20 characters'**
  String get applyNameHelper;

  /// Name empty error
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name'**
  String get applyNameEmpty;

  /// Birth date field label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get applyBirthDateLabel;

  /// Birth date placeholder
  ///
  /// In en, this message translates to:
  /// **'Select your birthday'**
  String get applyBirthDateHint;

  /// Birth date empty error
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get applyBirthDateEmpty;

  /// Age requirement error
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 years old to apply'**
  String get applyAgeError;

  /// Gender field label
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get applyGenderLabel;

  /// Male option
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get applyGenderMale;

  /// Female option
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get applyGenderFemale;

  /// Other gender option
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get applyGenderOther;

  /// Gender empty error
  ///
  /// In en, this message translates to:
  /// **'Please select a gender'**
  String get applyGenderEmpty;

  /// Seeking field label
  ///
  /// In en, this message translates to:
  /// **'Interested in'**
  String get applySeekingLabel;

  /// Seeking men option
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get applySeekingMen;

  /// Seeking women option
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get applySeekingWomen;

  /// Seeking everyone option
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get applySeekingEveryone;

  /// Seeking empty error
  ///
  /// In en, this message translates to:
  /// **'Please select who you\'re interested in'**
  String get applySeekingEmpty;

  /// Apply Step 3 title
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get applyPhotosTitle;

  /// Apply Step 3 subtitle
  ///
  /// In en, this message translates to:
  /// **'Upload 2–9 recent, clear photos that show the real you. Long-press to reorder.'**
  String get applyPhotosSubtitle;

  /// Text shown in empty photo slot
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get applyPhotosAddPhoto;

  /// Pick photo from gallery option
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get applyPhotosFromGallery;

  /// Take photo with camera option
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get applyPhotosFromCamera;

  /// Photo upload loading text
  ///
  /// In en, this message translates to:
  /// **'Uploading photos...'**
  String get applyPhotosUploading;

  /// Number of photos selected
  ///
  /// In en, this message translates to:
  /// **'{count} photo(s) selected'**
  String applyPhotosSelected(int count);

  /// Minimum photos not met message
  ///
  /// In en, this message translates to:
  /// **'At least {min} photos required'**
  String applyPhotosMinRequired(int min);

  /// iOS limited photo access hint text
  ///
  /// In en, this message translates to:
  /// **'Limited access — some photos are hidden'**
  String get applyPhotosLimitedHint;

  /// iOS limited access: button to open system photo selection panel
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get applyPhotosManageAccess;

  /// Banner shown when reapplying with existing uploaded photos
  ///
  /// In en, this message translates to:
  /// **'You have {count} uploaded photos. Tap Next to keep them, or add new ones to replace.'**
  String applyPhotosExistingHint(int count);

  /// Gallery permission denied dialog title
  ///
  /// In en, this message translates to:
  /// **'Photo Library Access Required'**
  String get permissionPhotoTitle;

  /// Gallery permission denied dialog body
  ///
  /// In en, this message translates to:
  /// **'PR Dating needs access to your photo library to upload photos. Please enable it in Settings.'**
  String get permissionPhotoBody;

  /// Camera permission denied dialog title
  ///
  /// In en, this message translates to:
  /// **'Camera Access Required'**
  String get permissionCameraTitle;

  /// Camera permission denied dialog body
  ///
  /// In en, this message translates to:
  /// **'PR Dating needs camera access to take photos. Please enable it in Settings.'**
  String get permissionCameraBody;

  /// Open system settings button
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get permissionOpenSettings;

  /// Identity verification intro page title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Identity'**
  String get applyVerifyIntroTitle;

  /// Identity verification intro page body
  ///
  /// In en, this message translates to:
  /// **'To keep our community safe, we need to confirm you\'re a real person.\nVerification photos are only visible to our review team and will never be shown publicly.'**
  String get applyVerifyIntroBody;

  /// Verification flow step 1 description
  ///
  /// In en, this message translates to:
  /// **'Front-facing photo'**
  String get applyVerifyIntroStep1;

  /// Verification flow step 2 description
  ///
  /// In en, this message translates to:
  /// **'Left profile photo'**
  String get applyVerifyIntroStep2;

  /// Verification flow step 3 description
  ///
  /// In en, this message translates to:
  /// **'2 random actions'**
  String get applyVerifyIntroStep3;

  /// Start verification button
  ///
  /// In en, this message translates to:
  /// **'Start Verification'**
  String get applyVerifyStartButton;

  /// Verification step — front face title
  ///
  /// In en, this message translates to:
  /// **'Front-facing photo'**
  String get applyVerifyStepFrontTitle;

  /// Verification step — front face hint
  ///
  /// In en, this message translates to:
  /// **'Face the camera with a natural expression'**
  String get applyVerifyStepFrontHint;

  /// Verification step — side face title
  ///
  /// In en, this message translates to:
  /// **'Left profile photo'**
  String get applyVerifyStepSideTitle;

  /// Verification step — side face hint
  ///
  /// In en, this message translates to:
  /// **'Turn your head to the left so your profile is clearly visible'**
  String get applyVerifyStepSideHint;

  /// Verification step — action title
  ///
  /// In en, this message translates to:
  /// **'Perform the action'**
  String get applyVerifyStepActionTitle;

  /// Verification step — action hint
  ///
  /// In en, this message translates to:
  /// **'Face the camera and perform the following action:'**
  String get applyVerifyStepActionHint;

  /// Take photo button
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get applyVerifyTakePhoto;

  /// Retake photo button
  ///
  /// In en, this message translates to:
  /// **'Retake'**
  String get applyVerifyRetake;

  /// Continue to next step button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get applyVerifyNextStep;

  /// Complete button on the last verification step
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get applyVerifyDone;

  /// Verification photo upload loading text
  ///
  /// In en, this message translates to:
  /// **'Uploading verification photos...'**
  String get applyVerifyUploading;

  /// Verification action: smile
  ///
  /// In en, this message translates to:
  /// **'Smile at the camera'**
  String get verifyActionSmile;

  /// Verification action: open mouth
  ///
  /// In en, this message translates to:
  /// **'Open your mouth'**
  String get verifyActionOpenMouth;

  /// Verification action: raise right hand
  ///
  /// In en, this message translates to:
  /// **'Raise your right hand'**
  String get verifyActionRaiseRightHand;

  /// Verification action: raise left hand
  ///
  /// In en, this message translates to:
  /// **'Raise your left hand'**
  String get verifyActionRaiseLeftHand;

  /// Verification action: wave
  ///
  /// In en, this message translates to:
  /// **'Wave at the camera'**
  String get verifyActionWave;

  /// Verification action: thumbs up
  ///
  /// In en, this message translates to:
  /// **'Give a thumbs up'**
  String get verifyActionThumbsUp;

  /// Verification action: touch nose
  ///
  /// In en, this message translates to:
  /// **'Touch your nose with your finger'**
  String get verifyActionTouchNose;

  /// Verification action: tilt head
  ///
  /// In en, this message translates to:
  /// **'Tilt your head toward your right shoulder'**
  String get verifyActionTiltHead;

  /// Verification action: show number 6 (thumb and pinky extended)
  ///
  /// In en, this message translates to:
  /// **'Show the number 6 with your hand'**
  String get verifyActionShowSix;

  /// Verification action: show number 7 (index, middle, ring fingers extended)
  ///
  /// In en, this message translates to:
  /// **'Show the number 7 with your hand'**
  String get verifyActionShowSeven;

  /// Verification action: show number 8 (thumb and index finger in L shape)
  ///
  /// In en, this message translates to:
  /// **'Show the number 8 with your hand'**
  String get verifyActionShowEight;

  /// Verification action: show number 9 (index finger curled)
  ///
  /// In en, this message translates to:
  /// **'Show the number 9 with your hand'**
  String get verifyActionShowNine;

  /// Apply Step 5 title
  ///
  /// In en, this message translates to:
  /// **'What are you into?'**
  String get applyInterestsTitle;

  /// Apply Step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'Pick at least {min} to help with matching'**
  String applyInterestsSubtitle(int min);

  /// Interests selected count
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String applyInterestsSelected(int count);

  /// Interests below minimum prompt
  ///
  /// In en, this message translates to:
  /// **'{remaining} more to go'**
  String applyInterestsShortfall(int remaining);

  /// Category limit reached prompt
  ///
  /// In en, this message translates to:
  /// **'This category allows max {max} picks'**
  String applyInterestsCategoryMax(int max);

  /// Custom interest bottom sheet title
  ///
  /// In en, this message translates to:
  /// **'Add a custom interest'**
  String get applyInterestsAddCustomTitle;

  /// Custom interest input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter interest name'**
  String get applyInterestsAddCustomHint;

  /// Add custom interest confirm button
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get applyInterestsAddButton;

  /// Apply Step 6 title
  ///
  /// In en, this message translates to:
  /// **'Let them get to know you'**
  String get applyQuestionsTitle;

  /// Apply Step 6 subtitle
  ///
  /// In en, this message translates to:
  /// **'Answer at least 1 — there are no wrong answers'**
  String get applyQuestionsSubtitle;

  /// Questions answered count
  ///
  /// In en, this message translates to:
  /// **'{count} answered'**
  String applyQuestionsAnswered(int count);

  /// Questions below minimum prompt
  ///
  /// In en, this message translates to:
  /// **'Answer at least 1 question to continue'**
  String get applyQuestionsMinRequired;

  /// Question answer input placeholder
  ///
  /// In en, this message translates to:
  /// **'Share your thoughts...'**
  String get applyQuestionsAnswerHint;

  /// Save question answer button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get applyQuestionsAnswerSave;

  /// Clear question answer button
  ///
  /// In en, this message translates to:
  /// **'Clear answer'**
  String get applyQuestionsAnswerClear;

  /// Apply Step 7 title
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get applyBioTitle;

  /// Apply Step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself (optional)'**
  String get applyBioSubtitle;

  /// Bio input placeholder
  ///
  /// In en, this message translates to:
  /// **'Share your interests, lifestyle, or anything you\'d like others to know...'**
  String get applyBioHint;

  /// Bio character limit helper
  ///
  /// In en, this message translates to:
  /// **'Up to 500 characters'**
  String get applyBioHelper;

  /// Confirm dialog title when leaving apply flow
  ///
  /// In en, this message translates to:
  /// **'Leave Application?'**
  String get applyLeaveDialogTitle;

  /// Confirm dialog body when leaving apply flow
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out. You can continue your application next time you sign in.'**
  String get applyLeaveDialogBody;

  /// Confirm button when leaving apply flow
  ///
  /// In en, this message translates to:
  /// **'Leave & Sign Out'**
  String get applyLeaveDialogConfirm;

  /// Apply Step 5 title
  ///
  /// In en, this message translates to:
  /// **'Review & Submit'**
  String get applyConfirmTitle;

  /// Apply Step 5 subtitle
  ///
  /// In en, this message translates to:
  /// **'Please review your details before submitting'**
  String get applyConfirmSubtitle;

  /// Placeholder when bio is empty
  ///
  /// In en, this message translates to:
  /// **'(Not filled in)'**
  String get applyConfirmNoBio;

  /// Loading text while submitting
  ///
  /// In en, this message translates to:
  /// **'Submitting application...'**
  String get applyConfirmSubmitting;

  /// Submit application button
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get applySubmitButton;

  /// Confirm page review info card title
  ///
  /// In en, this message translates to:
  /// **'Review Info'**
  String get applyConfirmReviewInfoTitle;

  /// Confirm page review timeline description
  ///
  /// In en, this message translates to:
  /// **'Timeline: Usually completed within 1–3 business days'**
  String get applyConfirmReviewDays;

  /// Confirm page review notification description
  ///
  /// In en, this message translates to:
  /// **'Notification: We\'ll notify you via app push notification and email'**
  String get applyConfirmReviewNotify;

  /// Terms agreement text
  ///
  /// In en, this message translates to:
  /// **'I agree to the Terms of Service and Privacy Policy'**
  String get applyTermsAgree;

  /// Review pending screen title
  ///
  /// In en, this message translates to:
  /// **'Application Submitted'**
  String get reviewPendingTitle;

  /// Review pending screen body text
  ///
  /// In en, this message translates to:
  /// **'Our team will complete the review within 1–3 business days. You\'ll be notified via app push notification and email.'**
  String get reviewPendingBody;

  /// Pending timeline step 1 label
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get reviewPendingStep1Label;

  /// Pending timeline step 1 sublabel
  ///
  /// In en, this message translates to:
  /// **'Your profile is queued for review'**
  String get reviewPendingStep1Sub;

  /// Pending timeline step 2 label
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get reviewPendingStep2Label;

  /// Pending timeline step 2 sublabel
  ///
  /// In en, this message translates to:
  /// **'Usually completed within 1–3 business days'**
  String get reviewPendingStep2Sub;

  /// Pending timeline step 3 label
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get reviewPendingStep3Label;

  /// Pending timeline step 3 sublabel
  ///
  /// In en, this message translates to:
  /// **'Result sent via app push notification and email'**
  String get reviewPendingStep3Sub;

  /// Review rejected screen title (fallback)
  ///
  /// In en, this message translates to:
  /// **'Not Quite Yet'**
  String get reviewRejectedTitle;

  /// Review rejected screen body text (fallback)
  ///
  /// In en, this message translates to:
  /// **'Your profile doesn\'t meet our community standards at this time. You\'re welcome to reapply in 30 days.'**
  String get reviewRejectedBody;

  /// Rejected screen title — hard rejection
  ///
  /// In en, this message translates to:
  /// **'Thank You for Applying'**
  String get reviewRejectedTitleHard;

  /// Rejected screen body — hard rejection
  ///
  /// In en, this message translates to:
  /// **'Thank you for your application. To ensure every member has the best possible matching experience, we have basic quality standards for application photos.\nHere are some tips that might be helpful:'**
  String get reviewRejectedBodyHard;

  /// Rejected screen title — potential tier
  ///
  /// In en, this message translates to:
  /// **'Almost There!'**
  String get reviewRejectedTitlePotential;

  /// Rejected screen body — potential tier
  ///
  /// In en, this message translates to:
  /// **'Thank you for your application. To ensure every member has the best possible matching experience, we have basic quality standards for application photos.\nYou\'re close to our standard — try these tips before reapplying:'**
  String get reviewRejectedBodyPotential;

  /// Soft-rejected page: admin feedback card title
  ///
  /// In en, this message translates to:
  /// **'Review Feedback'**
  String get reviewAdminFeedbackTitle;

  /// Rejection tag: photo blurry or poor lighting
  ///
  /// In en, this message translates to:
  /// **'Try submitting clear, well-lit photos'**
  String get reviewRejectedTagPhotoBlurry;

  /// Rejection tag: messy background
  ///
  /// In en, this message translates to:
  /// **'Try shooting in a tidy or visually appealing space'**
  String get reviewRejectedTagMessyBackground;

  /// Rejection tag: casual/ungroomed style
  ///
  /// In en, this message translates to:
  /// **'Consider presenting a more put-together look and style'**
  String get reviewRejectedTagCasualStyle;

  /// Rejection tag: face not clearly visible
  ///
  /// In en, this message translates to:
  /// **'Make sure your main photo shows your face clearly'**
  String get reviewRejectedTagFaceUnclear;

  /// Rejection tag: too few photos
  ///
  /// In en, this message translates to:
  /// **'Try including at least 3 photos from different angles'**
  String get reviewRejectedTagTooFewPhotos;

  /// Improvement tip 1
  ///
  /// In en, this message translates to:
  /// **'Shoot near a window or outdoors in natural light'**
  String get reviewRejectedTip1;

  /// Improvement tip 2
  ///
  /// In en, this message translates to:
  /// **'Keep your face clear — avoid heavy filters or editing'**
  String get reviewRejectedTip2;

  /// Improvement tip 3
  ///
  /// In en, this message translates to:
  /// **'Add a lifestyle photo that shows your personality'**
  String get reviewRejectedTip3;

  /// Reapply CTA button
  ///
  /// In en, this message translates to:
  /// **'Reapply Now'**
  String get reviewReapplyButton;

  /// Shows how many reapply attempts are left (max 3 total)
  ///
  /// In en, this message translates to:
  /// **'{remaining} attempt(s) remaining'**
  String reviewReapplyAttemptsLeft(int remaining);

  /// Title shown when all application attempts are used up
  ///
  /// In en, this message translates to:
  /// **'No More Attempts'**
  String get reviewReapplyExhaustedTitle;

  /// Body shown when all application attempts are used up
  ///
  /// In en, this message translates to:
  /// **'Each account is limited to 3 application attempts. This account has reached the limit. Thank you for your interest in PR Dating.'**
  String get reviewReapplyExhaustedBody;

  /// Sign out button on exhausted page
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get reviewExhaustedSignOut;

  /// Contact us hint on exhausted page (tap to copy email)
  ///
  /// In en, this message translates to:
  /// **'Questions? Contact us'**
  String get reviewExhaustedContactUs;

  /// SnackBar shown after copying support email
  ///
  /// In en, this message translates to:
  /// **'Email copied'**
  String get reviewExhaustedEmailCopied;

  /// Subtle delete account entry at bottom of rejected page
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get reviewDeleteRequestButton;

  /// Delete account confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get reviewDeleteDialogTitle;

  /// Delete account confirmation dialog body
  ///
  /// In en, this message translates to:
  /// **'Your account data will be permanently deleted 90 days from now. During this period, you can log in and cancel this request. After 90 days, you may reapply with a fresh start.'**
  String get reviewDeleteDialogBody;

  /// Delete account confirm button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get reviewDeleteDialogConfirm;

  /// Delete account cancel button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get reviewDeleteDialogCancel;

  /// Pending deletion page title
  ///
  /// In en, this message translates to:
  /// **'Deletion Scheduled'**
  String get pendingDeletionTitle;

  /// Pending deletion page body
  ///
  /// In en, this message translates to:
  /// **'All your data will be permanently deleted on the date below. After that, you may reapply with a fresh start.'**
  String get pendingDeletionBody;

  /// Date label on pending deletion page
  ///
  /// In en, this message translates to:
  /// **'Scheduled for'**
  String get pendingDeletionDateLabel;

  /// Cancel deletion request button
  ///
  /// In en, this message translates to:
  /// **'Cancel Deletion'**
  String get pendingDeletionCancelButton;

  /// Sign out button on pending deletion page
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get pendingDeletionSignOut;

  /// SnackBar after successfully cancelling deletion
  ///
  /// In en, this message translates to:
  /// **'Deletion request cancelled'**
  String get pendingDeletionCancelSuccess;

  /// Contact us hint at bottom of pending page (tap to copy email)
  ///
  /// In en, this message translates to:
  /// **'Questions? Feel free to contact us'**
  String get reviewPendingContactUs;

  /// SnackBar after copying email on pending page
  ///
  /// In en, this message translates to:
  /// **'Email copied'**
  String get reviewPendingEmailCopied;

  /// Discover tab title
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// Empty state on discover page
  ///
  /// In en, this message translates to:
  /// **'You\'ve seen everyone'**
  String get discoverEmptyTitle;

  /// Empty state subtitle on discover page
  ///
  /// In en, this message translates to:
  /// **'Check back later for new profiles.'**
  String get discoverEmptySubtitle;

  /// Discover page waiting-for-midnight-refresh title
  ///
  /// In en, this message translates to:
  /// **'Today\'s picks are on their way'**
  String get discoverMidnightTitle;

  /// Discover page waiting-for-refresh body text, includes local equivalent time
  ///
  /// In en, this message translates to:
  /// **'PR Dating refreshes your daily matches at midnight Taiwan time\n({localTime} your local time)'**
  String discoverMidnightSubtitle(String localTime);

  /// Discover page countdown label
  ///
  /// In en, this message translates to:
  /// **'Next refresh in'**
  String get discoverMidnightCountdownLabel;

  /// Match tab title
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get matchTitle;

  /// New match notification title
  ///
  /// In en, this message translates to:
  /// **'It\'s a Match!'**
  String get matchNewMatch;

  /// Chat tab title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get chatTitle;

  /// Empty chat state
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get chatEmptyTitle;

  /// Profile tab title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// Profile page edit button
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditButton;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language option
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Log out option
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogout;

  /// Delete account button
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get settingsDeleteAccount;

  /// Report profile dialog title
  ///
  /// In en, this message translates to:
  /// **'Report Profile'**
  String get reportTitle;

  /// Submit report button
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// Block user button
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// Onboarding skip button (reserved, not shown)
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// Onboarding mid-page CTA button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// Onboarding last page CTA button
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready'**
  String get onboardingGetStarted;

  /// Onboarding page 1 title
  ///
  /// In en, this message translates to:
  /// **'You deserve\nsomeone like you.'**
  String get onboarding1Title;

  /// Onboarding page 1 body
  ///
  /// In en, this message translates to:
  /// **'Intentionality shows.\n\nThe care someone puts into how they present themselves\n\nThat\'s how they\'ll show up for you too.'**
  String get onboarding1Body;

  /// Onboarding page 2 title
  ///
  /// In en, this message translates to:
  /// **'We screen\nfor intention.'**
  String get onboarding2Title;

  /// Onboarding page 2 body
  ///
  /// In en, this message translates to:
  /// **'Not algorithms. Real people.\n\nEvery account on PR Dating is reviewed by hand — because attitude can\'t be automated.\n'**
  String get onboarding2Body;

  /// Onboarding page 3 title
  ///
  /// In en, this message translates to:
  /// **'Good connections\naren\'t luck.'**
  String get onboarding3Title;

  /// Onboarding page 3 body
  ///
  /// In en, this message translates to:
  /// **'No more endless scrolling.\n\nEvery day, PR Dating curates a small circle of people — each one genuinely worth your time.\n\nYou take yourself seriously.\nYou deserve someone who does too.'**
  String get onboarding3Body;

  /// Onboarding page 1 background quote 1
  ///
  /// In en, this message translates to:
  /// **'These are the photos they handpicked to show you.\n Imagine what meeting them looks like.'**
  String get onboarding1Quote1;

  /// Onboarding page 1 background quote 2
  ///
  /// In en, this message translates to:
  /// **'Am I asking for too much?'**
  String get onboarding1Quote2;

  /// Onboarding page 1 background quote 3
  ///
  /// In en, this message translates to:
  /// **'I spent an hour getting ready and they showed up like…'**
  String get onboarding1Quote3;

  /// Onboarding page 1 background quote 4
  ///
  /// In en, this message translates to:
  /// **'Why does nobody put in effort anymore?'**
  String get onboarding1Quote4;

  /// Onboarding page 1 background quote 5
  ///
  /// In en, this message translates to:
  /// **'Their photos look like they couldn\'t care less'**
  String get onboarding1Quote5;

  /// Onboarding page 1 background quote 6
  ///
  /// In en, this message translates to:
  /// **'Am I the only one who actually cares about showing up?'**
  String get onboarding1Quote6;

  /// Onboarding page 2 background quote 1
  ///
  /// In en, this message translates to:
  /// **'How do I even know if he\'s real?'**
  String get onboarding2Quote1;

  /// Onboarding page 2 background quote 2
  ///
  /// In en, this message translates to:
  /// **'Fake photos, fake info — all of it'**
  String get onboarding2Quote2;

  /// Onboarding page 2 background quote 3
  ///
  /// In en, this message translates to:
  /// **'It feels like I\'m talking to a bot'**
  String get onboarding2Quote3;

  /// Onboarding page 2 background quote 4
  ///
  /// In en, this message translates to:
  /// **'I can\'t tell if there\'s a real person on the other side'**
  String get onboarding2Quote4;

  /// Onboarding page 2 background quote 5
  ///
  /// In en, this message translates to:
  /// **'Chatted for weeks before realizing it was a fake account'**
  String get onboarding2Quote5;

  /// Onboarding page 2 background quote 6
  ///
  /// In en, this message translates to:
  /// **'We had plans and then they just vanished…'**
  String get onboarding2Quote6;

  /// Onboarding page 3 background quote 1
  ///
  /// In en, this message translates to:
  /// **'Scrolled forever and nobody feels right'**
  String get onboarding3Quote1;

  /// Onboarding page 3 background quote 2
  ///
  /// In en, this message translates to:
  /// **'I\'m so tired of swiping'**
  String get onboarding3Quote2;

  /// Onboarding page 3 background quote 3
  ///
  /// In en, this message translates to:
  /// **'After a while I forgot what I was even looking for'**
  String get onboarding3Quote3;

  /// Onboarding page 3 background quote 4
  ///
  /// In en, this message translates to:
  /// **'Is this even working?'**
  String get onboarding3Quote4;

  /// Onboarding page 3 background quote 5
  ///
  /// In en, this message translates to:
  /// **'99+ messages a day and I can\'t connect with anyone'**
  String get onboarding3Quote5;

  /// Onboarding page 3 background quote 6
  ///
  /// In en, this message translates to:
  /// **'There has to be a better way than this…'**
  String get onboarding3Quote6;

  /// Terms update page title
  ///
  /// In en, this message translates to:
  /// **'We\'ve Updated Our Terms'**
  String get termsUpdateTitle;

  /// Terms update page subtitle
  ///
  /// In en, this message translates to:
  /// **'We\'ve updated our Terms of Service and Privacy Policy. Please review them to continue using PR Dating.'**
  String get termsUpdateSubtitle;

  /// Terms update accept button
  ///
  /// In en, this message translates to:
  /// **'I\'ve Read and Agree to the New Terms'**
  String get termsUpdateAccept;

  /// Terms update decline button
  ///
  /// In en, this message translates to:
  /// **'Decline and Sign Out'**
  String get termsUpdateDecline;

  /// Terms update processing loading text
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get termsUpdateAccepting;

  /// Terms of Service page title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsPageTitle;

  /// Privacy Policy page title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPageTitle;

  /// Terms of Service inline link label
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsLabel;

  /// Privacy Policy inline link label
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyLabel;

  /// Link to open full Terms of Service page
  ///
  /// In en, this message translates to:
  /// **'Read full Terms of Service'**
  String get termsReadFull;

  /// Link to open full Privacy Policy page
  ///
  /// In en, this message translates to:
  /// **'Read full Privacy Policy'**
  String get privacyReadFull;

  /// Prefix before the terms link in the agree row
  ///
  /// In en, this message translates to:
  /// **'I agree to the '**
  String get termsAgreePrefix;

  /// Conjunction between terms link and privacy link
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get termsAgreeAnd;

  /// Implicit consent notice prefix shown before sending OTP
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our '**
  String get authConsentPrefix;

  /// Hard rejection tip 1 (neutral, no appearance judgement)
  ///
  /// In en, this message translates to:
  /// **'Authentic photos that show your true self tend to resonate best'**
  String get reviewRejectedHardTip1;

  /// Hard rejection tip 2
  ///
  /// In en, this message translates to:
  /// **'A personal bio helps others get to know you in a more complete way'**
  String get reviewRejectedHardTip2;

  /// Hard rejection tip 3
  ///
  /// In en, this message translates to:
  /// **'A variety of photos can show different sides of who you are'**
  String get reviewRejectedHardTip3;

  /// Age display
  ///
  /// In en, this message translates to:
  /// **'{age}'**
  String profileAgeYears(int age);

  /// Seeking label
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get profileSeeking;

  /// Seeking men
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get profileSeekingMale;

  /// Seeking women
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get profileSeekingFemale;

  /// Seeking everyone
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get profileSeekingOther;

  /// Male gender
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get profileGenderMale;

  /// Female gender
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get profileGenderFemale;

  /// Other gender
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get profileGenderOther;

  /// Profile bio section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileSectionBio;

  /// Profile interests section title
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get profileSectionInterests;

  /// Profile Q&A section title
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get profileSectionQuestions;

  /// Empty bio placeholder
  ///
  /// In en, this message translates to:
  /// **'No bio yet'**
  String get profileNoBio;

  /// Empty interests placeholder
  ///
  /// In en, this message translates to:
  /// **'No interests set'**
  String get profileNoInterests;

  /// Empty questions placeholder
  ///
  /// In en, this message translates to:
  /// **'No questions answered'**
  String get profileNoQuestions;

  /// Profile load error message
  ///
  /// In en, this message translates to:
  /// **'Could not load profile'**
  String get profileLoadError;

  /// Edit profile page title
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileTitle;

  /// Photos section title
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get editProfileSectionPhotos;

  /// Basic info section title
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get editProfileSectionBasic;

  /// Seeking section title
  ///
  /// In en, this message translates to:
  /// **'Looking for'**
  String get editProfileSectionSeeking;

  /// Interests section title
  ///
  /// In en, this message translates to:
  /// **'Interests'**
  String get editProfileSectionInterests;

  /// Q&A section title
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get editProfileSectionQuestions;

  /// Display name field label
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get editProfileNameLabel;

  /// Bio field label
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get editProfileBioLabel;

  /// Bio input hint
  ///
  /// In en, this message translates to:
  /// **'Tell us about yourself...'**
  String get editProfileBioHint;

  /// Bio character limit helper
  ///
  /// In en, this message translates to:
  /// **'Optional, max {max} characters'**
  String editProfileBioHelper(int max);

  /// Seeking men
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get editProfileSeekingMale;

  /// Seeking women
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get editProfileSeekingFemale;

  /// Seeking everyone
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get editProfileSeekingOther;

  /// Photo change warning title
  ///
  /// In en, this message translates to:
  /// **'Photo Change Requires Review'**
  String get editProfilePhotoChangeTitle;

  /// Photo change warning body
  ///
  /// In en, this message translates to:
  /// **'After changing photos, we\'ll re-verify your identity.\nDuring review (1–3 business days), your current photos remain active for matching.'**
  String get editProfilePhotoChangeBody;

  /// Photo change confirm button
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get editProfilePhotoChangeContinue;

  /// Interests count
  ///
  /// In en, this message translates to:
  /// **'{count} interests selected'**
  String editProfileInterestsCount(int count);

  /// Edit interests button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfileInterestsEdit;

  /// Questions count
  ///
  /// In en, this message translates to:
  /// **'{count} questions answered'**
  String editProfileQuestionsCount(int count);

  /// Edit questions button
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfileQuestionsEdit;

  /// Unsaved changes dialog title
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editProfileUnsavedTitle;

  /// Unsaved changes dialog body
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. They\'ll be lost if you leave.'**
  String get editProfileUnsavedMessage;

  /// Discard changes confirm button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editProfileUnsavedDiscard;

  /// Save success message
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get editProfileSaved;

  /// Save failed message
  ///
  /// In en, this message translates to:
  /// **'Save failed. Please try again.'**
  String get editProfileSaveFailed;

  /// Photo review pending banner
  ///
  /// In en, this message translates to:
  /// **'Photos under review (1–3 days) — current photos remain active for matching'**
  String get editProfilePhotoPendingBanner;

  /// Account section title
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// Privacy section title
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// Preferences section title
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// Support section title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// Phone number option
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get settingsPhone;

  /// Push notifications option
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get settingsNotifications;

  /// Traditional Chinese option
  ///
  /// In en, this message translates to:
  /// **'Traditional Chinese'**
  String get settingsLanguageZh;

  /// English option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// Privacy policy option
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacy;

  /// Terms of service option
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTerms;

  /// Contact support option
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get settingsContactUs;

  /// FAQ option
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get settingsFaq;

  /// Report a problem option
  ///
  /// In en, this message translates to:
  /// **'Report a Problem'**
  String get settingsReport;

  /// Version option
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// Log out dialog title
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogoutTitle;

  /// Log out dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of this device?'**
  String get settingsLogoutMessage;

  /// Log out confirm button
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get settingsLogoutConfirm;

  /// Account security option
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get settingsAccountSecurity;

  /// Account security page title
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurityTitle;

  /// Account security page body
  ///
  /// In en, this message translates to:
  /// **'The following actions will permanently affect your account. Please proceed carefully.'**
  String get accountSecurityBody;

  /// Delete account section title
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountSecurityDeleteTitle;

  /// Delete account description
  ///
  /// In en, this message translates to:
  /// **'Deleting your account will permanently remove all your data, matches, and messages. This cannot be undone.\nIf you just need a break, consider pausing your account instead.'**
  String get accountSecurityDeleteDesc;

  /// Delete account button
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete Account'**
  String get accountSecurityDeleteButton;

  /// Edit photos page title
  ///
  /// In en, this message translates to:
  /// **'Manage Photos'**
  String get editPhotosTitle;

  /// Edit photos page subtitle
  ///
  /// In en, this message translates to:
  /// **'Long-press to reorder. Min 2, max 9 photos.'**
  String get editPhotosSubtitle;

  /// Edit photos page uploading text
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get editPhotosUploading;

  /// Photos submitted success message
  ///
  /// In en, this message translates to:
  /// **'Photos submitted for review. Matching continues in the meantime.'**
  String get editPhotosSuccessMessage;

  /// Photo upload failed message
  ///
  /// In en, this message translates to:
  /// **'Upload failed. Please try again.'**
  String get editPhotosUploadFailed;

  /// Pending status text shown below manage photos button
  ///
  /// In en, this message translates to:
  /// **'Photos under review (1–3 days)\nCurrent photos remain active for matching'**
  String get editPhotosPendingStatus;

  /// Photo re-verify page title
  ///
  /// In en, this message translates to:
  /// **'Verification Photos'**
  String get editReverifyTitle;

  /// Photo re-verify page subtitle
  ///
  /// In en, this message translates to:
  /// **'We need 2 quick photos to confirm it\'s you before submitting your new photos for review.\nVerification photos are for our review team only and will never be shown publicly.'**
  String get editReverifySubtitle;

  /// Photo re-verify submit button
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get editReverifySubmit;

  /// Photo re-verify submitting text
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get editReverifyUploading;

  /// Photo re-verify success message
  ///
  /// In en, this message translates to:
  /// **'Photo update submitted for review. Matching continues in the meantime.'**
  String get editReverifySuccess;

  /// Photo re-verify failed message
  ///
  /// In en, this message translates to:
  /// **'Submission failed. Please try again.'**
  String get editReverifyFailed;

  /// Beta apply info page subtitle
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Confirm or update your basic info.'**
  String get betaApplyInfoSubtitle;

  /// Beta apply bio page subtitle
  ///
  /// In en, this message translates to:
  /// **'Here\'s your bio from the beta — feel free to edit it.'**
  String get betaApplyBioSubtitle;

  /// Beta photos locked title
  ///
  /// In en, this message translates to:
  /// **'Photos Locked'**
  String get betaApplyPhotosLockedTitle;

  /// Beta photos locked body text
  ///
  /// In en, this message translates to:
  /// **'To confirm your identity, photos can\'t be changed right now. You can update them in your profile after joining the app.'**
  String get betaApplyPhotosLockedBody;
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
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
