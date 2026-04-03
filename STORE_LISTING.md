# Luko — 上架素材規格

> **版本：** v0.1 Draft
> **建立日期：** 2026-03-25
> **用途：** App Store + Google Play 上架素材清單與文案

---

## 目錄

1. [App 基本資訊](#1-app-基本資訊)
2. [App Store 文案](#2-app-store-文案)
3. [Google Play 文案](#3-google-play-文案)
4. [截圖規格與內容](#4-截圖規格與內容)
5. [App Icon 規格](#5-app-icon-規格)
6. [隱私權政策大綱](#6-隱私權政策大綱)
7. [服務條款大綱](#7-服務條款大綱)
8. [年齡分級設定](#8-年齡分級設定)
9. [上架提交清單](#9-上架提交清單)

---

## 1. App 基本資訊

| 項目 | 內容 |
|------|------|
| App 名稱 | Luko |
| 副標題 | 與認真打理自己的人相遇 |
| 開發者名稱 | （待填：公司或個人名稱） |
| Bundle ID（iOS） | com.yuliao.luko |
| Package Name（Android） | com.yuliao.luko |
| 版本號 | 1.0.0 |
| 支援語言 | 繁體中文、English |
| 支援平台 | iOS 16.0+、Android 8.0+ |
| 類別 | 社交（Social Networking）|

---

## 2. App Store 文案

### App 名稱（30 字元以內）
```
Luko
```

### 副標題（30 字元以內）
```
繁中：與認真打理自己的人相遇
English：Meet People Who Take Care
```

### 描述（繁中版，4000 字元以內）

```
Luko 不一樣。

我們相信，一個認真打理自己的人，在生活的各個面向也更用心。
Luko 是一個有入場門檻的交友社群——每一個帳號都經過人工審核。

你不需要完美，但你需要認真對待自己。

【如何加入 Luko】
1. 提交申請：填寫基本資料、上傳近期照片
2. 等待審核：我們的團隊將在 48 小時內完成審核
3. 開始探索：通過後，你就進入了一個不同品質的社群

【核心功能】
・卡片滑動配對：直觀的探索體驗
・即時訊息：與配對對象輕鬆聊天
・形象意識社群：與同樣重視自我形象的人連結

【關於審核】
我們不是在評判任何人，而是在建立一個讓大家都更舒適的空間。
審核未通過並不代表你不好，只是我們正在謹慎地維護社群品質。

【隱私保護】
・你的照片僅用於入會審核，不會被用於其他目的
・完整隱私權政策：luko.app/privacy

準備好了嗎？申請加入 Luko。
```

### 描述（English 版）

```
Luko is different.

We believe people who take care of themselves tend to be more intentional in all areas of life.
Luko is a curated dating community — every profile is reviewed by our team.

You don't need to be perfect. You just need to care.

[How to Join Luko]
1. Apply: Submit your info and recent photos
2. Wait for review: Our team reviews every application within 48 hours
3. Start exploring: Once approved, you're part of a different kind of community

[Core Features]
· Card-swipe discovery with a curated pool
· Real-time messaging with your matches
· A community where first impressions actually matter

[About Our Review]
We're not here to judge anyone — we're building a space where everyone feels more comfortable.
Not being approved isn't a verdict on you as a person.

[Privacy]
· Your photos are only used for membership review
· Full Privacy Policy: luko.app/privacy

Ready? Apply to join Luko.
```

### 關鍵字（100 字元以內，逗號分隔）

```
交友,配對,dating,meet,交友軟體,外貌,形象,高品質,審核,社群,認識朋友,戀愛
```

---

## 3. Google Play 文案

### 簡短說明（80 字元以內）

```
繁中：高品質交友社群，每個帳號都經過人工審核。
English：A curated dating app. Every profile is reviewed by our team.
```

### 完整說明（與 App Store 描述相同，可直接複製）

---

## 4. 截圖規格與內容

### iPhone（必要，6.7 吋，1290 × 2796px）

| 張數 | 畫面 | 重點說明文字 |
|------|------|-------------|
| 1 | 歡迎頁 | 「與認真打理自己的人相遇」 |
| 2 | 探索頁（滑卡） | 「每一個人都通過了人工審核」 |
| 3 | 配對成功頁 | 「互相喜歡才能開始聊天」 |
| 4 | 聊天室 | 「直接開始你們的故事」 |
| 5 | 個人檔案頁 | 「打理好自己，展現真實的你」 |

> ⚠️ 截圖中的人物照片**不得使用真實用戶照片**（除非取得書面授權）
> 建議：使用設計工具生成模擬人臉，或使用授權免費圖庫

### iPad（若支援）

暫時不需要，初期標記為「不支援 iPad」。

### Android（Google Play）

```
手機截圖：1080 × 1920px（或 9:16 比例）
內容：與 iPhone 截圖相同
```

---

## 5. App Icon 規格

| 平台 | 尺寸 | 格式 | 備註 |
|------|------|------|------|
| App Store | 1024 × 1024px | PNG，無圓角，無透明 | Apple 自動加圓角 |
| Google Play | 512 × 512px | PNG | 可有透明背景 |
| App 內（iOS） | 多種尺寸 | 透過 flutter_launcher_icons 自動生成 | |
| App 內（Android） | 多種尺寸 | 透過 flutter_launcher_icons 自動生成 | |

### flutter_launcher_icons 設定

```yaml
# 加入 pubspec.yaml 的 dev_dependencies：
dev_dependencies:
  flutter_launcher_icons: ^0.14.0

# pubspec.yaml 的 flutter_icons 區塊：
flutter_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"   # 1024x1024 原始圖
  adaptive_icon_background: "#F4F7F4"      # Android 自適應圖示背景色
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

---

## 6. 隱私權政策大綱

> 需由律師協助撰寫完整版本，以下為必要涵蓋項目。
> 託管位置：`luko.app/privacy`（上架前必須上線）

### 必要涵蓋項目

```
1. 蒐集的個人資料類型
   ✅ 手機號碼（驗證用）
   ✅ 姓名、生日、性別
   ✅ 個人照片（含人臉影像，屬生物特徵資料）
   ✅ 自我介紹文字
   ✅ 使用記錄（滑動、配對、訊息）
   ✅ 裝置資訊（OS 版本、裝置型號）

2. 資料使用目的
   ✅ 入會資格審核
   ✅ 提供配對與聊天服務
   ✅ 平台安全維護（防詐騙、處理檢舉）

3. 資料保存與刪除
   ✅ 審核未通過者：照片於 30 天內刪除
   ✅ 帳號刪除後：所有個人資料於 30 天內清除
   ✅ 聊天訊息：帳號刪除時一併清除

4. 第三方服務（資料處理者）
   ✅ Supabase（資料庫與儲存，美國）
   ✅ 說明跨境傳輸情況（個資法要求）

5. 用戶權利
   ✅ 查詢自己的資料
   ✅ 更正資料
   ✅ 刪除帳號與資料
   ✅ 聯絡方式：support@luko.app（待確認）

6. 未成年人保護
   ✅ 本平台僅供 18 歲以上用戶使用
   ✅ 若發現未成年用戶，立即停權並刪除資料
```

---

## 7. 服務條款大綱

> 託管位置：`luko.app/terms`（上架前必須上線）

### 必要涵蓋項目

```
1. 服務說明
   - Luko 是一個有入會門檻的交友平台
   - 申請加入不保證通過

2. 入會審核條款（法律關鍵條款）
   「本平台保留對所有申請進行審核的權利，
    並有權在不說明具體原因的情況下拒絕申請。
    此決定屬平台內部決策，不構成任何形式的歧視。」

3. 用戶行為規範
   - 禁止上傳他人照片
   - 禁止騷擾、詐騙其他用戶
   - 違規行為將導致帳號停權

4. 照片使用授權
   「您上傳的照片僅用於身份審核與個人檔案展示，
    平台不會將您的照片用於廣告或其他商業目的。」

5. 帳號終止
   - 用戶可隨時刪除帳號
   - 平台保留在用戶違規時終止帳號的權利

6. 免責聲明
   - 平台不對用戶間的互動行為負責
   - 建議在實體見面前謹慎確認對方身份

7. 聯絡方式
   support@luko.app
```

---

## 8. 年齡分級設定

### App Store（iOS）

```
年齡分級：17+
原因：
  ✅ 包含成人交友功能（Dating）
  ✅ 允許用戶上傳個人照片
  ✅ 含有用戶生成內容

設定位置：
  App Store Connect → App Information → Age Rating
  問卷中選擇：
    「Dating services for people 17 and up」→ 啟用
```

### Google Play（Android）

```
內容分級：PEGI 16 / 目標對象 16+（或依問卷結果）
IARC 問卷中需說明：
  ✅ 包含用戶配對功能
  ✅ 包含用戶之間的即時通訊
  ✅ 18 歲以上才能使用（需在 App 中實作年齡驗證）

設定位置：
  Google Play Console → Content rating → Start questionnaire
```

---

## 9. 上架提交清單

### App Store Connect

```
□ 帳號設定
  □ Apple Developer Program 會員費繳納（NT$3,000/年）
  □ 建立 App ID：com.yuliao.luko
  □ 建立 App Store Connect App 條目

□ 素材準備
  □ App Icon（1024 × 1024px PNG）
  □ iPhone 截圖 × 5 張（6.7 吋）
  □ App 名稱（繁中 + 英文）
  □ App 副標題（繁中 + 英文）
  □ App 描述（繁中 + 英文）
  □ 關鍵字（繁中 100 字元）
  □ 支援 Email（4.0 合規要求）

□ 技術設定
  □ 隱私權政策 URL（luko.app/privacy）
  □ 服務條款 URL（luko.app/terms）
  □ 年齡分級問卷完成（選擇 17+）
  □ 內容說明（填寫交友 App 相關欄位）

□ 合規功能確認（退件常見原因）
  □ 檢舉功能正常運作
  □ 封鎖功能正常運作
  □ 帳號刪除功能正常運作
  □ 17+ 年齡提醒

□ Build 上傳
  □ flutter build ipa --release
  □ 透過 Xcode 或 Transporter 上傳到 App Store Connect
  □ TestFlight 內部測試通過
```

### Google Play Console

```
□ 帳號設定
  □ 開發者帳號費用繳納（US$25 一次性）
  □ 開發者身份驗證

□ 素材準備
  □ App Icon（512 × 512px PNG）
  □ Feature Graphic（1024 × 500px）
  □ 手機截圖 × 5 張（9:16）
  □ App 名稱（繁中 + 英文）
  □ 簡短說明（繁中 80 字元）
  □ 完整說明（繁中 + 英文）

□ 技術設定
  □ 隱私權政策 URL
  □ 內容分級問卷完成
  □ 目標對象：18 歲以上
  □ 資料安全問卷填寫（蒐集哪些資料）

□ Build 上傳
  □ flutter build appbundle --release
  □ 上傳到 Google Play Console
  □ 內部測試軌道測試通過
  □ 申請正式上架審核
```

---

*上架素材持續更新中。隱私權政策與服務條款需在律師審閱後定稿。*
