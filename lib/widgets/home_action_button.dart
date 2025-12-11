import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeActionButton extends StatelessWidget {
  const HomeActionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Home',
      icon: const Icon(Icons.home_outlined),
      onPressed: () => context.go('/home'),
    );
  }
}
