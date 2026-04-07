// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PR Dating';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonNext => 'Next';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Something went wrong. Please try again.';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonRetry => 'Retry';

  @override
  String get authWelcomeTitle => 'Date people who take care of themselves.';

  @override
  String get authWelcomeSubtitle =>
      'Apply to join PR Dating. We review every profile.';

  @override
  String get welcomeBadge => 'BY APPLICATION';

  @override
  String get welcomeHeadline => 'You\'re serious. So are they.';

  @override
  String get welcomeBody => 'Every account is human-reviewed.';

  @override
  String get authApplyButton => 'Apply to Join';

  @override
  String get authLoginButton => 'Already have an account? Sign In';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authContinueWithApple => 'Continue with Apple';

  @override
  String authConsentSuffix(String privacy) {
    return ' and $privacy';
  }

  @override
  String get approvedGateBadge => 'REVIEW COMPLETE';

  @override
  String get approvedGateTitle => 'You\'re In';

  @override
  String get approvedGateBody =>
      'Congratulations! You\'ve passed the PR Dating review.\nOne last step — link your phone number to finish setting up your account.';

  @override
  String get approvedGateBodyTop =>
      'Congratulations! You\'ve passed the PR Dating review.\nAs a founding member (top 85%), you\'ll have free access to all features for life.\nOne last step — link your phone number to finish setting up your account.';

  @override
  String get approvedGateBodyStandard =>
      'Congratulations! You\'ve passed the PR Dating review.\nYou\'ll enjoy a 5-day free trial, after which you can subscribe to continue.\nOne last step — link your phone number to finish setting up your account.';

  @override
  String get approvedGateTierLabelTop => 'Founding Member · Free Forever';

  @override
  String get approvedGateTierLabelStandard => '5-Day Free Trial';

  @override
  String get approvedGateCta => 'Link Phone Number';

  @override
  String get approvedGateNote =>
      'Your number is only used for verification and won\'t appear on your profile';

  @override
  String get verifyPhoneTitle => 'Link Your Phone';

  @override
  String get verifyPhoneSubtitle =>
      'One last step! Link your phone number to verify your identity.';

  @override
  String get verifyPhoneUniqueNote =>
      'Each phone number can only be linked to one account';

  @override
  String get authPhoneTitle => 'Verify Your Phone';

  @override
  String get authPhoneSubtitle =>
      'Enter your phone number and we\'ll send you a verification code';

  @override
  String get authPhoneLabel => 'Phone Number';

  @override
  String get authPhoneHint => 'Enter your phone number';

  @override
  String get authSendCode => 'Send Code';

  @override
  String get authOtpTitle => 'Enter Verification Code';

  @override
  String authOtpSentTo(String phone) {
    return 'Code sent to $phone';
  }

  @override
  String get authOtpVerify => 'Verify';

  @override
  String get authOtpResend => 'Resend Code';

  @override
  String authOtpResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authOtpInvalid => 'Invalid verification code. Please try again.';

  @override
  String get authOtpExpired => 'Code expired. Please request a new one.';

  @override
  String get authPhoneInvalid => 'Please enter a valid phone number';

  @override
  String get phoneCountryUnsupported =>
      'This country/region is not yet supported. Stay tuned!';

  @override
  String get authLoginTitle => 'Welcome back';

  @override
  String get authLoginSubtitle => 'Enter your phone number to sign in';

  @override
  String applyStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get applyInfoTitle => 'Basic Info';

  @override
  String get applyInfoSubtitle => 'Let others know you';

  @override
  String get applyNameLabel => 'Display Name';

  @override
  String get applyNameHint => 'Enter your name';

  @override
  String get applyNameHelper => 'Up to 20 characters';

  @override
  String get applyNameEmpty => 'Please enter a display name';

  @override
  String get applyBirthDateLabel => 'Date of Birth';

  @override
  String get applyBirthDateHint => 'Select your birthday';

  @override
  String get applyBirthDateEmpty => 'Please select your date of birth';

  @override
  String get applyAgeError => 'You must be at least 18 years old to apply';

  @override
  String get applyGenderLabel => 'Gender';

  @override
  String get applyGenderMale => 'Male';

  @override
  String get applyGenderFemale => 'Female';

  @override
  String get applyGenderOther => 'Other';

  @override
  String get applyGenderEmpty => 'Please select a gender';

  @override
  String get applySeekingLabel => 'Interested in';

  @override
  String get applySeekingMen => 'Men';

  @override
  String get applySeekingWomen => 'Women';

  @override
  String get applySeekingEveryone => 'Everyone';

  @override
  String get applySeekingEmpty => 'Please select who you\'re interested in';

  @override
  String get applyPhotosTitle => 'Add Photos';

  @override
  String get applyPhotosSubtitle =>
      'Upload 2–9 recent, clear photos that show the real you. Long-press to reorder.';

  @override
  String get applyPhotosAddPhoto => 'Add Photo';

  @override
  String get applyPhotosFromGallery => 'Choose from Gallery';

  @override
  String get applyPhotosFromCamera => 'Take Photo';

  @override
  String get applyPhotosUploading => 'Uploading photos...';

  @override
  String applyPhotosSelected(int count) {
    return '$count photo(s) selected';
  }

  @override
  String applyPhotosMinRequired(int min) {
    return 'At least $min photos required';
  }

  @override
  String get applyPhotosLimitedHint =>
      'Limited access — some photos are hidden';

  @override
  String get applyPhotosManageAccess => 'Add Photos';

  @override
  String get permissionPhotoTitle => 'Photo Library Access Required';

  @override
  String get permissionPhotoBody =>
      'PR Dating needs access to your photo library to upload photos. Please enable it in Settings.';

  @override
  String get permissionCameraTitle => 'Camera Access Required';

  @override
  String get permissionCameraBody =>
      'PR Dating needs camera access to take photos. Please enable it in Settings.';

  @override
  String get permissionOpenSettings => 'Open Settings';

  @override
  String get applyVerifyIntroTitle => 'Verify Your Identity';

  @override
  String get applyVerifyIntroBody =>
      'To keep our community safe, we need to confirm you\'re a real person.\nVerification photos are only visible to our review team and will never be shown publicly.';

  @override
  String get applyVerifyIntroStep1 => 'Front-facing photo';

  @override
  String get applyVerifyIntroStep2 => 'Left profile photo';

  @override
  String get applyVerifyIntroStep3 => '2 random actions';

  @override
  String get applyVerifyStartButton => 'Start Verification';

  @override
  String get applyVerifyStepFrontTitle => 'Front-facing photo';

  @override
  String get applyVerifyStepFrontHint =>
      'Face the camera with a natural expression';

  @override
  String get applyVerifyStepSideTitle => 'Left profile photo';

  @override
  String get applyVerifyStepSideHint =>
      'Turn your head to the left so your profile is clearly visible';

  @override
  String get applyVerifyStepActionTitle => 'Perform the action';

  @override
  String get applyVerifyStepActionHint =>
      'Face the camera and perform the following action:';

  @override
  String get applyVerifyTakePhoto => 'Take Photo';

  @override
  String get applyVerifyRetake => 'Retake';

  @override
  String get applyVerifyNextStep => 'Continue';

  @override
  String get applyVerifyDone => 'Done';

  @override
  String get applyVerifyUploading => 'Uploading verification photos...';

  @override
  String get verifyActionSmile => 'Smile at the camera';

  @override
  String get verifyActionOpenMouth => 'Open your mouth';

  @override
  String get verifyActionRaiseRightHand => 'Raise your right hand';

  @override
  String get verifyActionRaiseLeftHand => 'Raise your left hand';

  @override
  String get verifyActionWave => 'Wave at the camera';

  @override
  String get verifyActionThumbsUp => 'Give a thumbs up';

  @override
  String get verifyActionTouchNose => 'Touch your nose with your finger';

  @override
  String get verifyActionTiltHead =>
      'Tilt your head toward your right shoulder';

  @override
  String get verifyActionShowSix => 'Show the number 6 with your hand';

  @override
  String get verifyActionShowSeven => 'Show the number 7 with your hand';

  @override
  String get verifyActionShowEight => 'Show the number 8 with your hand';

  @override
  String get verifyActionShowNine => 'Show the number 9 with your hand';

  @override
  String get applyBioTitle => 'About You';

  @override
  String get applyBioSubtitle => 'Tell us a little about yourself (optional)';

  @override
  String get applyBioHint =>
      'Share your interests, lifestyle, or anything you\'d like others to know...';

  @override
  String get applyBioHelper => 'Up to 150 characters';

  @override
  String get applyConfirmTitle => 'Review & Submit';

  @override
  String get applyConfirmSubtitle =>
      'Please review your details before submitting';

  @override
  String get applyConfirmNoBio => '(Not filled in)';

  @override
  String get applyConfirmSubmitting => 'Submitting application...';

  @override
  String get applySubmitButton => 'Submit Application';

  @override
  String get applyConfirmReviewInfoTitle => 'Review Info';

  @override
  String get applyConfirmReviewDays =>
      'Timeline: Usually completed within 1–3 business days';

  @override
  String get applyConfirmReviewNotify =>
      'Notification: We\'ll notify you via app push notification and email';

  @override
  String get applyTermsAgree =>
      'I agree to the Terms of Service and Privacy Policy';

  @override
  String get reviewPendingTitle => 'Application Submitted';

  @override
  String get reviewPendingBody =>
      'Our team will complete the review within 1–3 business days. You\'ll be notified via app push notification and email.';

  @override
  String get reviewPendingStep1Label => 'Submitted';

  @override
  String get reviewPendingStep1Sub => 'Your profile is queued for review';

  @override
  String get reviewPendingStep2Label => 'Under Review';

  @override
  String get reviewPendingStep2Sub =>
      'Usually completed within 1–3 business days';

  @override
  String get reviewPendingStep3Label => 'Notification';

  @override
  String get reviewPendingStep3Sub =>
      'Result sent via app push notification and email';

  @override
  String get reviewRejectedTitle => 'Not Quite Yet';

  @override
  String get reviewRejectedBody =>
      'Your profile doesn\'t meet our community standards at this time. You\'re welcome to reapply in 30 days.';

  @override
  String get reviewRejectedTitleSoft => 'Thank You for Applying';

  @override
  String get reviewRejectedBodySoft =>
      'Thanks for applying to PR Dating.\nWe reviewed your application carefully and are sorry that we can\'t approve it at this time.\nHere are some general tips that might be helpful:';

  @override
  String get reviewRejectedTitlePotential => 'Almost There!';

  @override
  String get reviewRejectedBodyPotential =>
      'You\'re close to our standard — just not quite there yet.\nTry these tips before reapplying:';

  @override
  String get reviewAdminFeedbackTitle => 'Review Feedback';

  @override
  String get reviewRejectedTip1 =>
      'Shoot near a window or outdoors in natural light';

  @override
  String get reviewRejectedTip2 =>
      'Keep your face clear — avoid heavy filters or editing';

  @override
  String get reviewRejectedTip3 =>
      'Add a lifestyle photo that shows your personality';

  @override
  String get reviewReapplyButton => 'Reapply Now';

  @override
  String reviewReapplyAttemptsLeft(int remaining) {
    return '$remaining attempt(s) remaining';
  }

  @override
  String get reviewReapplyExhaustedTitle => 'No More Attempts';

  @override
  String get reviewReapplyExhaustedBody =>
      'Each account is limited to 3 application attempts. This account has reached the limit. Thank you for your interest in PR Dating.';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverEmptyTitle => 'You\'ve seen everyone';

  @override
  String get discoverEmptySubtitle => 'Check back later for new profiles.';

  @override
  String get matchTitle => 'Matches';

  @override
  String get matchNewMatch => 'It\'s a Match!';

  @override
  String get chatTitle => 'Messages';

  @override
  String get chatEmptyTitle => 'No messages yet';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEditButton => 'Edit Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLogout => 'Sign Out';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String get reportTitle => 'Report Profile';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get blockUser => 'Block User';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingGetStarted => 'I\'m Ready';

  @override
  String get onboarding1Title => 'You deserve\nsomeone like you.';

  @override
  String get onboarding1Body =>
      'Intentionality shows.\n\nThe care someone puts into how they present themselves\n\nThat\'s how they\'ll show up for you too.';

  @override
  String get onboarding2Title => 'We screen\nfor intention.';

  @override
  String get onboarding2Body =>
      'Not algorithms. Real people.\n\nEvery account on PR Dating is reviewed by hand — because attitude can\'t be automated.\n';

  @override
  String get onboarding3Title => 'Good connections\naren\'t luck.';

  @override
  String get onboarding3Body =>
      'No more endless scrolling.\n\nEvery day, PR Dating curates a small circle of people — each one genuinely worth your time.\n\nYou take yourself seriously.\nYou deserve someone who does too.';

  @override
  String get onboarding1Quote1 =>
      'These are the photos they handpicked to show you.\n Imagine what meeting them looks like.';

  @override
  String get onboarding1Quote2 => 'Am I asking for too much?';

  @override
  String get onboarding1Quote3 =>
      'I spent an hour getting ready and they showed up like…';

  @override
  String get onboarding1Quote4 => 'Why does nobody put in effort anymore?';

  @override
  String get onboarding1Quote5 =>
      'Their photos look like they couldn\'t care less';

  @override
  String get onboarding1Quote6 =>
      'Am I the only one who actually cares about showing up?';

  @override
  String get onboarding2Quote1 => 'How do I even know if he\'s real?';

  @override
  String get onboarding2Quote2 => 'Fake photos, fake info — all of it';

  @override
  String get onboarding2Quote3 => 'It feels like I\'m talking to a bot';

  @override
  String get onboarding2Quote4 =>
      'I can\'t tell if there\'s a real person on the other side';

  @override
  String get onboarding2Quote5 =>
      'Chatted for weeks before realizing it was a fake account';

  @override
  String get onboarding2Quote6 => 'We had plans and then they just vanished…';

  @override
  String get onboarding3Quote1 => 'Scrolled forever and nobody feels right';

  @override
  String get onboarding3Quote2 => 'I\'m so tired of swiping';

  @override
  String get onboarding3Quote3 =>
      'After a while I forgot what I was even looking for';

  @override
  String get onboarding3Quote4 => 'Is this even working?';

  @override
  String get onboarding3Quote5 =>
      '99+ messages a day and I can\'t connect with anyone';

  @override
  String get onboarding3Quote6 => 'There has to be a better way than this…';

  @override
  String get termsUpdateTitle => 'We\'ve Updated Our Terms';

  @override
  String get termsUpdateSubtitle =>
      'We\'ve updated our Terms of Service and Privacy Policy. Please review them to continue using PR Dating.';

  @override
  String get termsUpdateAccept => 'I\'ve Read and Agree to the New Terms';

  @override
  String get termsUpdateDecline => 'Decline and Sign Out';

  @override
  String get termsUpdateAccepting => 'Updating...';

  @override
  String get termsPageTitle => 'Terms of Service';

  @override
  String get privacyPageTitle => 'Privacy Policy';

  @override
  String get termsLabel => 'Terms of Service';

  @override
  String get privacyLabel => 'Privacy Policy';

  @override
  String get termsReadFull => 'Read full Terms of Service';

  @override
  String get privacyReadFull => 'Read full Privacy Policy';

  @override
  String get termsAgreePrefix => 'I agree to the ';

  @override
  String get termsAgreeAnd => ' and ';

  @override
  String get authConsentPrefix => 'By continuing, you agree to our ';

  @override
  String get reviewRejectedHardTip1 =>
      'Authentic photos that show your true self tend to resonate best';

  @override
  String get reviewRejectedHardTip2 =>
      'A personal bio helps others get to know you in a more complete way';

  @override
  String get reviewRejectedHardTip3 =>
      'A variety of photos can show different sides of who you are';
}
