import 'dart:async';

import 'package:flutter/services.dart';

import '../constants.dart';
import '../events/verification_event.dart';
import '../exceptions/checkin_exception.dart';
import '../models/verification_session.dart';
import 'checkin_platform_interface.dart';

/// Method channel implementation of [CheckinPlatform].
final class MethodChannelCheckinPlatform extends CheckinPlatform {
  MethodChannelCheckinPlatform({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel =
            methodChannel ?? const MethodChannel(CheckinChannels.methodChannel),
        _eventChannel =
            eventChannel ?? const EventChannel(CheckinChannels.eventChannel);

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  Stream<VerificationEvent>? _events;

  @override
  Stream<VerificationEvent> get events {
    return _events ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => VerificationEvent.fromJson(
              Map<dynamic, dynamic>.from(event as Map),
            ))
        .handleError((Object error, StackTrace stackTrace) {
      throw _mapError(error);
    });
  }

  @override
  Future<void> initialize() async {
    try {
      await _methodChannel.invokeMethod<void>(CheckinMethods.initialize);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<void> startVerification(VerificationSession session) async {
    try {
      await _methodChannel.invokeMethod<void>(
        CheckinMethods.startVerification,
        session.toJson(),
      );
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _methodChannel.invokeMethod<void>(CheckinMethods.cancel);
    } on PlatformException catch (error) {
      throw _mapPlatformException(error);
    }
  }

  CheckinException _mapPlatformException(PlatformException error) {
    return mapPlatformException(
      code: error.code,
      message: error.message ?? 'A platform error occurred.',
      details: error.details?.toString(),
    );
  }

  Never _mapError(Object error) {
    if (error is CheckinException) {
      throw error;
    }
    if (error is PlatformException) {
      throw _mapPlatformException(error);
    }
    throw UnknownCheckinException(
      errorCode: 'UNKNOWN',
      message: error.toString(),
    );
  }
}
