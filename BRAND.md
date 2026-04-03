# Luko — 品牌與設計系統

> **版本：** v0.1 Draft
> **建立日期：** 2026-03-25
> **狀態：** 色彩系統已定案，持續更新中

---

## 目錄

1. [設計哲學](#1-設計哲學)
2. [色彩系統](#2-色彩系統)
3. [字體系統](#3-字體系統)
4. [間距與圓角](#4-間距與圓角)
5. [動畫與互動](#5-動畫與互動)
6. [圖示風格](#6-圖示風格)
7. [元件設計原則](#7-元件設計原則)
8. [雙語系統（i18n）](#8-雙語系統i18n)
9. [深色模式](#9-深色模式)

---

## 1. 設計哲學

### 核心精神：「少即是精，精即是美」

參考對象不是熱鬧的交友 App，而是：

| 參考對象 | 借鑑元素 |
|----------|----------|
| **Apple iOS** | 空間感、動畫流暢度、細節一致性 |
| **Raya** | 高冷質感、稀缺感 |
| **Aesop 官網** | 留白、字體、克制的色彩 |
| **Loewe App** | 高端品牌的觸感與節奏 |

### 設計四原則

```
1. 空間即設計
   └─ 大量留白，讓每個元素都能「呼吸」
   └─ 不塞資訊，一個畫面只做一件事

2. 動畫是語言
   └─ 每個轉場、每個反饋都有意義
   └─ 絕不用動畫裝飾，只用動畫溝通

3. 字體即個性
   └─ 字體大小、粗細的層次即是設計
   └─ 顏色數量控制在 3 個以內

4. 觸感優先
   └─ 按下去要有反應（Haptic Feedback）
   └─ 滑動要跟手（60fps，physics-based）
```

---

## 2. 色彩系統

> ✅ 色彩方向已定案：**Palette 3 — Forest Elite（深林綠）**
> 定案日期：2026-03-25

### 定案色盤：Forest Elite

靈感：Aesop、精品植物品牌、Organic Luxury
色系類型：**Organic Luxury**（非莫蘭迪——深色有深度，淺色有溫度，整體不刺眼）

```
── Light Mode ─────────────────────────────────────────

背景
  Background:          #F4F7F4   ← 極淡綠白，溫潤不刺眼
  Card Surface:        #FFFFFF   ← 卡片、對話框
  Surface Alt:         #EEF2EE   ← 輸入框、分隔區塊背景

文字
  Text Primary:        #1A2219   ← 深墨綠黑，主文字
  Text Secondary:      #748070   ← 莫蘭迪灰綠，次要文字
  Text Hint:           #B0BEB0   ← Placeholder

強調色（Accent）
  Forest Green:        #3D6B4F   ← 主強調色：按鈕、Like 特效、高亮
  Forest Green Dark:   #2D5040   ← Pressed / Hover 狀態
  Forest Green Subtle: #3D6B4F1F ← 12% alpha，Tag 背景、Badge

分隔線
  Divider:             #E8EDE8

系統色
  Success:             #3D6B4F   ← 與主色相同
  Error:               #B3261E   ← 封鎖、刪除等危險動作
  Warning:             #C47A1E

── Dark Mode ──────────────────────────────────────────

Background:            #111614
Card Surface:          #1C2420
Text Primary:          #F0F4F0
Text Secondary:        #8A9E89
Forest Green:          #5A8F6D
Forest Green Subtle:   #5A8F6D1F
Divider:               #2A352A
Error:                 #CF6679
```

### Flutter 對應（實作位置）

```
lib/core/theme/app_colors.dart  ← ThemeExtension 完整定義
lib/core/theme/app_theme.dart   ← ThemeData + ColorScheme 統一入口

取色方式（程式碼規範）：
  final colors = Theme.of(context).extension<AppColors>()!;
  colors.forestGreen
  colors.forestGreen.withValues(alpha: 0.12)   ← 透明度用 withValues
```

### 使用規則

```
✅ Forest Green 只用在：主要按鈕、配對成功特效、Like 圖示、active 狀態
✅ 一個畫面最多出現 2 種顏色（不含灰階）
✅ 所有顏色透明度使用 .withValues(alpha:)，禁止 .withOpacity()
✅ 所有顏色必須從 AppColors（ThemeExtension）取用，禁止硬寫色碼
❌ 不用漸層（除非是配對成功的慶祝動畫）
❌ 不用多於 3 種灰色層次
```

---

## 3. 字體系統

### 字體選擇

```
主字體（內文、UI）：
  英文：Inter（Google Fonts，免費，Apple 品質感）
  中文：Noto Sans TC（繁體中文最佳選擇，Google Fonts）

Flutter 設定：
  dependencies:
    google_fonts: ^6.x.x
```

### 字體層級

```
Display（大標題，如配對成功頁）
  Size: 32sp  Weight: Bold (700)  Leading: 1.2

Headline（頁面標題）
  Size: 24sp  Weight: SemiBold (600)  Leading: 1.3

Title（卡片標題、用戶姓名）
  Size: 20sp  Weight: SemiBold (600)  Leading: 1.3

Body（主要內文）
  Size: 16sp  Weight: Regular (400)  Leading: 1.5

Caption（輔助資訊、時間戳記）
  Size: 13sp  Weight: Regular (400)  Leading: 1.4

Label（按鈕、Tab、標籤）
  Size: 14sp  Weight: Medium (500)  Leading: 1.0
```

### 字體使用原則

```
✅ 同一畫面最多 3 個字體大小層次
✅ 重要資訊用 Weight 區分，而不是用顏色區分
❌ 不用斜體（中文不適合）
❌ 不用全大寫（ALLCAPS）在中文介面
```

---

## 4. 間距與圓角

### 間距系統（8pt Grid）

```
所有間距都是 8 的倍數：

xs:   4px   ← 元素內部小間距
sm:   8px   ← 相近元素之間
md:  16px   ← 標準間距（最常用）
lg:  24px   ← 區塊之間
xl:  32px   ← 頁面上下 Padding
xxl: 48px   ← 大區塊分隔
```

### 圓角系統

```
small:  8px   ← Tag、小按鈕
medium: 16px  ← 輸入框、小卡片
large:  24px  ← 主要 Card、大按鈕
xlarge: 32px  ← Bottom Sheet、Modal
full:   999px ← 圓形按鈕（Like/Pass）、頭像
```

### 陰影

```
Apple 風格的陰影：少、柔、低彩度

Card Shadow:
  color: #00000014  （不透明度 8%）
  blur:  20px
  y:     4px

Subtle Shadow（輸入框 focus）:
  color: #C4956A30  （Accent 色，30% 透明度）
  blur:  12px
  y:     0px
```

---

## 5. 動畫與互動

### Apple 品質感的關鍵：動畫

```
原則：
  - 用 spring physics（彈簧動畫），不用 linear / ease
  - 所有轉場 200–350ms
  - 滑動卡片跟手，放開後彈回或飛出

Flutter 實作：
  基本動畫：AnimationController + CurvedAnimation
  Spring：physics-based simulation
  套件：flutter_animate（推薦，語法簡潔）
```

### 互動反饋標準

```
按鈕點擊
  └─ 視覺：Scale down 0.96，duration 100ms，spring back 200ms
  └─ 觸覺：HapticFeedback.lightImpact()

Like（右滑）
  └─ 視覺：卡片飛出 + 綠色光暈漸出
  └─ 觸覺：HapticFeedback.mediumImpact()

Pass（左滑）
  └─ 視覺：卡片飛出（灰色）
  └─ 觸覺：HapticFeedback.selectionClick()

配對成功
  └─ 視覺：全螢幕動畫（兩張照片合攏 + 粒子特效）
  └─ 觸覺：HapticFeedback.heavyImpact() × 2（節奏感）

頁面轉場
  └─ 使用 iOS 風格的側滑轉場（CupertinoPageRoute 或自訂）
```

### 載入狀態

```
✅ 使用 Skeleton Loading（骨架屏），不用 Spinner
   └─ 原因：Spinner 讓用戶感知等待，Skeleton 讓用戶感知「快要好了」

實作：shimmer 套件（flutter_shimmer）
```

---

## 6. 圖示風格

```
選擇：Lucide Icons 或 Phosphor Icons
原因：線條風格統一、有 Flutter 套件、輕量

規格：
  大小：24px（標準）/ 20px（小）/ 32px（強調）
  線條：1.5px stroke weight
  風格：Outline（非 Filled），質感更輕盈

❌ 不混用不同風格的 Icon 套件
```

---

## 7. 元件設計原則

### 主要按鈕（Primary Button）

```
外觀：
  背景：Accent (#C4956A)
  文字：White，14sp Medium
  圓角：16px
  高度：52px
  寬度：撐滿容器（Full Width）

狀態：
  Default  → Accent
  Pressed  → Accent Dark (#96704A) + Scale 0.96
  Disabled → #C4BDBB（Hint 色），不可點擊
  Loading  → 文字換成小型 Spinner（白色）
```

### 輸入框

```
外觀：
  背景：Surface Alt (#F3F1EE)
  邊框：無（flat design）
  圓角：16px
  高度：56px

狀態：
  Default  → 無邊框
  Focus    → Accent 色細邊框 1.5px + 柔和陰影
  Error    → Error 色細邊框 + 下方紅色提示文字
```

### 用戶卡片（Swipe Card）

```
外觀：
  圓角：24px
  陰影：Card Shadow
  照片：全滿，底部漸層（黑色 0%→50%）讓文字可讀
  資訊區：左下角，名字 + 年齡

互動：
  拖曳時：輕微旋轉（最大 ±15度）
  右滑 >30%：顯示 LIKE 標籤（綠色）
  左滑 >30%：顯示 PASS 標籤（灰色）
```

---

## 8. 雙語系統（i18n）

### 支援語言

| 語言 | 代碼 | 優先順序 |
|------|------|----------|
| 繁體中文 | zh-TW | 主要市場（台灣） |
| English | en | 次要市場 |

### Flutter i18n 架構

```
技術選型：flutter_localizations + intl（官方標準方案）
原因：
  ✅ Flutter 官方支援，長期穩定
  ✅ ARB 格式，翻譯人員友善
  ✅ 支援複數、性別、日期格式本地化
  ✅ 編譯時期生成型別安全的程式碼
```

### 檔案結構

```
lib/
  l10n/
    app_en.arb       ← 英文字串
    app_zh.arb       ← 繁體中文字串

pubspec.yaml 設定：
  flutter:
    generate: true   ← 維持此行

l10n.yaml（Flutter 3.27+ 新寫法，已套用）：
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  output-dir: lib/l10n
  synthetic-package: false   ← 輸出為真實檔案，非舊的 flutter_gen

import 方式：
  import 'package:luko/l10n/app_localizations.dart';  ✅
  import 'package:flutter_gen/...'                     ❌ 已棄用
```

### ARB 檔案範例

```json
// app_en.arb
{
  "@@locale": "en",
  "appName": "Luko",
  "loginTitle": "Welcome back",
  "loginSubtitle": "Enter your phone number to continue",
  "phoneLabel": "Phone number",
  "sendOtp": "Send code",
  "swipeDiscoverTitle": "Discover",
  "matchTitle": "It's a Match!",
  "matchSubtitle": "{name} and you liked each other",
  "@matchSubtitle": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "reviewPending": "Your application is under review",
  "reviewApproved": "Welcome to Luko!",
  "reviewRejected": "Your application doesn't meet our community standards at this time.",
  "reapplyIn": "You can reapply in {days} days",
  "@reapplyIn": {
    "placeholders": {
      "days": { "type": "int" }
    }
  }
}
```

```json
// app_zh.arb
{
  "@@locale": "zh",
  "appName": "Luko",
  "loginTitle": "歡迎回來",
  "loginSubtitle": "請輸入你的手機號碼繼續",
  "phoneLabel": "手機號碼",
  "sendOtp": "發送驗證碼",
  "swipeDiscoverTitle": "探索",
  "matchTitle": "配對成功！",
  "matchSubtitle": "{name} 和你互相喜歡對方",
  "@matchSubtitle": {
    "placeholders": {
      "name": { "type": "String" }
    }
  },
  "reviewPending": "你的申請正在審核中",
  "reviewApproved": "歡迎加入 Luko！",
  "reviewRejected": "你目前暫時未符合我們的社群標準。",
  "reapplyIn": "{days} 天後可重新申請",
  "@reapplyIn": {
    "placeholders": {
      "days": { "type": "int" }
    }
  }
}
```

### 在程式碼中使用

```dart
// 取得翻譯
final l10n = AppLocalizations.of(context)!;
Text(l10n.loginTitle)
Text(l10n.matchSubtitle(user.name))

// 語言切換（存在 SharedPreferences）
// 使用 Riverpod 管理當前 locale
final localeProvider = StateProvider<Locale>((ref) {
  return const Locale('zh'); // 預設繁中
});
```

### 語言切換 UX

```
位置：設定頁 > 語言
選項：繁體中文 / English
切換後：即時生效，不需重啟 App
儲存：SharedPreferences（本地儲存，不需後端）
```

### i18n 注意事項

```
✅ 所有用戶看到的文字都走 ARB，禁止 hardcode 中文或英文
✅ 審核拒絕通知的文字特別重要，兩種語言都要字斟句酌
✅ 日期格式本地化：
   zh → 2026年3月25日
   en → March 25, 2026
✅ 電話號碼格式：用 intl_phone_field 套件處理國碼
```

---

## 9. 深色模式

```
策略：跟隨系統（初期）

實作：
  ThemeMode.system  → 自動跟隨 iOS/Android 系統設定

深色模式色彩對應：
  Background:     #0D0D0F   ← 不用純黑，有層次感
  Surface:        #1C1C1E   ← Apple Dark Mode 標準
  Surface Alt:    #2C2C2E
  Text Primary:   #FFFFFF
  Text Secondary: #AEAEB2
  Accent:         #C4956A   ← 暖金在深色背景上很好看，保持不變

注意：
  ✅ 不要讓深色模式變成「把白色換成黑色」
  ✅ 陰影在深色模式改用發光效果（glow）而非陰影
  ✅ 先做淺色，深色模式在 MVP 後補上也可以
```

---

*設計系統持續更新中。色彩方向待 Co-founder 確認後定案。*
