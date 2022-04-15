import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

/// Статусы выполнения верификации
enum VerificationStatus {
  /// Успешно
  success,

  /// Повторить верификаию
  repeat,

  /// Отменено пользователем
  canceled,

  /// Ошибка
  error,

  /// Приложение биометрии не установлено
  appNotInstalled,
}

const _statusMap = {
  'SUCCESS': VerificationStatus.success,
  'REPEAT': VerificationStatus.repeat,
  'CANCELED': VerificationStatus.canceled,
  'ERROR': VerificationStatus.error,
  'APP_NOT_INSTALLED': VerificationStatus.appNotInstalled,
};

/// Результат верификации через ЕСИА
@immutable
class EsiaVerificationResult {
  const EsiaVerificationResult({
    required final this.status,
    final this.esiaCode,
    final this.esiaState,
  });

  const EsiaVerificationResult._error()
      : status = VerificationStatus.error,
        esiaCode = null,
        esiaState = null;

  factory EsiaVerificationResult.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return const EsiaVerificationResult._error();
    if (!map.containsKey('status')) return const EsiaVerificationResult._error();

    final status = _statusMap[map['status']] ?? VerificationStatus.error;

    if (status != VerificationStatus.success) {
      return EsiaVerificationResult(status: status);
    }

    final esiaCode = map['esiaCode'];
    final esiaState = map['esiaState'];

    if ([esiaState, esiaCode].any((element) => element == null || element is! String)) {
      return const EsiaVerificationResult._error();
    }

    return EsiaVerificationResult(
      status: status,
      esiaCode: esiaCode as String,
      esiaState: esiaState as String,
    );
  }

  /// Статус верификации
  final VerificationStatus status;

  /// Код авторизации через ЕСИА
  final String? esiaCode;

  /// Стейт верификации
  final String? esiaState;

  @override
  String toString() => '$EsiaVerificationResult(${describeEnum(status)}, $esiaCode, $esiaState)';
}

/// Результат верификации через биометрию
@immutable
class EbsVerificationResult {
  const EbsVerificationResult({
    required final this.status,
    final this.ebsToken,
    final this.ebsTokenExpired,
  });

  const EbsVerificationResult._error()
      : status = VerificationStatus.error,
        ebsToken = null,
        ebsTokenExpired = null;

  factory EbsVerificationResult.fromMap(Map<Object?, Object?>? map) {
    if (map == null) return const EbsVerificationResult._error();
    if (!map.containsKey('status')) return const EbsVerificationResult._error();

    final status = _statusMap[map['status']] ?? VerificationStatus.error;

    if (status != VerificationStatus.success) {
      return EbsVerificationResult(status: status);
    }

    final ebsToken = map['ebsToken'];
    final ebsTokenExpired = map['ebsTokenExpired'];

    if ([ebsToken, ebsTokenExpired].any((element) => element == null || element is! String)) {
      return const EbsVerificationResult._error();
    }

    return EbsVerificationResult(
      status: status,
      ebsToken: ebsToken as String,
      ebsTokenExpired: ebsTokenExpired as String,
    );
  }

  /// Статус верификации
  final VerificationStatus status;

  /// Код авторизации через биометрию
  final String? ebsToken;

  /// Стейт верификации
  final String? ebsTokenExpired;

  @override
  String toString() =>
      '$EbsVerificationResult(${describeEnum(status)}, $ebsToken, $ebsTokenExpired)';
}
