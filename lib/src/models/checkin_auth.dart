import 'package:equatable/equatable.dart';

/// Authentication credentials for starting a Checkin.com verification flow.
///
/// The native SDK supports two authentication modes:
/// - [CheckinAuth.sdkKey] for development
/// - [CheckinAuth.jwt] for production (recommended)
sealed class CheckinAuth extends Equatable {
  const CheckinAuth();

  const factory CheckinAuth.sdkKey(String sdkKey) = CheckinSdkKeyAuth;
  const factory CheckinAuth.jwt(String token) = CheckinJwtAuth;

  String get type => switch (this) {
        CheckinSdkKeyAuth() => 'sdkKey',
        CheckinJwtAuth() => 'jwt',
      };

  String get value => switch (this) {
        CheckinSdkKeyAuth(:final sdkKey) => sdkKey,
        CheckinJwtAuth(:final token) => token,
      };

  Map<String, dynamic> toJson() => {
        'type': type,
        'value': value,
      };

  @override
  List<Object?> get props => [type, value];
}

final class CheckinSdkKeyAuth extends CheckinAuth {
  const CheckinSdkKeyAuth(this.sdkKey);

  final String sdkKey;

  @override
  List<Object?> get props => [sdkKey];
}

final class CheckinJwtAuth extends CheckinAuth {
  const CheckinJwtAuth(this.token);

  final String token;

  @override
  List<Object?> get props => [token];
}
