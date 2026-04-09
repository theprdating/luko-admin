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
  /// **'Congratulations! You\'ve passed the PR Dating review.\nOne last step — link your phone number to finish setting up your account.'**
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
  /// **'About You'**
  String get applyBioTitle;

  /// Apply Step 4 subtitle
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about yourself (optional)'**
  String get applyBioSubtitle;

  /// Bio input placeholder
  ///
  /// In en, this message translates to:
  /// **'Share your interests, lifestyle, or anything you\'d like others to know...'**
  String get applyBioHint;

  /// Bio character limit helper
  ///
  /// In en, this message translates to:
  /// **'Up to 150 characters'**
  String get applyBioHelper;

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
  String get reviewRejectedTitleSoft;

  /// Rejected screen body — hard rejection
  ///
  /// In en, this message translates to:
  /// **'Thank you for your application. To ensure every member has the best possible matching experience, we have basic quality standards for application photos.\nHere are some tips that might be helpful:'**
  String get reviewRejectedBodySoft;

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

  /// Edit profile button
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditButton;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Logout button
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
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
