import 'package:stash/core/theme/app_theme.dart';
import 'package:stash/data/settings/settings_repository.dart';
import 'package:stash/features/shell/shell_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/providers/app_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: BudgetApp()));
}

class BudgetApp extends ConsumerWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final s = settings ?? const AppSettings();
    final theme = s.colorMode == ColorMode.dark
        ? AppTheme.dark(fontSize: s.fontSize)
        : AppTheme.light(fontSize: s.fontSize);
    return MaterialApp(
      title: 'Budget App',
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const DatabaseGate(child: ShellScreen()),
    );
  }
}

/// Ensures Isar is open and categories seeded before showing the shell.
class DatabaseGate extends ConsumerStatefulWidget {
  const DatabaseGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DatabaseGate> createState() => _DatabaseGateState();
}

class _DatabaseGateState extends ConsumerState<DatabaseGate> {
  @override
  Widget build(BuildContext context) {
    final isarAsync = ref.watch(isarProvider);
    final categoryRepo = ref.watch(categoryRepositoryProvider);

    return isarAsync.when(
      data: (_) {
        if (categoryRepo != null) {
          categoryRepo.seedIfEmpty();
        }
        return widget.child;
      },
      loading: () => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Opening database...',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Database error: $e')),
      ),
    );
  }
}
