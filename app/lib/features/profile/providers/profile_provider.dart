import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_provider.dart';

/// 當前登入用戶的個人資料（profiles 表完整欄位）
final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userId = ref.watch(currentUserProvider)?.id;
  if (userId == null) return null;

  final supabase = ref.watch(supabaseProvider);
  return await supabase
      .from('profiles')
      .select(
        'id, display_name, birth_date, gender, bio, '
        'photo_paths, city, seeking, interests, question_answers, '
        'photo_pending_review',
      )
      .eq('id', userId)
      .maybeSingle();
});

/// 個人資料照片的公開 CDN Transform URL 列表
///
/// profile-photos bucket 是公開的（migration 20260412000002_profile_photos_public）。
/// getPublicUrl() 同步計算，無 API call，URL 永久有效，適合 CachedNetworkImage disk cache。
///
/// Gallery 尺寸：width 1200px，quality 82（3x DPI 手機不失真）
final myProfilePhotoUrlsProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null) return [];

  final photoPaths = (profile['photo_paths'] as List?)?.cast<String>() ?? [];
  if (photoPaths.isEmpty) return [];

  final supabase = ref.read(supabaseProvider);

  return photoPaths.map((path) {
    // Beta users may have full URLs (PR Dating source) until import-beta-media completes
    if (path.startsWith('https://') || path.startsWith('http://')) return path;
    return supabase.storage
        .from('profile-photos')
        .getPublicUrl(path);
  }).toList();
});

/// 換照審核中的 reverify 路徑（僅判斷是否有待審核驗證照）
///
/// 不用於顯示，僅供 EditProfilePage 判斷管理照片按鈕是否應禁用。
final myProfilePhotoPendingProvider = FutureProvider<bool>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  return profile?['photo_pending_review'] as bool? ?? false;
});

/// 個人資料照片縮圖 URL（160px，用於 EditProfilePage 橫向縮圖列）
///
/// 單獨提供小尺寸 URL，避免 EditProfilePage 下載完整 1200px 圖僅顯示 80×80px 的縮圖。
final myProfilePhotoThumbnailUrlsProvider = FutureProvider<List<String>>((ref) async {
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null) return [];

  final photoPaths = (profile['photo_paths'] as List?)?.cast<String>() ?? [];
  if (photoPaths.isEmpty) return [];

  final supabase = ref.read(supabaseProvider);

  return photoPaths.map((path) {
    // Beta users may have full URLs (PR Dating source) until import-beta-media completes
    if (path.startsWith('https://') || path.startsWith('http://')) return path;
    return supabase.storage
        .from('profile-photos')
        .getPublicUrl(path);
  }).toList();
});
