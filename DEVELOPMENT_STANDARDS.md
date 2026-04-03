# Luko — Flutter 開發規範

> **版本：** v0.1 Draft
> **建立日期：** 2026-03-25
> **適用範圍：** 全專案 Flutter 程式碼

---

## 目錄

1. [色彩使用規範](#1-色彩使用規範)
2. [Theme 架構](#2-theme-架構)
3. [元件模組化原則](#3-元件模組化原則)
4. [資料夾結構](#4-資料夾結構)
5. [命名規範](#5-命名規範)
6. [效能規範](#6-效能規範)
7. [安全區域與鍵盤溢位防護](#7-安全區域與鍵盤溢位防護)
8. [推播通知規範](#8-推播通知規範)
9. [用戶行為追蹤規範](#9-用戶行為追蹤規範)
10. [輸入欄鍵盤收起規範](#10-輸入欄鍵盤收起規範)
11. [輸入安全性規範](#11-輸入安全性規範)

---

## 1. 色彩使用規範

### ✅ 使用 `.withValues(alpha:)`，禁止 `.withOpacity()`

Flutter 3.27 起，`Color` 的內部儲存從 `int`（0–255）改為 `double`（0.0–1.0），
舊的 `.withOpacity()` 已被標記為 **deprecated**，精度不足且不支援 wide gamut color。

```dart
// ❌ 禁止 — 已棄用，精度損失
color: AppColors.forest.withOpacity(0.5)

// ✅ 正確 — 直接操作 double 通道，精確無損
color: AppColors.forest.withValues(alpha: 0.5)

// ✅ 多個通道同時調整時
color: AppColors.forest.withValues(alpha: 0.5, red: 0.8)
```

### ✅ 所有顏色必須來自 Theme，禁止硬寫色碼

```dart
// ❌ 禁止 — 顏色寫死在 Widget 裡
Container(color: const Color(0xFF3D6B4F))
Text('Hello', style: TextStyle(color: Colors.green))

// ✅ 正確 — 從 Theme Extension 取色
final colors = Theme.of(context).extension<AppColors>()!;
Container(color: colors.forestGreen)
Text('Hello', style: TextStyle(color: colors.primaryText))
```

---

## 2. Theme 架構

### 整體架構說明

```
ThemeData                    ← Flutter 標準 Theme
  └─ ColorScheme             ← 標準語意色（primary, surface, error…）
  └─ TextTheme               ← 全域字體樣式
  └─ extension<AppColors>    ← Luko 品牌自訂色（ThemeExtension）
  └─ extension<AppSpacing>   ← 間距常數
```

### AppColors — 品牌色 ThemeExtension

```dart
// lib/core/theme/app_colors.dart

import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.forestGreen,
    required this.forestGreenSubtle,
    required this.backgroundWarm,
    required this.primaryText,
    required this.secondaryText,
    required this.cardSurface,
    required this.divider,
    required this.success,
    required this.error,
    required this.warning,
  });

  final Color forestGreen;       // #3D6B4F — 主強調色
  final Color forestGreenSubtle; // #3D6B4F @ alpha:0.12 — Tag 背景、Badge
  final Color backgroundWarm;    // #F4F7F4 — 頁面底色
  final Color primaryText;       // #1A2219 — 主文字
  final Color secondaryText;     // #748070 — 次要文字、時間戳記
  final Color cardSurface;       // #FFFFFF — 卡片背景
  final Color divider;           // #E8EDE8 — 分隔線
  final Color success;           // #3D6B4F — 成功狀態
  final Color error;             // #B3261E — 錯誤、危險動作
  final Color warning;           // #C47A1E — 警告

  /// Light Mode
  static const light = AppColors(
    forestGreen:       Color(0xFF3D6B4F),
    forestGreenSubtle: Color(0x1F3D6B4F), // alpha: 12%
    backgroundWarm:    Color(0xFFF4F7F4),
    primaryText:       Color(0xFF1A2219),
    secondaryText:     Color(0xFF748070),
    cardSurface:       Color(0xFFFFFFFF),
    divider:           Color(0xFFE8EDE8),
    success:           Color(0xFF3D6B4F),
    error:             Color(0xFFB3261E),
    warning:           Color(0xFFC47A1E),
  );

  /// Dark Mode
  static const dark = AppColors(
    forestGreen:       Color(0xFF5A8F6D),
    forestGreenSubtle: Color(0x1F5A8F6D),
    backgroundWarm:    Color(0xFF111614),
    primaryText:       Color(0xFFF0F4F0),
    secondaryText:     Color(0xFF8A9E89),
    cardSurface:       Color(0xFF1C2420),
    divider:           Color(0xFF2A352A),
    success:           Color(0xFF5A8F6D),
    error:             Color(0xFFCF6679),
    warning:           Color(0xFFE6A830),
  );

  @override
  AppColors copyWith({
    Color? forestGreen,
    Color? forestGreenSubtle,
    Color? backgroundWarm,
    Color? primaryText,
    Color? secondaryText,
    Color? cardSurface,
    Color? divider,
    Color? success,
    Color? error,
    Color? warning,
  }) {
    return AppColors(
      forestGreen:       forestGreen       ?? this.forestGreen,
      forestGreenSubtle: forestGreenSubtle ?? this.forestGreenSubtle,
      backgroundWarm:    backgroundWarm    ?? this.backgroundWarm,
      primaryText:       primaryText       ?? this.primaryText,
      secondaryText:     secondaryText     ?? this.secondaryText,
      cardSurface:       cardSurface       ?? this.cardSurface,
      divider:           divider           ?? this.divider,
      success:           success           ?? this.success,
      error:             error             ?? this.error,
      warning:           warning           ?? this.warning,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      forestGreen:       Color.lerp(forestGreen,       other.forestGreen,       t)!,
      forestGreenSubtle: Color.lerp(forestGreenSubtle, other.forestGreenSubtle, t)!,
      backgroundWarm:    Color.lerp(backgroundWarm,    other.backgroundWarm,    t)!,
      primaryText:       Color.lerp(primaryText,       other.primaryText,       t)!,
      secondaryText:     Color.lerp(secondaryText,     other.secondaryText,     t)!,
      cardSurface:       Color.lerp(cardSurface,       other.cardSurface,       t)!,
      divider:           Color.lerp(divider,           other.divider,           t)!,
      success:           Color.lerp(success,           other.success,           t)!,
      error:             Color.lerp(error,             other.error,             t)!,
      warning:           Color.lerp(warning,           other.warning,           t)!,
    );
  }
}
```

### AppTheme — 統一入口

```dart
// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary:   Color(0xFF3D6B4F),
      onPrimary: Color(0xFFFFFFFF),
      surface:   Color(0xFFF4F7F4),
      onSurface: Color(0xFF1A2219),
      error:     Color(0xFFB3261E),
    ),
    textTheme: AppTextTheme.textTheme,
    extensions: const [AppColors.light],
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary:   Color(0xFF5A8F6D),
      onPrimary: Color(0xFFFFFFFF),
      surface:   Color(0xFF111614),
      onSurface: Color(0xFFF0F4F0),
      error:     Color(0xFFCF6679),
    ),
    textTheme: AppTextTheme.textTheme,
    extensions: const [AppColors.dark],
  );
}
```

### Widget 內取用方式

```dart
// ✅ 標準取用方式
class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: colors.backgroundWarm,
      child: Text(
        'Hello',
        style: textTheme.bodyLarge?.copyWith(
          color: colors.primaryText,
        ),
      ),
    );
  }
}

// ✅ 透明度需求時，一律用 withValues
color: colors.forestGreen.withValues(alpha: 0.12)
```

---

## 3. 元件模組化原則

### 核心原則：一個 Widget 只做一件事

當你發現同樣的 UI 片段出現**兩次以上**，就必須模組化。

```
重複出現 2 次  → 考慮抽出
重複出現 3 次  → 必須抽出
```

### 模組化範例

#### ❌ 禁止：重複結構寫死

```dart
// 個人資料頁
Row(children: [
  Icon(Icons.location_on, size: 16, color: Color(0xFF748070)),
  SizedBox(width: 4),
  Text('台北', style: TextStyle(fontSize: 13, color: Color(0xFF748070))),
])

// 聊天室頁
Row(children: [
  Icon(Icons.location_on, size: 16, color: Color(0xFF748070)),
  SizedBox(width: 4),
  Text('台中', style: TextStyle(fontSize: 13, color: Color(0xFF748070))),
])
```

#### ✅ 正確：抽成可重用元件

```dart
// lib/core/widgets/luko_icon_label.dart

class LukoIconLabel extends StatelessWidget {
  const LukoIconLabel({
    super.key,
    required this.icon,
    required this.label,
    this.iconSize = 16.0,
    this.gap = 4.0,
  });

  final IconData icon;
  final String   label;
  final double   iconSize;
  final double   gap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: colors.secondaryText),
        SizedBox(width: gap),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// 使用
LukoIconLabel(icon: Icons.location_on, label: '台北')
```

### 常見應該模組化的元件清單

| 元件名稱 | 路徑 | 說明 |
|---------|------|------|
| `LukoButton` | `core/widgets/luko_button.dart` | 主要 CTA 按鈕，含 primary / secondary variant |
| `LukoAvatar` | `core/widgets/luko_avatar.dart` | 用戶頭像，含圓角、載入狀態 |
| `LukoCard` | `core/widgets/luko_card.dart` | 通用卡片容器，含陰影規範 |
| `LukoIconLabel` | `core/widgets/luko_icon_label.dart` | icon + 文字的行內組合 |
| `LukoTextField` | `core/widgets/luko_text_field.dart` | 統一輸入框樣式 |
| `LukoTag` | `core/widgets/luko_tag.dart` | 標籤 chip，如興趣、城市 |
| `LukoEmptyState` | `core/widgets/luko_empty_state.dart` | 空狀態頁（無配對、無訊息等） |
| `LukoLoadingOverlay` | `core/widgets/luko_loading_overlay.dart` | 全頁載入遮罩 |

### Named Constructor 模式處理 Variant

```dart
// lib/core/widgets/luko_button.dart

class LukoButton extends StatelessWidget {
  // Primary — 填滿強調色
  const LukoButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _ButtonVariant.primary;

  // Secondary — 邊框透明背景
  const LukoButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _ButtonVariant.secondary;

  // Ghost — 純文字
  const LukoButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  }) : _variant = _ButtonVariant.ghost;

  final String            label;
  final VoidCallback?     onPressed;
  final bool              isLoading;
  final _ButtonVariant    _variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;

    return switch (_variant) {
      _ButtonVariant.primary   => _PrimaryButton(colors: colors, label: label, onPressed: onPressed, isLoading: isLoading),
      _ButtonVariant.secondary => _SecondaryButton(colors: colors, label: label, onPressed: onPressed, isLoading: isLoading),
      _ButtonVariant.ghost     => _GhostButton(colors: colors, label: label, onPressed: onPressed),
    };
  }
}

enum _ButtonVariant { primary, secondary, ghost }

// 使用範例
LukoButton.primary(label: '開始配對', onPressed: _onMatch)
LukoButton.secondary(label: '查看資料', onPressed: _onView)
LukoButton.ghost(label: '略過', onPressed: _onSkip)
```

---

## 4. 資料夾結構

```
lib/
├── core/                    # 全專案共用
│   ├── theme/
│   │   ├── app_theme.dart       # ThemeData 統一入口
│   │   ├── app_colors.dart      # AppColors ThemeExtension
│   │   └── app_text_theme.dart  # TextTheme 定義
│   ├── widgets/             # 共用元件（所有頁面都可能用到的）
│   │   ├── luko_button.dart
│   │   ├── luko_avatar.dart
│   │   ├── luko_card.dart
│   │   └── ...
│   ├── constants/
│   │   ├── app_spacing.dart     # 間距常數
│   │   └── app_durations.dart   # 動畫時間常數
│   └── utils/               # 純函數工具
│
├── features/                # 功能模組（每個功能獨立）
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │       ├── pages/
│   │       └── widgets/     # 只有 auth 用的 widgets 放這
│   ├── profile/
│   ├── discover/            # 滑卡頁
│   ├── match/
│   └── chat/
│
├── l10n/                    # 語言包
│   ├── app_en.arb
│   └── app_zh.arb
│
└── main.dart
```

---

## 5. 命名規範

| 類型 | 規則 | 範例 |
|------|------|------|
| 檔案名稱 | `snake_case` | `luko_button.dart` |
| Class 名稱 | `PascalCase` | `LukoButton` |
| 變數 / 函數 | `camelCase` | `isLoading`, `onPressed` |
| 常數 | `camelCase` | `AppSpacing.md` |
| 私有成員 | `_camelCase` | `_variant`, `_buildContent()` |
| 語言 key | `camelCase` | `welcomeTitle`, `loginButton` |

### 共用元件前綴統一用 `Luko`

```dart
// ✅ 一看就知道是專案共用元件
LukoButton, LukoCard, LukoAvatar, LukoTag

// ❌ 避免 — 語意不清
CustomButton, MyCard, SharedAvatar
```

---

## 6. 效能規範

### const 優先

```dart
// ✅ 能 const 就 const，減少 rebuild
const SizedBox(height: 16)
const LukoIconLabel(icon: Icons.star, label: '精選')

// ❌ 不必要的 new instance
SizedBox(height: 16)
```

### 間距用常數，不寫數字

```dart
// lib/core/constants/app_spacing.dart
class AppSpacing {
  AppSpacing._();

  static const double xs  =  4.0;
  static const double sm  =  8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;
}

// ✅ 使用
SizedBox(height: AppSpacing.md)
Padding(padding: EdgeInsets.all(AppSpacing.lg))

// ❌ 禁止
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(24))
```

### 動畫時間用常數

```dart
// lib/core/constants/app_durations.dart
class AppDurations {
  AppDurations._();

  static const Duration fast   = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow   = Duration(milliseconds: 500);
}

// 使用
AnimatedOpacity(duration: AppDurations.normal, ...)
```

---

---

## 7. 安全區域與鍵盤溢位防護

> ⚠️ 所有含輸入框的頁面都必須通過此章節的檢查清單，否則會在低機型或橫向時爆版。

### 7-1. 永遠使用 SafeArea

手機底部導航列（Android 手勢列 / iPhone Home Indicator）和頂部瀏海會遮住 UI。
所有頁面根層必須包上 `SafeArea`。

```dart
// ❌ 禁止 — 內容被導航列或瀏海遮住
Scaffold(
  body: Column(children: [...]),
)

// ✅ 正確 — SafeArea 自動避開瀏海、狀態列、底部手勢區
Scaffold(
  body: SafeArea(
    child: Column(children: [...]),
  ),
)
```

> 💡 `Scaffold` + `AppBar` 組合已自動處理頂部安全區，但**底部仍需要手動保護**。
> 最穩的做法是 `SafeArea` 加在 `body` 內層，讓 `Scaffold` 的背景色可以延伸到邊緣。

### 7-2. 含輸入框的頁面：防止鍵盤遮擋溢位

鍵盤彈出時 `viewInsets.bottom` 增加，若頁面沒有捲動容器就會出現
`A RenderFlex overflowed by xxx pixels` 錯誤。

```dart
// ✅ 標準做法：SingleChildScrollView 包住整個 body
Scaffold(
  resizeToAvoidBottomInset: true,   // 預設為 true，明確寫出增加可讀性
  body: SafeArea(
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(
        left:   AppSpacing.md,
        right:  AppSpacing.md,
        top:    AppSpacing.md,
        // 鍵盤高度 + 額外 padding，確保最後一個欄位不被蓋住
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 表單欄位...
        ],
      ),
    ),
  ),
)
```

### 7-3. 固定底部按鈕（申請流程「下一步」）

申請流程 Step 1–5 的「下一步」按鈕固定在底部，鍵盤彈出時需要跟著上移。
**解法：放進 `Scaffold.bottomNavigationBar`，Flutter 會自動處理上移。**

```dart
// ✅ 正確：bottomNavigationBar 搭配 SafeArea
Scaffold(
  resizeToAvoidBottomInset: true,
  body: SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(children: [
        // 表單內容...
      ]),
    ),
  ),
  bottomNavigationBar: SafeArea(
    // SafeArea 確保按鈕不被手機底部導航列遮住
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md,
      ),
      child: LukoButton.primary(
        label: '下一步',
        onPressed: _onNext,
      ),
    ),
  ),
)

// ❌ 禁止：手動用 Stack + Positioned 固定按鈕
// 這樣鍵盤彈出後按鈕會被遮住
Stack(
  children: [
    ...,
    Positioned(
      bottom: 24,
      child: LukoButton.primary(...),  // 鍵盤蓋住
    ),
  ],
)
```

### 7-4. 聊天室輸入列（底部固定 + 鍵盤互動）

聊天室的訊息輸入框固定在畫面底部，這是最容易出問題的情境。

```dart
// ✅ 聊天室標準結構
Scaffold(
  resizeToAvoidBottomInset: true,  // 讓 body 壓縮，輸入框自動上移
  appBar: AppBar(title: Text(partnerName)),
  body: Column(
    children: [
      Expanded(
        // 訊息列表：鍵盤彈起時 ListView 自動縮短
        child: ListView.builder(
          reverse: true,            // 最新訊息在底部
          itemBuilder: (ctx, i) => MessageBubble(...),
        ),
      ),
      // 輸入列：貼近鍵盤頂端
      _ChatInputBar(),
    ],
  ),
)

// _ChatInputBar 內部
class _ChatInputBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,   // 只保護底部
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(children: [
          Expanded(child: LukoTextField(...)),
          // 送出按鈕...
        ]),
      ),
    );
  }
}
```

### 7-5. MediaQuery 正確取值

```dart
// ✅ Flutter 3.10+ 推薦：只在對應值改變時 rebuild（效能更好）
final bottomInset = MediaQuery.viewInsetsOf(context).bottom;   // 鍵盤高度
final bottomPad   = MediaQuery.paddingOf(context).bottom;      // 系統安全區域高度
final screenSize  = MediaQuery.sizeOf(context);                // 畫面尺寸

// ❌ 舊寫法（任何 MediaQuery 屬性改變都會 rebuild）
final bottomInset = MediaQuery.of(context).viewInsets.bottom;
```

### 7-6. 溢位防護檢查清單

開發每個新頁面前，確認以下項目：

| 情境 | 必須做的事 |
|------|-----------|
| 任何頁面 | 根 Widget 包 `SafeArea` |
| 含輸入框的頁面 | 整個 `body` 包 `SingleChildScrollView` |
| 固定底部 CTA 按鈕 | 放進 `Scaffold.bottomNavigationBar`（包 `SafeArea`） |
| 聊天室 | `resizeToAvoidBottomInset: true` + `Column` 結構 |
| 橫向文字可能過長 | `Text` 加 `overflow: TextOverflow.ellipsis`，或外層包 `Flexible` |
| `Row` 子項不確定寬度 | 加 `Flexible` 或 `Expanded`，避免 unbounded width |
| 鍵盤彈出後想讓用戶下滑關閉鍵盤 | `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag` |

---

## 8. 推播通知規範（Push Notifications）

> Luko 使用 **Firebase Cloud Messaging（FCM）** 發送推播，後端觸發端為 **Supabase Edge Functions**。
> Flutter 端安裝 `firebase_messaging` 套件；FCM 與 Supabase 並存是業界標準做法。

### 8-1. 整體架構

```
Flutter App（用戶端）                  Supabase 後端
  ├─ firebase_messaging              Edge Function
  │   └─ 1. 請求通知權限                └─ 收到 DB 事件（配對/訊息/審核）
  │   └─ 2. 取得 FCM Token    ──→          └─ 呼叫 FCM HTTP v1 API
  │                                              └─ FCM → 手機推播彈出
  └─ 3. 將 Token 存至 Supabase
       └─ device_tokens 資料表
```

### 8-2. 推播觸發時機

| 事件 | 推播標題 | 推播內文 | 觸發來源 |
|------|---------|---------|---------|
| 配對成功 | 「新配對！💚」 | 「你和 [名稱] 互相喜歡了」 | `swipe_match_trigger` → Edge Function |
| 收到新訊息（App 背景） | 「[名稱]」 | 「[訊息前 40 字]」 | `messages` INSERT → Edge Function |
| 審核通過 | 「歡迎加入 Luko！」 | 「點此開始探索」 | `applications.status` 更新 |
| 審核未通過 | 「申請審核完成」 | 「請開啟 App 查看結果」 | `applications.status` 更新 |

> ⚠️ **隱私原則**：通知內文不包含完整訊息內容（避免鎖定螢幕洩漏隱私）。
> 訊息通知只顯示前 40 字，且不在通知欄直接顯示對話圖片。

### 8-3. Flutter 端初始化（在 Auth 初始化時執行）

```dart
// lib/features/auth/data/notification_service.dart

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    // 1. 請求權限（iOS 必須，Android 13+ 也需要）
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. iOS 前景顯示設定
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. 取得 Token 並儲存
    final token = await _messaging.getToken();
    if (token != null) await _upsertToken(token);

    // 4. Token 更新監聽（重裝 App 或長時間未使用後 Token 可能更新）
    _messaging.onTokenRefresh.listen(_upsertToken);

    // 5. App 在背景時，點擊通知的處理
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 6. App 完全關閉時，點擊通知後啟動的處理
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage);
  }

  static Future<void> _upsertToken(String token) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    await Supabase.instance.client.from('device_tokens').upsert({
      'user_id':    userId,
      'token':      token,
      'platform':   Platform.isIOS ? 'ios' : 'android',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,token');
  }

  /// 登出時呼叫：移除此裝置的 Token
  static Future<void> removeToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;

    await Supabase.instance.client
        .from('device_tokens')
        .delete()
        .eq('token', token);

    await _messaging.deleteToken();
  }

  static void _handleTap(RemoteMessage message) {
    final type    = message.data['type'];
    final matchId = message.data['match_id'];

    switch (type) {
      case 'new_match':
        // GoRouter 導向配對列表
        // router.go('/matches');
        break;
      case 'new_message':
        if (matchId != null) {
          // router.go('/messages/$matchId');
        }
        break;
      case 'application_reviewed':
        // router.refresh() → GoRouter guard 自動判斷導向
        break;
    }
  }
}
```

### 8-4. 注意事項

#### iOS 設定（必做）
- Xcode → Target → Signing & Capabilities → 加入 **Push Notifications**
- 同上加入 **Background Modes** → 勾選 **Remote notifications**
- Apple Developer Console 建立 APNs Key 並上傳至 Firebase Console

#### Android 設定（必做）
- `android/app/google-services.json` 放置正確
- `AndroidManifest.xml` 加入通知圖示設定（`notification_icon`）

#### 權限與隱私
- 首次請求通知權限的時機：**審核通過進入主 App 後**，不要在申請流程中詢問
- 用戶**登出時必須呼叫 `NotificationService.removeToken()`**，否則會收到別人的通知
- 帳號刪除時，Edge Function 負責清除 `device_tokens` 資料

---

## 9. 用戶行為追蹤規範

> 目標：收集足夠的行為數據支持產品決策（轉化漏斗、功能使用率、留存分析），
> 但**不收集任何敏感內容**（訊息內文、照片、精確位置）。

### 9-1. 架構

```
Flutter App
  └─ EventTracker（singleton service）
       └─ supabase.from('user_events').insert({...})
            └─ user_events 資料表（JSONB properties）
                  └─ 後端 / BI 工具查詢分析
```

### 9-2. EventTracker Service

在 `lib/core/services/event_tracker.dart` 實作：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';   // 產生 session_id

import '../supabase/supabase_provider.dart';

class EventTracker {
  EventTracker(this._ref) {
    _sessionId = const Uuid().v4();
  }

  final Ref _ref;
  late final String _sessionId;

  // 平台和版本由 main.dart 初始化時設定
  static String platform    = 'android';
  static String appVersion  = '1.0.0';

  Future<void> track(
    String eventName, {
    Map<String, dynamic> properties = const {},
  }) async {
    final supabase = _ref.read(supabaseProvider);
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;   // 未登入不追蹤

    // fire-and-forget：追蹤不阻擋 UI
    supabase.from('user_events').insert({
      'user_id':     userId,
      'event_name':  eventName,
      'properties':  properties,
      'session_id':  _sessionId,
      'platform':    platform,
      'app_version': appVersion,
    }).then((_) {}, onError: (_) {});   // 靜默失敗，不影響主流程
  }
}

final eventTrackerProvider = Provider<EventTracker>(
  (ref) => EventTracker(ref),
);
```

### 9-3. 使用方式

```dart
// 頁面瀏覽（在 initState 呼叫）
ref.read(eventTrackerProvider).track('screen_view',
  properties: {'screen': 'discover'});

// 滑動行為
ref.read(eventTrackerProvider).track('swipe_like',
  properties: {'target_user_id': targetUserId});

// 申請步驟完成
ref.read(eventTrackerProvider).track('apply_step_completed',
  properties: {'step': 3});
```

### 9-4. 事件命名規範

| 規則 | 說明 |
|------|------|
| 命名格式 | `snake_case`，`{物件}_{動作}` |
| 物件優先 | `swipe_like`（不是 `like_swipe`） |
| 過去式動詞 | 事件發生後才記錄，用完成式（`_created`、`_sent`、`_viewed`） |
| 不記錄內容 | properties 禁止放訊息文字、照片 URL、精確座標 |

### 9-5. 完整事件清單

| event_name | 觸發時機 | properties |
|-----------|---------|------------|
| `session_start` | App 冷啟動或 foreground resume | `{"source": "cold_start\|push_notification\|background"}` |
| `screen_view` | 進入任何頁面 | `{"screen": "discover\|matches\|chat\|profile\|..."}` |
| `apply_step_completed` | 完成申請步驟 | `{"step": 1–5}` |
| `photo_uploaded` | 照片上傳成功 | `{"count": 2}` |
| `swipe_like` | 滑右（喜歡） | `{"target_user_id": "uuid"}` |
| `swipe_pass` | 滑左（略過） | `{"target_user_id": "uuid"}` |
| `match_viewed` | 點開配對列表 | — |
| `profile_view` | 查看他人詳細資料 | `{"target_user_id": "uuid"}` |
| `message_sent` | 發送訊息 | `{"match_id": "uuid", "char_count": 42}` |
| `message_first_sent` | 配對後第一則訊息 | `{"match_id": "uuid", "hours_since_match": 3}` |
| `photo_view` | 點看對方照片輪播 | `{"target_user_id": "uuid", "photo_index": 1}` |
| `settings_opened` | 進入設定頁 | — |
| `account_deleted` | 觸發帳號刪除流程 | — |

### 9-6. 禁止事項

```
❌ 禁止追蹤的內容：
   - 訊息文字內容
   - 照片 URL 或路徑
   - 精確 GPS 座標
   - 任何可辨識個人身份的文字（姓名、電話）

❌ 禁止阻擋主流程：
   - track() 必須 fire-and-forget（非 await）
   - 追蹤失敗不得顯示錯誤給用戶
```

---

## 10. 輸入欄鍵盤收起規範

### 規則：所有含文字輸入欄的頁面，點擊空白處必須收起鍵盤

在 `Scaffold` 的 `body:` 最外層包一層 `GestureDetector`：

```dart
body: GestureDetector(
  onTap: () => FocusScope.of(context).unfocus(),
  behavior: HitTestBehavior.translucent, // ← 必須是 translucent，不是 opaque
  child: SafeArea(
    child: ...,
  ),
),
```

**`translucent` vs `opaque` 的差異：**
- `translucent`：GestureDetector 偵測空白區域點擊來 unfocus，子 Widget（Button、TextField）的點擊事件照常傳遞 ✅
- `opaque`：會吞掉所有子 Widget 的點擊事件，導致按鈕、輸入框失效 ❌

如果頁面有 `SingleChildScrollView`，同時加上拖曳收起：

```dart
SingleChildScrollView(
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
  ...
)
```

---

## 11. 輸入安全性規範

### 文字輸入欄的 SQL Injection 風險

**答：無風險。** Supabase Flutter SDK 透過 PostgREST REST API 傳送資料，
參數以 JSON body 傳遞，PostgREST 內部使用 prepared statement。
只要透過 SDK 鏈式 API（`.insert()`、`.update()`）操作，不可能發生 SQL Injection。

```dart
// ✅ 安全 — 由 PostgREST 自動 parameterize
await supabase.from('profiles').insert({'display_name': userInput});
```

### 應用層仍需要的輸入驗證

```dart
// ✅ 長度限制（顯示名稱上限 20 字）
// ✅ 非空驗證
// ✅ 格式驗證（電話號碼、日期）
// ⚠️  若 display_name 顯示於 WebView / 後台 HTML，渲染端需做 XSS 防護
```

---

> 📌 **開發前請先讀完本文件，所有 PR 必須符合以上規範。**
