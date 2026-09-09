import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/notification_bloc.dart';
import 'bloc/studio_bloc.dart';
import 'panels/code_editor_panel.dart';
import 'panels/configurator_panel.dart';
import 'panels/event_log_panel.dart';
import 'studio_theme.dart';

/// The root layout for NFQ Studio.
///
/// Provides [StudioBloc] and renders a responsive split-pane layout:
/// - **Wide screens**: Configurator (left) + Code Editor (right)
/// - **Narrow screens**: Tabbed view with bottom navigation & preview FAB
class StudioHome extends StatelessWidget {
  const StudioHome({super.key});

  @override
  Widget build(final BuildContext context) => const _StudioShell();
}

class _StudioShell extends StatefulWidget {
  const _StudioShell();

  @override
  State<_StudioShell> createState() => _StudioShellState();
}

class _StudioShellState extends State<_StudioShell> {
  int _tabIndex = 0;
  bool _isFabVisible = true;
  Timer? _hideTimer;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onUserScroll(final UserScrollNotification notification) {
    if (notification.direction == ScrollDirection.reverse) {
      _hideTimer?.cancel();
      if (_isFabVisible) {
        setState(() => _isFabVisible = false);
      }
    } else if (notification.direction == ScrollDirection.forward) {
      _hideTimer?.cancel();
      if (!_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    } else if (notification.direction == ScrollDirection.idle) {
      _scheduleFabShow();
    }
  }

  void _scheduleFabShow() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 1000), () {
      if (mounted && !_isFabVisible) {
        setState(() => _isFabVisible = true);
      }
    });
  }

  @override
  Widget build(final BuildContext context) => LayoutBuilder(
        builder: (final context, final constraints) {
          final isNarrow = constraints.maxWidth <= 1000;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'NFQ STUDIO',
                    style: TextStyle(
                      letterSpacing: 4,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(width: 8),
                  _VersionBadge(),
                ],
              ),
              centerTitle: true,
              backgroundColor: Theme.of(context)
                  .colorScheme
                  .surface
                  .withValues(alpha: 0.85),
              elevation: 0,
              actions: [
                BlocBuilder<StudioBloc, StudioState>(
                  builder: (final context, final state) => IconButton(
                    onPressed: () {
                      context.read<StudioBloc>().add(const ToggleTheme());
                    },
                    icon: Icon(
                      state.themeMode == ThemeMode.dark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    tooltip: 'Toggle Theme',
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: Stack(
              children: [
                const _StudioBackground(),
                SafeArea(
                  child: isNarrow ? _narrowLayout() : _wideLayout(),
                ),
              ],
            ),
            floatingActionButton: isNarrow && _tabIndex == 0
                ? AnimatedSlide(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _isFabVisible ? 0.85 : 0.0,
                      child: FloatingActionButton(
                        onPressed: () {
                          context
                              .read<NotificationBloc>()
                              .add(const FirePreview());
                        },
                        backgroundColor:
                            StudioTheme.colorScheme.primaryContainer,
                        foregroundColor:
                            StudioTheme.colorScheme.onPrimaryContainer,
                        elevation: 4,
                        tooltip: 'Fire Notification',
                        child: const Icon(Icons.send_rounded, size: 20),
                      ),
                    ),
                  )
                : null,
            bottomNavigationBar: isNarrow
                ? BottomNavigationBar(
                    currentIndex: _tabIndex,
                    onTap: (final i) => setState(() => _tabIndex = i),
                    backgroundColor: StudioTheme.colorScheme.surface,
                    selectedItemColor: StudioTheme.colorScheme.primary,
                    unselectedItemColor: StudioTheme.colorScheme.onSurface
                        .withValues(alpha: 0.38),
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.tune),
                        label: 'Configure',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.code),
                        label: 'Code',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.stream_rounded),
                        label: 'Events',
                      ),
                    ],
                  )
                : null,
          );
        },
      );

  Widget _wideLayout() => Row(
        children: [
          const Expanded(child: ConfiguratorPanel()),
          Container(
            width: 1,
            color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const Expanded(child: CodeEditorPanel()),
          Container(
            width: 1,
            color: StudioTheme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 280, child: EventLogPanel()),
        ],
      );

  Widget _narrowLayout() => NotificationListener<UserScrollNotification>(
        onNotification: (final notification) {
          _onUserScroll(notification);
          return false;
        },
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            ConfiguratorPanel(),
            CodeEditorPanel(),
            EventLogPanel(),
          ],
        ),
      );
}

class _StudioBackground extends StatelessWidget {
  const _StudioBackground();

  @override
  Widget build(final BuildContext context) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-0.8, -0.8),
            radius: 1.5,
            colors: [
              StudioTheme.colorScheme.surface,
              StudioTheme.theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      StudioTheme.colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
            ),
          ],
        ),
      );
}

class _VersionBadge extends StatefulWidget {
  const _VersionBadge();

  @override
  State<_VersionBadge> createState() => _VersionBadgeState();
}

class _VersionBadgeState extends State<_VersionBadge> {
  late final Future<String?> _versionFuture;

  @override
  void initState() {
    super.initState();
    _versionFuture = _loadVersion();
  }

  static Future<String?> _loadVersion() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final assetKeys = manifest.listAssets();
      for (final key in assetKeys.where(
        (final k) => k.contains('pubspec.yaml'),
      )) {
        try {
          final content = await rootBundle.loadString(key);
          final match =
              RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(content);
          if (match?.group(1) != null) {
            return match!.group(1);
          }
        } on Object catch (_) {}
      }
    } on Object catch (_) {}

    final candidates = [
      '../pubspec.yaml',
      'pubspec.yaml',
      'assets/pubspec.yaml',
    ];

    for (final candidate in candidates) {
      try {
        final content = await rootBundle.loadString(candidate);
        final match =
            RegExp(r'^version:\s*([^\s+]+)', multiLine: true).firstMatch(content);
        if (match?.group(1) != null) {
          return match!.group(1);
        }
      } on Object catch (_) {}
    }
    return null;
  }

  @override
  Widget build(final BuildContext context) => FutureBuilder<String?>(
        future: _versionFuture,
        builder: (final context, final snapshot) {
          final version = snapshot.data;
          if (version == null || version.isEmpty) {
            return const SizedBox.shrink();
          }
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'v$version',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          );
        },
      );
}
