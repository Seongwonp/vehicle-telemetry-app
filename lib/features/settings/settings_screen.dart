import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/token_storage.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';
import '../landing/landing_screen.dart';
import '../../core/theme/design_tokens.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String? _username;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final username = await TokenStorage.getUsername();
    if (mounted) {
      setState(() {
        _username = username;
        _loading = false;
      });
    }
  }

  Future<void> _logout() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LandingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final themePreference = ref.watch(themePreferenceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      Spacing.md, Spacing.md, Spacing.md, Spacing.xl),
                  children: [
                    const _SectionLabel('계정'),
                    _SettingsCard(
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: '아이디',
                          value: _username ?? '알 수 없음',
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.lg),
                    const _SectionLabel('화면'),
                    _SettingsCard(
                      children: [
                        _ThemeSelector(
                          selected: themePreference,
                          onChanged: (preference) => ref
                              .read(themePreferenceProvider.notifier)
                              .setPreference(preference),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xl),
                    OutlinedButton.icon(
                      onPressed: _logout,
                      icon: Icon(Icons.logout, color: colors.danger),
                      label:
                          Text('로그아웃', style: TextStyle(color: colors.danger)),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: Spacing.md),
                        side: BorderSide(color: colors.danger, width: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.xxs, 0, 0, Spacing.xs),
      child: Text(
        text,
        style: TextStyle(
          fontSize: FontSizes.caption,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.textSecondary),
          const SizedBox(width: Spacing.sm),
          Text(label,
              style: TextStyle(
                  fontSize: FontSizes.body, color: colors.textSecondary)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: FontSizes.body, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppThemePreference selected;
  final ValueChanged<AppThemePreference> onChanged;

  const _ThemeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.sm),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<AppThemePreference>(
          segments: const [
            ButtonSegment(
              value: AppThemePreference.system,
              icon: Icon(Icons.brightness_auto_outlined),
              label: Text('시스템'),
            ),
            ButtonSegment(
              value: AppThemePreference.light,
              icon: Icon(Icons.light_mode_outlined),
              label: Text('라이트'),
            ),
            ButtonSegment(
              value: AppThemePreference.dark,
              icon: Icon(Icons.dark_mode_outlined),
              label: Text('다크'),
            ),
          ],
          selected: {selected},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.single),
        ),
      ),
    );
  }
}
