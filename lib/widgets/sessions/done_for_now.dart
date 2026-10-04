import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_provider.dart';
import '../../models/connected/passage_reference.dart';
import '../../services/sessions/session_return.dart';

class DoneForNow extends StatefulWidget {
  final PassageReference passage;
  final VoidCallback? onDone;
  const DoneForNow({super.key, required this.passage, this.onDone});
  @override
  State<DoneForNow> createState() => _DoneForNowState();
}

class _DoneForNowState extends State<DoneForNow> {
  bool busy = false;
  String? error;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 12),
        const Text('You can pause here. Continue when you’re ready.'),
        TextButton.icon(
            icon: const Icon(Icons.check_circle_outline),
            label: Text(busy ? 'Keeping your return point…' : 'Done for now'),
            onPressed: busy
                ? null
                : () async {
                    setState(() {
                      busy = true;
                      error = null;
                    });
                    try {
                      await SessionReturn.save(
                          context.read<AppProvider>().currentUser!.id,
                          widget.passage);
                      if (!context.mounted) return;
                      if (widget.onDone != null) {
                        widget.onDone!();
                      } else {
                        context.go('/');
                      }
                    } catch (_) {
                      if (mounted)
                        setState(() => error =
                            'Could not keep your return point. Your earned progress is unchanged. Retry when ready.');
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  }),
        if (error != null) Semantics(liveRegion: true, child: Text(error!)),
      ]);
}
