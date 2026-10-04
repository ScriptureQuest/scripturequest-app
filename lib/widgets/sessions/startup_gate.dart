import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';

/// Protect every entry route, including direct links, while startup is unsettled.
class StartupGate extends StatelessWidget {
  final Widget child;
  const StartupGate({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    if (app.initializationError != null)
      return Scaffold(
        body: SafeArea(
            child: Center(
                child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cloud_off_outlined, size: 40),
                  const SizedBox(height: 16),
                  Text('Your reading space could not open',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  const Text(
                      'Startup did not finish. Retry will reload your saved data; nothing will be reset. If this continues, contact support before changing or clearing storage.'),
                  const SizedBox(height: 24),
                  FilledButton(
                      onPressed: app.startInitialization,
                      child: const Text('Retry')),
                ],
              )),
        ))),
      );
    if (!app.isInitialized)
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator(
                  semanticsLabel: 'Opening your saved reading space')));
    return child;
  }
}
