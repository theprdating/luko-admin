// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'Luko';

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
  String get commonError => '發生錯誤，請再試一次。';

  @override
  String get commonSkip => '略過';

  @override
  String get commonRetry => '重試';

  @override
  String get authWelcomeTitle => '與認真打理自己的人相遇。';

  @override
  String get authWelcomeSubtitle => '申請加入 Luko，每一個帳號都經過人工審核。';

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
  String authConsentSuffix(String privacy) {
    return ' 與 $privacy';
  }

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
  String get permissionPhotoTitle => '需要相簿權限';

  @override
  String get permissionPhotoBody => 'Luko 需要存取您的相簿才能上傳照片。請前往設定開啟相簿權限。';

  @override
  String get permissionCameraTitle => '需要相機權限';

  @override
  String get permissionCameraBody => 'Luko 需要存取相機才能拍照。請前往設定開啟相機權限。';

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
  String get applyBioTitle => '自我介紹';

  @override
  String get applyBioSubtitle => '簡短介紹一下自己（選填）';

  @override
  String get applyBioHint => '分享你的興趣、生活方式或任何想說的話...';

  @override
  String get applyBioHelper => '最多 150 字';

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
  String get reviewRejectedTitleSoft => '目前還不是時候';

  @override
  String get reviewRejectedBodySoft => '感謝你申請加入 Luko。\n目前的呈現方式暫時與我們的標準有些距離。';

  @override
  String get reviewRejectedTitlePotential => '你有 Luko 的潛力！';

  @override
  String get reviewRejectedBodyPotential =>
      '我們看見你的潛力，但目前的照片還不夠展現你的魅力。\n試試這些建議，讓自己更容易通過審核：';

  @override
  String get reviewRejectedTip1 => '靠近窗戶或在戶外自然光下拍攝';

  @override
  String get reviewRejectedTip2 => '臉部清晰，避免過度修圖或濾鏡';

  @override
  String get reviewRejectedTip3 => '加入一張展現你個性的生活照';

  @override
  String reviewReapplyDays(int days) {
    return '$days 天後可重新申請';
  }

  @override
  String get reviewReapplyAvailable => '現在可以重新申請了';

  @override
  String get reviewReapplyButton => '重新申請';

  @override
  String reviewReapplyDateHint(String date) {
    return '最早可於 $date 重新申請';
  }

  @override
  String get discoverTitle => '探索';

  @override
  String get discoverEmptyTitle => '已經看完所有人了';

  @override
  String get discoverEmptySubtitle => '稍後再回來看看新的用戶吧。';

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
      '不再是無限滑卡。\n\n每天 Luko 只為你精選幾個人\n讓你把所有的注意力，放在真正值得的人身上。\n\n認真的你，值得一個認真的遇見。';

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
  String get termsUpdateSubtitle => '我們更新了服務條款與隱私政策，請閱讀後繼續使用 Luko。';

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
}
