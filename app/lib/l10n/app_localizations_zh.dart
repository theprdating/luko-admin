// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'PR Dating';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '儲存';

  @override
  String get commonNext => '下一步';

  @override
  String get commonBack => '返回';

  @override
  String get commonLoading => '載入中...';

  @override
  String get commonSaving => '儲存中...';

  @override
  String get commonError => '發生錯誤，請再試一次。';

  @override
  String get commonSkip => '略過';

  @override
  String get commonRetry => '重試';

  @override
  String get authWelcomeTitle => '與認真打理自己的人相遇。';

  @override
  String get authWelcomeSubtitle => '申請加入 PR Dating，每一個帳號都經過人工審核。';

  @override
  String get welcomeBadge => '申請制';

  @override
  String get welcomeHeadline => '你在認真，他們也是。';

  @override
  String get welcomeBody => '每個帳號都由真人審核。';

  @override
  String get authApplyButton => '申請加入';

  @override
  String get authLoginButton => '已有帳號，直接登入';

  @override
  String get authContinueWithGoogle => '使用 Google 繼續';

  @override
  String get authContinueWithApple => '使用 Apple 繼續';

  @override
  String get welcomeEmailLoginButton => '以 Email 登入';

  @override
  String get emailLoginTitle => 'Email 登入';

  @override
  String get emailLoginSubtitle => '此入口供已有帳號的封測用戶使用。\n輸入註冊信箱，我們將寄送登入連結。';

  @override
  String get emailLoginLabel => '電子信箱';

  @override
  String get emailLoginSendLink => '寄送登入連結';

  @override
  String get emailLoginResend => '重新發送';

  @override
  String emailLoginResendIn(int seconds) {
    return '$seconds 秒後可重新發送';
  }

  @override
  String get emailLoginOAuthHint =>
      '尚未申請帳號？請返回使用 Google 或 Apple 進行申請。\n曾以 Google / Apple 登入的用戶請返回使用對應按鈕。';

  @override
  String get betaAccountEmailInvalid => '請輸入有效的電子信箱';

  @override
  String get betaAccountSentTitle => '登入連結已發送';

  @override
  String betaAccountSentTo(String email) {
    return '已寄至 $email';
  }

  @override
  String get betaAccountSentBody => '請查收信箱，點擊連結後 App 將自動開啟並完成登入。\n連結 60 分鐘內有效。';

  @override
  String authConsentSuffix(String privacy) {
    return ' 與 $privacy';
  }

  @override
  String get approvedGateBadge => '審核完成';

  @override
  String get approvedGateTitle => '申請通過';

  @override
  String get approvedGateBody =>
      '恭喜！你已通過 PR Dating 的資格審核，歡迎加入。\n接下來，綁定手機號碼以完成帳號設置。';

  @override
  String get approvedGateBodyTop =>
      '您的形象符合 PR Dating 的精選標準，歡迎加入。\n你可終生免費使用所有功能。\n接下來，綁定手機號碼以完成帳號設置。';

  @override
  String get approvedGateBodyStandard =>
      '您通過了我們的基本審核，期待看見您在社群中的表現。\n你可享有 5 天免費體驗，之後可訂閱方案繼續使用。\n接下來，綁定手機號碼以完成帳號設置。';

  @override
  String get approvedGateTierLabelTop => '精選成員 · 終生免費';

  @override
  String get approvedGateTierLabelStandard => '5 天免費體驗';

  @override
  String get approvedGateCta => '綁定手機號碼';

  @override
  String get approvedGateNote => '此號碼僅用於帳號驗證，不會顯示於個人檔案';

  @override
  String get verifyPhoneTitle => '綁定手機號碼';

  @override
  String get verifyPhoneSubtitle => '最後一步！綁定手機號碼以確認你的身份。';

  @override
  String get verifyPhoneUniqueNote => '每個手機號碼只能綁定一個帳號';

  @override
  String get authPhoneTitle => '驗證手機號碼';

  @override
  String get authPhoneSubtitle => '輸入你的手機號碼，我們將發送驗證碼簡訊';

  @override
  String get authPhoneLabel => '手機號碼';

  @override
  String get authPhoneHint => '09XX XXX XXX';

  @override
  String get authSendCode => '發送驗證碼';

  @override
  String get authOtpTitle => '輸入驗證碼';

  @override
  String authOtpSentTo(String phone) {
    return '驗證碼已發送至 $phone';
  }

  @override
  String get authOtpVerify => '驗證';

  @override
  String get authOtpResend => '重新發送';

  @override
  String authOtpResendIn(int seconds) {
    return '$seconds 秒後可重新發送';
  }

  @override
  String get authOtpInvalid => '驗證碼不正確，請重新輸入';

  @override
  String get authOtpExpired => '驗證碼已過期，請重新發送';

  @override
  String get authPhoneInvalid => '請輸入正確的手機號碼';

  @override
  String get phoneCountryUnsupported => '目前尚不支援此國家/地區的號碼，敬請期待';

  @override
  String get authLoginTitle => '歡迎回來';

  @override
  String get authLoginSubtitle => '輸入手機號碼以驗證身份';

  @override
  String applyStep(int current, int total) {
    return '$current / $total';
  }

  @override
  String get applyInfoTitle => '基本資料';

  @override
  String get applyInfoSubtitle => '讓大家認識你';

  @override
  String get applyNameLabel => '顯示名稱';

  @override
  String get applyNameHint => '輸入你的名稱';

  @override
  String get applyNameHelper => '最多 20 個字';

  @override
  String get applyNameEmpty => '請輸入顯示名稱';

  @override
  String get applyBirthDateLabel => '生日';

  @override
  String get applyBirthDateHint => '選擇你的生日';

  @override
  String get applyBirthDateEmpty => '請選擇生日';

  @override
  String get applyAgeError => '需年滿 18 歲才能申請';

  @override
  String get applyGenderLabel => '性別';

  @override
  String get applyGenderMale => '男';

  @override
  String get applyGenderFemale => '女';

  @override
  String get applyGenderOther => '其他';

  @override
  String get applyGenderEmpty => '請選擇性別';

  @override
  String get applySeekingLabel => '想認識';

  @override
  String get applySeekingMen => '男性';

  @override
  String get applySeekingWomen => '女性';

  @override
  String get applySeekingEveryone => '都可以';

  @override
  String get applySeekingEmpty => '請選擇想認識的對象';

  @override
  String get applyPhotosTitle => '上傳照片';

  @override
  String get applyPhotosSubtitle => '上傳 2–9 張近期清晰照片，展現真實的你。長按照片可調整順序。';

  @override
  String get applyPhotosAddPhoto => '新增照片';

  @override
  String get applyPhotosFromGallery => '從相簿選取';

  @override
  String get applyPhotosFromCamera => '拍照';

  @override
  String get applyPhotosUploading => '上傳照片中...';

  @override
  String applyPhotosSelected(int count) {
    return '已選取 $count 張照片';
  }

  @override
  String applyPhotosMinRequired(int min) {
    return '至少需要 $min 張照片';
  }

  @override
  String get applyPhotosLimitedHint => '目前為有限存取，部分照片無法顯示';

  @override
  String get applyPhotosManageAccess => '新增照片';

  @override
  String applyPhotosExistingHint(int count) {
    return '已有 $count 張上傳照片，可直接繼續，或重新選取替換';
  }

  @override
  String get permissionPhotoTitle => '需要相簿權限';

  @override
  String get permissionPhotoBody => 'PR Dating 需要存取您的相簿才能上傳照片。請前往設定開啟相簿權限。';

  @override
  String get permissionCameraTitle => '需要相機權限';

  @override
  String get permissionCameraBody => 'PR Dating 需要存取相機才能拍照。請前往設定開啟相機權限。';

  @override
  String get permissionOpenSettings => '前往設定';

  @override
  String get applyVerifyIntroTitle => '真人認證';

  @override
  String get applyVerifyIntroBody =>
      '為了保護社群安全，我們需要確認你是真實的人。\n認證照片僅供審核人員查閱，不會對外顯示。';

  @override
  String get applyVerifyIntroStep1 => '正面照';

  @override
  String get applyVerifyIntroStep2 => '左側臉照';

  @override
  String get applyVerifyIntroStep3 => '隨機動作 ×2';

  @override
  String get applyVerifyStartButton => '開始認證';

  @override
  String get applyVerifyStepFrontTitle => '拍正面照';

  @override
  String get applyVerifyStepFrontHint => '面對鏡頭，保持自然表情';

  @override
  String get applyVerifyStepSideTitle => '拍左側臉照';

  @override
  String get applyVerifyStepSideHint => '頭轉向左側，讓側臉清楚入鏡';

  @override
  String get applyVerifyStepActionTitle => '完成動作';

  @override
  String get applyVerifyStepActionHint => '面對鏡頭，做出以下動作：';

  @override
  String get applyVerifyTakePhoto => '拍照';

  @override
  String get applyVerifyRetake => '重拍';

  @override
  String get applyVerifyNextStep => '繼續';

  @override
  String get applyVerifyDone => '完成';

  @override
  String get applyVerifyUploading => '上傳認證照片中...';

  @override
  String get verifyActionSmile => '對鏡頭微笑';

  @override
  String get verifyActionOpenMouth => '張開嘴巴';

  @override
  String get verifyActionRaiseRightHand => '舉起右手';

  @override
  String get verifyActionRaiseLeftHand => '舉起左手';

  @override
  String get verifyActionWave => '向鏡頭揮手';

  @override
  String get verifyActionThumbsUp => '比讚';

  @override
  String get verifyActionTouchNose => '用手指摸鼻子';

  @override
  String get verifyActionTiltHead => '頭歪向右肩';

  @override
  String get verifyActionShowSix => '用手比出數字 6';

  @override
  String get verifyActionShowSeven => '用手比出數字 7';

  @override
  String get verifyActionShowEight => '用手比出數字 8';

  @override
  String get verifyActionShowNine => '用手比出數字 9';

  @override
  String get applyInterestsTitle => '你喜歡什麼？';

  @override
  String applyInterestsSubtitle(int min) {
    return '至少選 $min 項，幫助更好的配對';
  }

  @override
  String applyInterestsSelected(int count) {
    return '已選 $count';
  }

  @override
  String applyInterestsShortfall(int remaining) {
    return '還差 $remaining 項就可以繼續';
  }

  @override
  String applyInterestsCategoryMax(int max) {
    return '此類別最多選 $max 項';
  }

  @override
  String get applyInterestsAddCustomTitle => '新增自訂興趣';

  @override
  String get applyInterestsAddCustomHint => '輸入興趣名稱';

  @override
  String get applyInterestsAddButton => '新增';

  @override
  String get applyQuestionsTitle => '讓對方更了解你';

  @override
  String get applyQuestionsSubtitle => '至少回答 1 題，沒有標準答案';

  @override
  String applyQuestionsAnswered(int count) {
    return '已答 $count 題';
  }

  @override
  String get applyQuestionsMinRequired => '回答至少 1 題再繼續';

  @override
  String get applyQuestionsAnswerHint => '分享你的想法...';

  @override
  String get applyQuestionsAnswerSave => '儲存';

  @override
  String get applyQuestionsAnswerClear => '清除回答';

  @override
  String get applyBioTitle => '自我介紹';

  @override
  String get applyBioSubtitle => '介紹一下自己（選填）';

  @override
  String get applyBioHint => '分享你的興趣、生活方式或任何想說的話...';

  @override
  String get applyBioHelper => '最多 500 字';

  @override
  String get applyLeaveDialogTitle => '確定要離開？';

  @override
  String get applyLeaveDialogBody => '離開將會登出，下次重新登入後可繼續申請。';

  @override
  String get applyLeaveDialogConfirm => '離開並登出';

  @override
  String get applyConfirmTitle => '確認送出';

  @override
  String get applyConfirmSubtitle => '請確認以下資料後送出申請';

  @override
  String get applyConfirmNoBio => '（未填寫）';

  @override
  String get applyConfirmSubmitting => '送出申請中...';

  @override
  String get applySubmitButton => '送出申請';

  @override
  String get applyConfirmReviewInfoTitle => '審核說明';

  @override
  String get applyConfirmReviewDays => '審核時間：通常在 1–3 個工作天內完成';

  @override
  String get applyConfirmReviewNotify => '通知方式：APP 推播通知及 Email 雙管道告知你審核結果';

  @override
  String get applyTermsAgree => '我同意 服務條款 及 隱私權政策';

  @override
  String get reviewPendingTitle => '申請已送出';

  @override
  String get reviewPendingBody =>
      '我們的團隊將在 1–3 個工作天內完成審核，結果將透過 APP 推播通知及 Email 告知你。';

  @override
  String get reviewPendingStep1Label => '申請已送出';

  @override
  String get reviewPendingStep1Sub => '資料已收到，等待排程審核';

  @override
  String get reviewPendingStep2Label => '審核中';

  @override
  String get reviewPendingStep2Sub => '通常在 1–3 個工作天內完成';

  @override
  String get reviewPendingStep3Label => '通知發送';

  @override
  String get reviewPendingStep3Sub => '結果將透過 APP 推播通知及 Email 通知你';

  @override
  String get reviewRejectedTitle => '暫時未能通過';

  @override
  String get reviewRejectedBody => '您目前暫時未符合我們的社群標準。歡迎在 30 天後重新申請。';

  @override
  String get reviewRejectedTitleHard => '感謝你的申請';

  @override
  String get reviewRejectedBodyHard =>
      '感謝你的申請。為確保每位成員都能擁有最佳的配對體驗，我們對申請照片有基本的品質要求。\n以下是一些建議，希望對你有所幫助：';

  @override
  String get reviewRejectedTitlePotential => '差一點點！';

  @override
  String get reviewRejectedBodyPotential =>
      '感謝你的申請。為確保每位成員都能擁有最佳的配對體驗，我們對申請照片有基本的品質要求。\n你與通過標準的距離不遠，試試這些建議：';

  @override
  String get reviewAdminFeedbackTitle => '審核建議';

  @override
  String get reviewRejectedTagPhotoBlurry => '建議提供清晰、光線充足的照片';

  @override
  String get reviewRejectedTagMessyBackground => '建議在整潔或有質感的空間拍攝';

  @override
  String get reviewRejectedTagCasualStyle => '建議展現經過打理的穿搭與造型';

  @override
  String get reviewRejectedTagFaceUnclear => '建議確保主照片能清楚看見臉部';

  @override
  String get reviewRejectedTagTooFewPhotos => '建議提供至少 3 張不同角度的照片';

  @override
  String get reviewRejectedTip1 => '靠近窗戶或在戶外自然光下拍攝';

  @override
  String get reviewRejectedTip2 => '臉部清晰，避免過度修圖或濾鏡';

  @override
  String get reviewRejectedTip3 => '加入一張展現你個性的生活照';

  @override
  String get reviewReapplyButton => '重新申請';

  @override
  String reviewReapplyAttemptsLeft(int remaining) {
    return '還剩 $remaining 次申請機會';
  }

  @override
  String get reviewReapplyExhaustedTitle => '申請機會已用完';

  @override
  String get reviewReapplyExhaustedBody =>
      '每個帳號最多可申請 3 次，此帳號已達上限。感謝你對 PR Dating 的支持。';

  @override
  String get reviewExhaustedSignOut => '登出';

  @override
  String get reviewExhaustedContactUs => '如有任何疑問，請聯繫我們';

  @override
  String get reviewExhaustedEmailCopied => '信箱已複製';

  @override
  String get reviewDeleteRequestButton => '申請刪除帳號';

  @override
  String get reviewDeleteDialogTitle => '確認刪除帳號？';

  @override
  String get reviewDeleteDialogBody =>
      '你的帳號資料將於 90 天後永久清除。這段期間，你可以登入並取消此申請。90 天後你可以以全新身份重新申請。';

  @override
  String get reviewDeleteDialogConfirm => '確認申請';

  @override
  String get reviewDeleteDialogCancel => '取消';

  @override
  String get pendingDeletionTitle => '帳號刪除已排程';

  @override
  String get pendingDeletionBody => '你的所有資料將於以下日期永久清除。屆時你可以以全新身份重新申請。';

  @override
  String get pendingDeletionDateLabel => '預計刪除日期';

  @override
  String get pendingDeletionCancelButton => '取消刪除申請';

  @override
  String get pendingDeletionSignOut => '登出';

  @override
  String get pendingDeletionCancelSuccess => '刪除申請已取消';

  @override
  String get reviewPendingContactUs => '如有任何問題，歡迎聯繫我們';

  @override
  String get reviewPendingEmailCopied => '信箱已複製';

  @override
  String get discoverTitle => '探索';

  @override
  String get discoverEmptyTitle => '已經看完所有人了';

  @override
  String get discoverEmptySubtitle => '稍後再回來看看新的用戶吧。';

  @override
  String get discoverMidnightTitle => '今日精選準備中';

  @override
  String discoverMidnightSubtitle(String localTime) {
    return 'PR Dating 每天台灣時間凌晨 12:00 精選今日配對\n（你當地時間 $localTime）';
  }

  @override
  String get discoverMidnightCountdownLabel => '距離下次刷新';

  @override
  String get matchTitle => '配對';

  @override
  String get matchNewMatch => '互相喜歡！';

  @override
  String get chatTitle => '訊息';

  @override
  String get chatEmptyTitle => '還沒有任何訊息';

  @override
  String get profileTitle => '個人檔案';

  @override
  String get profileEditButton => '編輯資料';

  @override
  String get settingsTitle => '設定';

  @override
  String get settingsLanguage => '語言';

  @override
  String get settingsLogout => '登出';

  @override
  String get settingsDeleteAccount => '刪除帳號';

  @override
  String get reportTitle => '檢舉此用戶';

  @override
  String get reportSubmit => '送出檢舉';

  @override
  String get blockUser => '封鎖用戶';

  @override
  String get onboardingSkip => '略過';

  @override
  String get onboardingContinue => '繼續';

  @override
  String get onboardingGetStarted => '我準備好了';

  @override
  String get onboarding1Title => '打理好自己的人，\n你值得遇見';

  @override
  String get onboarding1Body => '細心，是看得見的。\n\n一個對自己認真的人，\n見到你的時候，也不會例外。';

  @override
  String get onboarding2Title => '我們用態度，\n篩選每一個人';

  @override
  String get onboarding2Body =>
      '不是演算法，是真人審核。\n\n每一個通過的帳號，都代表一個人決定認真對待自己，以及認識他的人。';

  @override
  String get onboarding3Title => '好的相遇，\n不是在人堆碰運氣';

  @override
  String get onboarding3Body =>
      '不再是無限滑卡。\n\n每天 PR Dating 只為你精選幾個人\n讓你把所有的注意力，放在真正值得的人身上。\n\n認真的你，值得一個認真的遇見。';

  @override
  String get onboarding1Quote1 => '「連能挑選的照片都這樣，誰還相信見面他會打理好自己」';

  @override
  String get onboarding1Quote2 => '「是我要求太多嗎？」';

  @override
  String get onboarding1Quote3 => '「我打扮了一小時，對方卻⋯」';

  @override
  String get onboarding1Quote4 => '「怎麼都不認真打扮？」';

  @override
  String get onboarding1Quote5 => '「對方的照片看起來好敷衍」';

  @override
  String get onboarding1Quote6 => '「難道只有我在乎見面這件事？」';

  @override
  String get onboarding2Quote1 => '「怎麼知道他是真的？」';

  @override
  String get onboarding2Quote2 => '「都是假照片假資訊」';

  @override
  String get onboarding2Quote3 => '「感覺在跟機器人聊天」';

  @override
  String get onboarding2Quote4 => '「搞不清楚對面是不是真人」';

  @override
  String get onboarding2Quote5 => '「聊了好久才發現是假帳號」';

  @override
  String get onboarding2Quote6 => '「說好見面，卻突然消失了⋯」';

  @override
  String get onboarding3Quote1 => '「滑了好久一個都不對」';

  @override
  String get onboarding3Quote2 => '「真的好累不想滑了」';

  @override
  String get onboarding3Quote3 => '「滑到後來根本不知道自己在找什麼」';

  @override
  String get onboarding3Quote4 => '「這樣找下去到底有沒有用」';

  @override
  String get onboarding3Quote5 => '「每天99+訊息到底要怎麼聊天」';

  @override
  String get onboarding3Quote6 => '「感覺這樣找不是辦法⋯」';

  @override
  String get termsUpdateTitle => '條款已更新';

  @override
  String get termsUpdateSubtitle => '我們更新了服務條款與隱私政策，請閱讀後繼續使用 PR Dating。';

  @override
  String get termsUpdateAccept => '我已閱讀並同意最新條款';

  @override
  String get termsUpdateDecline => '不同意，登出';

  @override
  String get termsUpdateAccepting => '更新中...';

  @override
  String get termsPageTitle => '服務條款';

  @override
  String get privacyPageTitle => '隱私權政策';

  @override
  String get termsLabel => '服務條款';

  @override
  String get privacyLabel => '隱私權政策';

  @override
  String get termsReadFull => '閱讀完整服務條款';

  @override
  String get privacyReadFull => '閱讀完整隱私權政策';

  @override
  String get termsAgreePrefix => '我同意 ';

  @override
  String get termsAgreeAnd => ' 及 ';

  @override
  String get authConsentPrefix => '繼續即代表您同意我們的 ';

  @override
  String get reviewRejectedHardTip1 => '展現真實自我的照片往往最能引起共鳴';

  @override
  String get reviewRejectedHardTip2 => '個人簡介能幫助別人更立體地認識你';

  @override
  String get reviewRejectedHardTip3 => '多元面向的照片能展現更完整的你';

  @override
  String profileAgeYears(int age) {
    return '$age 歲';
  }

  @override
  String get profileSeeking => '尋找';

  @override
  String get profileSeekingMale => '男性';

  @override
  String get profileSeekingFemale => '女性';

  @override
  String get profileSeekingOther => '所有人';

  @override
  String get profileGenderMale => '男';

  @override
  String get profileGenderFemale => '女';

  @override
  String get profileGenderOther => '其他';

  @override
  String get profileSectionBio => '關於我';

  @override
  String get profileSectionInterests => '興趣';

  @override
  String get profileSectionQuestions => '個人問答';

  @override
  String get profileNoBio => '尚未填寫自我介紹';

  @override
  String get profileNoInterests => '尚未設定興趣';

  @override
  String get profileNoQuestions => '尚未回答任何問題';

  @override
  String get profileLoadError => '無法載入個人資料';

  @override
  String get editProfileTitle => '編輯資料';

  @override
  String get editProfileSectionPhotos => '照片';

  @override
  String get editProfileSectionBasic => '基本資料';

  @override
  String get editProfileSectionSeeking => '想認識';

  @override
  String get editProfileSectionInterests => '興趣';

  @override
  String get editProfileSectionQuestions => '個人問答';

  @override
  String get editProfileNameLabel => '顯示名稱';

  @override
  String get editProfileBioLabel => '自我介紹';

  @override
  String get editProfileBioHint => '介紹一下自己...';

  @override
  String editProfileBioHelper(int max) {
    return '選填，最多 $max 字';
  }

  @override
  String get editProfileSeekingMale => '男性';

  @override
  String get editProfileSeekingFemale => '女性';

  @override
  String get editProfileSeekingOther => '不限';

  @override
  String get editProfilePhotoChangeTitle => '更換照片需重新審核';

  @override
  String get editProfilePhotoChangeBody =>
      '更換照片後，需要重拍兩張驗證照片確認是本人。\n審核期間（約 1–3 個工作天），您將繼續使用現有照片與他人配對。';

  @override
  String get editProfilePhotoChangeContinue => '繼續更換';

  @override
  String editProfileInterestsCount(int count) {
    return '已選 $count 個興趣';
  }

  @override
  String get editProfileInterestsEdit => '前往編輯';

  @override
  String editProfileQuestionsCount(int count) {
    return '已回答 $count 個問題';
  }

  @override
  String get editProfileQuestionsEdit => '前往編輯';

  @override
  String get editProfileUnsavedTitle => '放棄變更？';

  @override
  String get editProfileUnsavedMessage => '有尚未儲存的變更，離開後將會遺失。';

  @override
  String get editProfileUnsavedDiscard => '放棄變更';

  @override
  String get editProfileSaved => '已儲存';

  @override
  String get editProfileSaveFailed => '儲存失敗，請再試一次';

  @override
  String get editProfilePhotoPendingBanner => '照片審核中（1–3 個工作天），配對繼續使用原有照片';

  @override
  String get settingsSectionAccount => '帳號';

  @override
  String get settingsSectionPrivacy => '隱私';

  @override
  String get settingsSectionPreferences => '偏好';

  @override
  String get settingsSectionSupport => '支援';

  @override
  String get settingsSectionAbout => '關於';

  @override
  String get settingsPhone => '手機號碼';

  @override
  String get settingsNotifications => '推播通知';

  @override
  String get settingsLanguageZh => '繁體中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsPrivacy => '隱私政策';

  @override
  String get settingsTerms => '服務條款';

  @override
  String get settingsContactUs => '聯絡客服';

  @override
  String get settingsFaq => '常見問題';

  @override
  String get settingsReport => '回報問題';

  @override
  String get settingsVersion => '版本';

  @override
  String get settingsLogoutTitle => '確認登出';

  @override
  String get settingsLogoutMessage => '確定要從這台裝置登出嗎？';

  @override
  String get settingsLogoutConfirm => '登出';

  @override
  String get settingsAccountSecurity => '帳號安全';

  @override
  String get accountSecurityTitle => '帳號安全';

  @override
  String get accountSecurityBody => '以下操作將永久影響您的帳號，請謹慎操作。';

  @override
  String get accountSecurityDeleteTitle => '刪除帳號';

  @override
  String get accountSecurityDeleteDesc =>
      '刪除帳號後，您的所有資料、配對及對話紀錄將永久刪除，無法復原。\n如果只是需要暫時休息，建議先考慮暫停帳號。';

  @override
  String get accountSecurityDeleteButton => '永久刪除帳號';

  @override
  String get editPhotosTitle => '管理照片';

  @override
  String get editPhotosSubtitle => '長按照片可調整順序。最少 2 張，最多 9 張。';

  @override
  String get editPhotosUploading => '上傳中...';

  @override
  String get editPhotosSuccessMessage => '照片已送出審核，審核期間配對繼續進行';

  @override
  String get editPhotosUploadFailed => '上傳失敗，請再試一次';

  @override
  String get editPhotosPendingStatus => '照片審核中（1–3 個工作天）\n配對繼續使用原有照片';

  @override
  String get editReverifyTitle => '拍攝驗證照片';

  @override
  String get editReverifySubtitle => '確認是本人後，新照片才會送出審核。\n驗證照片僅供審核人員查閱，不對外顯示。';

  @override
  String get editReverifySubmit => '送出';

  @override
  String get editReverifyUploading => '送出中...';

  @override
  String get editReverifySuccess => '照片更換申請已送出，審核期間配對繼續進行';

  @override
  String get editReverifyFailed => '送出失敗，請再試一次';

  @override
  String get betaApplyInfoSubtitle => '歡迎回來！確認或調整您的基本資料。';

  @override
  String get betaApplyBioSubtitle => '這是您封測時的自我介紹，可直接使用或重新編輯。';

  @override
  String get betaApplyPhotosLockedTitle => '照片暫時鎖定';

  @override
  String get betaApplyPhotosLockedBody =>
      '為了確保是本人，目前暫時無法更換照片。進入 APP 後可以在個人資料頁自由更換。';
}
