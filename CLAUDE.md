# Luko — Claude Code 操作手冊

## 專案概覽
**Luko** 是一個精選制約會 App，台灣市場，Traditional Chinese 優先。
- **Tech stack**: Flutter (Riverpod + GoRouter) + Supabase (PostgreSQL + Storage + Edge Functions) + Firebase FCM
- **Supabase project ref**: xzqwzpwpjofpkbewkwzx

## 常用指令

```bash
# Flutter
flutter gen-l10n          # 從 .arb 產生本地化 .dart（改完 .arb 必跑）
flutter analyze           # 靜態分析
flutter build apk         # 建置 Android

# Supabase
supabase migration new <name>   # 建立新 migration
supabase db push                # 套用 migration 到遠端
supabase status                 # 確認 local/remote 狀態

# Edge Functions 部署（必須帶 --no-verify-jwt，見下方說明）
supabase functions deploy review-application --no-verify-jwt
```

---

## Edge Function 部署規則

### review-application 必須用 --no-verify-jwt

```bash
supabase functions deploy review-application --no-verify-jwt
```

**原因**：Supabase gateway 的 JWT 驗證與 session revocation 機制在某些情況下會讓有效的 user JWT 被 gateway 拒絕（HTTP 401、`execution_id: null`），導致 function 程式碼完全不執行。

**安全補償措施（缺一不可）**：
- function 內部 decode JWT payload 取得 `sub`（caller user_id）
- 再用 **service role client** 從 Auth DB 查 `user_metadata.user_role`，確認是 `"admin"`
- 授權判斷以 DB 為 source of truth，而非信任 JWT payload 的 user_role 宣稱

這樣即使 JWT 被偽造，攻擊者仍無法通過 admin 驗證，因為 DB 才是最終判斷依據。

---

## 硬性規則（絕對禁止）

### 🚫 不可直接改 generated l10n .dart 檔
`app_localizations.dart`、`app_localizations_zh.dart`、`app_localizations_en.dart` 由 `flutter gen-l10n` 自動產生，直接修改下次 build 會被覆蓋。

✅ 正確流程：
1. 修改 `app/lib/l10n/app_en.arb` 和 `app/lib/l10n/app_zh.arb`
2. 執行 `flutter gen-l10n`
3. commit .arb + 生成的 .dart 一起進版本控制

### 🚫 不可硬寫顏色
所有顏色必須來自 `Theme.of(context).extension<AppColors>()!`，禁止直接寫 `Color(0xFF...)` 或 `Colors.xxx` 在 Widget 裡。

### 🚫 不可用 `.withOpacity()`
Flutter 3.27+ 已棄用。一律改用 `.withValues(alpha: 0.5)`。

---

## 文件索引

| 文件 | 用途 |
|------|------|
| `DEVELOPMENT_STANDARDS.md` | Flutter 編碼規範（色彩、Theme、元件、命名、效能） |
| `DATABASE_SCHEMA.md` | 所有資料表設計、RLS、索引、Storage bucket |
| `PRODUCT_SPEC.md` | 產品需求規格 |
| `USER_FLOW.md` | 使用者流程與 App 狀態機 |
| `BRAND.md` | 品牌視覺規範 |
| `ADMIN_PANEL.md` | 後台管理介面規格 |
| `STORE_LISTING.md` | App Store / Play Store 上架文案 |

---

## App 狀態機（Router redirect 邏輯）

```
loading → unauthenticated → onboarding → pending ──┐
                                         rejected ──┼→ /gate (GateScreen)
                                         termsRequired → /terms-update
                                         approved → 主 App
```

- `/terms` 和 `/privacy` 在所有狀態都可存取（redirect 前先放行）
- `onboarding` = 3 slides 哲學頁，用 SharedPreferences `luko.onboarding_shown` 追蹤
- `rejection_type`: `soft` / `potential` / `hard`

---

## 本地化原則
- Source of truth：`.arb` 檔
- 繁體中文優先（`app_zh.arb`），英文同步維護（`app_en.arb`）
- `.dart` 視為 build artifact，不進行手動修改
