import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// FCM 推播服務
///
/// 使用方式：
///   1. main.dart 的 Firebase.initializeApp() 之後呼叫 FcmService.init()
///   2. 登出時呼叫 FcmService.deleteToken()
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background message handler 必須是 top-level function
  // 此處僅做 silent 處理，UI 通知由系統自動顯示
  debugPrint('[FCM] background message: ${message.messageId}');
}

class FcmService {
  FcmService._();

  /// 當收到 application_approved / application_rejected 類型通知時呼叫
  /// 由 LukoApp.build() 設定，確保每次 rebuild 都持有最新的 ref
  static VoidCallback? _onApplicationStatusChange;

  /// 當收到 photo_change_approved / photo_change_rejected 類型通知時呼叫
  /// 用於刷新個人資料照片狀態
  static VoidCallback? _onPhotoChangeComplete;

  static void setStatusChangeCallback(VoidCallback callback) {
    _onApplicationStatusChange = callback;
  }

  static void setPhotoChangeCallback(VoidCallback callback) {
    _onPhotoChangeComplete = callback;
  }

  static void _handleStatusChange(RemoteMessage message) {
    final type = message.data['type'] as String?;
    if (type == 'application_approved' || type == 'application_rejected') {
      _onApplicationStatusChange?.call();
    }
    if (type == 'photo_change_approved' || type == 'photo_change_rejected') {
      _onPhotoChangeComplete?.call();
    }
  }

  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;

    // ── 請求通知權限（iOS 必要；Android 13+ 也需要）──────────────────────
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] 用戶拒絕通知權限');
      return;
    }

    // ── 取得並儲存 token ────────────────────────────────────────────────
    await _registerToken(messaging);

    // ── Token 更新時重新儲存 ────────────────────────────────────────────
    messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    // ── Foreground 訊息：審核結果 → 刷新 App 狀態 ──────────────────────
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] foreground message: ${message.notification?.title}');
      _handleStatusChange(message);
    });

    // ── 點擊通知開啟 App（背景 → 前景）→ 刷新 App 狀態 ─────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] opened from notification: ${message.notification?.title}');
      _handleStatusChange(message);
    });

    // ── 冷啟動：App 被通知喚醒時刷新狀態 ──────────────────────────────
    final initial = await messaging.getInitialMessage();
    if (initial != null) _handleStatusChange(initial);
  }

  static Future<void> _registerToken(FirebaseMessaging messaging) async {
    try {
      String? token;

      if (Platform.isIOS) {
        // iOS 需先確認 APNs token 存在才能取得 FCM token
        final apnsToken = await messaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('[FCM] APNs token 尚未就緒，跳過 FCM token 取得');
          return;
        }
      }

      token = await messaging.getToken();
      if (token != null) {
        await _saveToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] token 取得失敗：$e');
    }
  }

  /// 將 FCM token 儲存到 Supabase device_tokens 資料表
  static Future<void> _saveToken(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      debugPrint('[FCM] 用戶未登入，跳過 token 儲存');
      return;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      await Supabase.instance.client.from('device_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': platform,
        },
        onConflict: 'user_id, token',
      );
      debugPrint('[FCM] token 已儲存（$platform）');
    } catch (e) {
      debugPrint('[FCM] token 儲存失敗：$e');
    }
  }

  /// 登出時刪除 token，避免對已登出裝置發送推播
  static Future<void> deleteToken() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final token = await FirebaseMessaging.instance.getToken();

      if (user != null && token != null) {
        await Supabase.instance.client
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('token', token);
      }

      await FirebaseMessaging.instance.deleteToken();
      debugPrint('[FCM] token 已刪除');
    } catch (e) {
      debugPrint('[FCM] token 刪除失敗：$e');
    }
  }
}
