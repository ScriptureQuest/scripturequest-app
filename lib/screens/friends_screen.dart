import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:level_up_your_faith/providers/app_provider.dart';
import 'package:level_up_your_faith/models/friend_model.dart';
import 'package:level_up_your_faith/theme.dart';
import 'package:level_up_your_faith/widgets/home_action_button.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        final list = provider.friends;
        return Scaffold(
          appBar: AppBar(
            leading: Navigator.of(context).canPop()
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: GamerColors.accent),
                    onPressed: () => context.pop(),
                  )
                : null,
            title: Text('Friends', style: Theme.of(context).textTheme.headlineSmall),
            centerTitle: true,
            actions: const [HomeActionButton()],
          ),
          body: list.isEmpty
              ? _EmptyFriends()
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final f = list[index];
                    return _FriendRow(friend: f);
                  },
                ),
        );
      },
    );
  }
}

class _EmptyFriends extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: GamerColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GamerColors.accent.withValues(alpha: 0.2), width: 1),
              ),
              child: Column(
                children: [
                  const Icon(Icons.group_off, color: GamerColors.textSecondary, size: 48),
                  const SizedBox(height: 12),
                  Text('No friends yet', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Your journey is personal. Add friends anytime.',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: GamerColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Journey Board entry removed from UI per spec. Keep empty space minimal.
          ],
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  final FriendModel friend;
  const _FriendRow({required this.friend});

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    return InkWell(
      onTap: () => context.push('/player/${friend.id}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GamerColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GamerColors.accent.withValues(alpha: 0.25), width: 1),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: GamerColors.neonCyan.withValues(alpha: 0.2),
              child: Text(
                _initials(friend.displayName),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(friend.displayName, style: Theme.of(context).textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    (friend.tagline ?? '').isNotEmpty ? friend.tagline! : 'Scripture Quest™ player',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(color: GamerColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: 'Remove friend',
              icon: const Icon(Icons.person_remove_alt_1_outlined, color: GamerColors.accent),
              onPressed: () async {
                await provider.removeFriend(friend.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removed from Friends')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
