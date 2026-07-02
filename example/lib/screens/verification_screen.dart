import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_checkin_sdk/flutter_checkin_sdk.dart';

import '../providers/checkin_providers.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _apiUrlController = TextEditingController(
    text: 'https://picktify.getid.ee',
  );
  final _flowNameController = TextEditingController(
    text: 'IDscan-InstantLiv',
  );
  final _sdkKeyController = TextEditingController();
  final _jwtController = TextEditingController();
  final _externalIdController = TextEditingController(text: 'demo-user-1');

  StreamSubscription<VerificationEvent>? _subscription;
  bool _useJwt = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    final sdk = ref.read(checkinSdkProvider);
    try {
      await sdk.initialize();
      _subscription = sdk.events.listen(_handleEvent);
      _appendLog('Plugin initialized.');
      ref.read(verificationStatusProvider.notifier).state =
          VerificationStatus.idle;
    } on CheckinException catch (error) {
      _showError(error.message);
    }
  }

  void _handleEvent(VerificationEvent event) {
    switch (event) {
      case VerificationStarted():
        ref.read(verificationStatusProvider.notifier).state =
            VerificationStatus.inProgress;
        _appendLog('Verification started.');
      case VerificationCompleted(:final result):
        ref.read(verificationStatusProvider.notifier).state =
            VerificationStatus.completed;
        ref.read(lastApplicationIdProvider.notifier).state =
            result.applicationId;
        ref.read(lastErrorProvider.notifier).state = null;
        _appendLog('Verification completed: ${result.applicationId}');
      case VerificationCancelled():
        ref.read(verificationStatusProvider.notifier).state =
            VerificationStatus.cancelled;
        _appendLog('Verification cancelled by user.');
      case VerificationFailed(:final error):
        ref.read(verificationStatusProvider.notifier).state =
            VerificationStatus.failed;
        ref.read(lastErrorProvider.notifier).state = error.message;
        _appendLog('Verification failed: ${error.message}');
      case UnknownError(:final error):
        ref.read(verificationStatusProvider.notifier).state =
            VerificationStatus.failed;
        ref.read(lastErrorProvider.notifier).state = error.message;
        _appendLog('Unknown SDK event: ${error.message}');
      default:
        _appendLog('Received undocumented event: ${event.runtimeType}');
    }
  }

  Future<void> _startVerification() async {
    final sdk = ref.read(checkinSdkProvider);
    final authValue = _useJwt ? _jwtController.text : _sdkKeyController.text;

    if (authValue.trim().isEmpty) {
      _showError(_useJwt ? 'JWT is required.' : 'SDK key is required.');
      return;
    }

    setState(() => _isBusy = true);
    ref.read(verificationStatusProvider.notifier).state =
        VerificationStatus.initializing;
    ref.read(lastApplicationIdProvider.notifier).state = null;
    ref.read(lastErrorProvider.notifier).state = null;

    try {
      await sdk.startVerification(
        apiUrl: _apiUrlController.text.trim(),
        auth: _useJwt
            ? CheckinAuth.jwt(authValue.trim())
            : CheckinAuth.sdkKey(authValue.trim()),
        flowName: _flowNameController.text.trim(),
        locale: 'en',
        metadata: VerificationMetadata(
          externalId: _externalIdController.text.trim(),
          labels: const {'source': 'flutter-example'},
        ),
        profileData: const {
          'first-name': 'John',
          'last-name': 'Doe',
        },
      );
      _appendLog('Verification flow requested.');
    } on CheckinException catch (error) {
      ref.read(verificationStatusProvider.notifier).state =
          VerificationStatus.failed;
      ref.read(lastErrorProvider.notifier).state = error.message;
      _showError(error.message);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _cancelVerification() async {
    final sdk = ref.read(checkinSdkProvider);
    try {
      await sdk.cancel();
      _appendLog('Cancel requested.');
    } on UnsupportedCheckinException catch (error) {
      _showError(error.message);
    } on CheckinException catch (error) {
      _showError(error.message);
    }
  }

  void _appendLog(String message) {
    final current = List<String>.from(ref.read(eventLogProvider));
    current.insert(0, '${TimeOfDay.now().format(context)} — $message');
    ref.read(eventLogProvider.notifier).state = current;
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _apiUrlController.dispose();
    _flowNameController.dispose();
    _sdkKeyController.dispose();
    _jwtController.dispose();
    _externalIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(verificationStatusProvider);
    final applicationId = ref.watch(lastApplicationIdProvider);
    final error = ref.watch(lastErrorProvider);
    final logs = ref.watch(eventLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkin.com Verification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Status: ${status.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (applicationId != null)
            Text('Application ID: $applicationId'),
          if (error != null)
            Text(
              'Error: $error',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _apiUrlController,
            decoration: const InputDecoration(
              labelText: 'API URL',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _flowNameController,
            decoration: const InputDecoration(
              labelText: 'Flow name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _externalIdController,
            decoration: const InputDecoration(
              labelText: 'External ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Use JWT (production)'),
            subtitle: const Text('Disable to use SDK key for development'),
            value: _useJwt,
            onChanged: (value) => setState(() => _useJwt = value),
          ),
          if (_useJwt)
            TextField(
              controller: _jwtController,
              decoration: const InputDecoration(
                labelText: 'JWT',
                border: OutlineInputBorder(),
              ),
            )
          else
            TextField(
              controller: _sdkKeyController,
              decoration: const InputDecoration(
                labelText: 'SDK key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isBusy ? null : _startVerification,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Start verification'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _cancelVerification,
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Cancel'),
          ),
          const SizedBox(height: 24),
          Text(
            'Event log',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...logs.map(
            (entry) => ListTile(
              dense: true,
              leading: const Icon(Icons.bolt_outlined),
              title: Text(entry),
            ),
          ),
        ],
      ),
    );
  }
}
