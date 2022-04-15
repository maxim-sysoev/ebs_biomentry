import 'dart:async';

import 'package:ebs_biometry/response/esia_verification_result.dart';
import 'package:flutter/services.dart';

class EbsBiometry {
  static const MethodChannel _channel = MethodChannel('ru.surfstudio/ebs_biometry');

  /// Конфигурация sdk
  static Future<bool> configureSdk({
    required String appScheme,
    required String infoSystem,
    String? appTitle,
  }) {
    return _channel.invokeMethod<bool>('configureSdk', {
      'appScheme': appScheme,
      'infoSystem': infoSystem,
      'appTitle': appTitle ?? '',
    }).then((value) => value ?? false);
  }

  /// Есть права на запуск верификации (только android)
  static Future<bool> hasVerificationPermission() {
    return _channel.invokeMethod<bool>('hasVerificationPermission').then((value) => value ?? false);
  }

  /// Запрос прав на запуск верификации (только android)
  static Future<bool> requestVerificationPermission() {
    return _channel
        .invokeMethod<bool>('requestVerificationPermission')
        .then((value) => value ?? false);
  }

  /// Проверка установлено ли приложение биометрии
  static Future<bool> isEbsAppInstalled() {
    return _channel.invokeMethod<bool>('isEbsAppInstalled').then((value) => value ?? false);
  }

  /// Запросить установку приложения биометрия
  ///
  /// Откроется google play или app store
  static Future<void> requestInstallApp() {
    return _channel.invokeMethod('requestInstallApp');
  }

  /// Авторизация на госуслугах
  static Future<EsiaVerificationResult> requestEsiaVerification(
    String url,
  ) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>(
      'requestEsiaVerification',
      {
        'esiaVerificationUri': url,
      },
    );

    return EsiaVerificationResult.fromMap(result);
  }

  /// Верификация через биометрию
  static Future<EbsVerificationResult> requestEbsVerification(
    String ebsSessionId,
  ) async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>?>(
      'requestEbsVerification',
      {
        'ebsSessionId': ebsSessionId,
      },
    );

    return EbsVerificationResult.fromMap(result);
  }
}
