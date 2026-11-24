import 'package:flutter/material.dart';

abstract final class CampusColors {
  static const mint = Color(0xFFBFEBDD);
  static const mintSoft = Color(0xFFDFF5EC);
  static const background = Color(0xFFF0FAF6);
  static const primary = Color(0xFF246B57);
  static const ink = Color(0xFF1C3D33);
  static const muted = Color(0xFF5A756B);
  static const outline = Color(0xFFCCE6DC);
}

ThemeData campusTheme({Brightness brightness = Brightness.light}) {
  final dark = brightness == Brightness.dark;
  final scheme =
      ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: CampusColors.mint,
        primary: dark ? const Color(0xFF9FDBC5) : CampusColors.primary,
        secondary: dark ? const Color(0xFFBCDACC) : CampusColors.ink,
        surface: dark ? const Color(0xFF182C26) : Colors.white,
      ).copyWith(
        primaryContainer: dark
            ? const Color(0xFF284D40)
            : CampusColors.mintSoft,
        onPrimaryContainer: dark ? const Color(0xFFD5F4E6) : CampusColors.ink,
        onSurface: dark ? const Color(0xFFE3F2EB) : CampusColors.ink,
        onSurfaceVariant: dark ? const Color(0xFFB1C9BD) : CampusColors.muted,
        outlineVariant: dark ? const Color(0xFF3A5649) : CampusColors.outline,
      );
  final text = ThemeData(brightness: brightness).textTheme.apply(
    fontFamily: 'LibreFranklin',
    bodyColor: scheme.onSurface,
    displayColor: scheme.onSurface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'LibreFranklin',
    brightness: brightness,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF10221B)
        : CampusColors.background,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF10221B) : CampusColors.background,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'LibreFranklin',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    textTheme: text.copyWith(
      headlineMedium: text.headlineMedium?.copyWith(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontSize: 21,
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: text.bodyMedium?.copyWith(height: 1.5),
    ),
    cardTheme: CardThemeData(
      color: scheme.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.all(16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: scheme.primaryContainer,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'LibreFranklin',
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
  );
}

class StudentHeading extends StatelessWidget {
  const StudentHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: .9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class StudentStatePanel extends StatelessWidget {
  const StudentStatePanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
    this.loading = false,
  });
  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final bool loading;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            CircularProgressIndicator(semanticsLabel: title)
          else
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          if (action != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    ),
  );
}
