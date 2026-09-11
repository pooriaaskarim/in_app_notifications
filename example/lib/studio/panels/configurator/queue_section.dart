import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_notification_queue/flutter_notification_queue.dart';

import '../../bloc/setup_bloc.dart';
import '../../models/channel_setup.dart';
import '../../models/queue_setup.dart';
import '../../studio_theme.dart';
import '../../widgets/queue_position_map.dart';
import '../../widgets/studio_dropdown_tile.dart';
import '../../widgets/studio_section_header.dart';
import '../../widgets/studio_slider_tile.dart';
import '../../widgets/studio_toggle_tile.dart';
import 'relocation_selector.dart';

/// A section that manages the creation, deletion, and configuration of
/// [NotificationQueue] instances.
///
/// It provides a high-level selector for active queues and handles the "Add
/// Queue" logic, enforcing the rule that only "unused" positions (neither
/// Masters nor Slaves) can be configured.
class QueueSection extends StatelessWidget {
  const QueueSection({
    required this.setupState,
    super.key,
  });

  final SetupState setupState;

  @override
  Widget build(final BuildContext context) {
    final activeQueue =
        setupState.setup.queues[setupState.activeQueuePosition] ??
            const QueueSetup();

    final allSlaves = setupState.setup.queues.values
        .expand((final q) => q.relocateTargets)
        .toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const StudioSectionHeader(title: 'QUEUES'),
            const Spacer(),
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                size: 18,
                color: StudioTheme.colorScheme.primary,
              ),
              tooltip: 'Add queue position',
              onPressed: () {
                final availablePositions = QueuePosition.values
                    .where(
                      (final p) =>
                          !setupState.setup.queues.containsKey(p) &&
                          !allSlaves.contains(p),
                    )
                    .toList();
                if (availablePositions.length == 1) {
                  context
                      .read<SetupBloc>()
                      .add(AddQueue(availablePositions.first));
                } else {
                  _showAddQueueDialog(context);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // ── 9-Cell Position Map ──
        QueuePositionMap(
          queues: setupState.setup.queues,
          selectedPosition: setupState.activeQueuePosition,
          onSelect: (final pos) =>
              context.read<SetupBloc>().add(SelectActiveQueue(pos)),
          onAdd: (final pos) => context.read<SetupBloc>().add(AddQueue(pos)),
          onRemove: (final pos) => _showConfirmDeleteDialog(
            context,
            pos,
            setupState.setup.channels.values.toList(),
            () => context.read<SetupBloc>().add(RemoveQueue(pos)),
          ),
        ),
        const SizedBox(height: 16),
        _QueueEditor(
          position: setupState.activeQueuePosition,
          setup: activeQueue,
        ),
      ],
    );
  }

  /// Shows a dialog to select a new queue position to configure.
  ///
  /// Only positions that are not currently Masters (already have a queue)
  /// and are not Slaves (relocation targets for other queues) are shown.
  void _showAddQueueDialog(final BuildContext context) {
    final allSlaves = setupState.setup.queues.values
        .expand((final q) => q.relocateTargets)
        .toSet();
    showDialog(
      context: context,
      builder: (final ctx) => AlertDialog(
        title: const Text('Add Queue Position'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: QueuePosition.values
              .where(
                (final p) =>
                    !setupState.setup.queues.containsKey(p) &&
                    !allSlaves.contains(p),
              )
              .map(
                (final p) => ListTile(
                  title: Text(p.name.toUpperCase()),
                  onTap: () {
                    context.read<SetupBloc>().add(AddQueue(p));
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

/// A specialized editor for a single [QueueSetup].
class _QueueEditor extends StatelessWidget {
  const _QueueEditor({
    required this.position,
    required this.setup,
  });

  final QueuePosition position;
  final QueueSetup setup;

  static const _styleTypes = [
    FilledQueueStyle,
    FlatQueueStyle,
    OutlinedQueueStyle,
  ];
  static const _behaviorTypes = [
    Disabled,
    Dismiss,
    Reorder,
    Relocate,
    ReorderAndRelocate,
  ];
  static const _closeButtonTypes = [AlwaysVisible, VisibleOnHover, Hidden];
  static const _transitionTypes = [
    SlideTransitionStrategy,
    FadeTransitionStrategy,
    ScaleTransitionStrategy,
  ];
  static const _tapBehaviorTypes = [
    TapToDismiss,
    TapToExpand,
    TapToAct,
    TapDisabled,
  ];

  String _formatBehaviorType(final Type t) => switch (t) {
        == Disabled => 'DISABLED',
        == Dismiss => 'DISMISS',
        == Reorder => 'REORDER',
        == Relocate => 'RELOCATE',
        == ReorderAndRelocate => 'REORDER & RELOCATE',
        _ => t.toString().toUpperCase(),
      };

  @override
  Widget build(final BuildContext context) {
    final colorScheme = StudioTheme.colorScheme;
    final studioSetup = context.watch<SetupBloc>().state.setup;
    final otherQueuesSlaves = studioSetup.queues.entries
        .where((final entry) => entry.key != position)
        .expand((final entry) => entry.value.relocateTargets)
        .toSet();
    final activePositions = studioSetup.queues.keys.toSet();
    final channels = studioSetup.channels.values.toList();

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (setup.dragBehaviorType == setup.longPressBehaviorType &&
                setup.dragBehaviorType != Disabled) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Both gestures are set to '
                        '${_formatBehaviorType(setup.dragBehaviorType)}. '
                        'You might want to use different behaviors for better '
                        'interaction.',
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Icon(
                  Icons.settings_input_component,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${position.name.toUpperCase()} CONFIGURATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (activePositions.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: () => _showConfirmDeleteDialog(
                      context,
                      position,
                      channels,
                      () =>
                          context.read<SetupBloc>().add(RemoveQueue(position)),
                    ),
                    tooltip: 'Remove queue',
                  ),
              ],
            ),
            const Divider(height: 24),
            StudioSliderTile(
              label: 'MAX VISIBLE NOTIFICATIONS',
              value: setup.maxStackSize.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(maxStackSize: v.round()),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioToggleTile(
              label: 'CUSTOM MAX WIDTH',
              value: setup.maxWidth != null,
              onChanged: (final enable) {
                context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(
                          maxWidth: enable ? 360.0 : null,
                          clearMaxWidth: !enable,
                        ),
                      ),
                    );
              },
            ),
            if (setup.maxWidth != null) ...[
              const SizedBox(height: 12),
              StudioSliderTile(
                label: 'MAX CARD WIDTH (PX)',
                value: setup.maxWidth!,
                min: 200,
                max: 600,
                divisions: 40,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(maxWidth: v),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'VISUAL STYLE',
              value: setup.styleType,
              items: _styleTypes,
              itemLabel: (final t) => switch (t) {
                == FilledQueueStyle => 'FILLED',
                == FlatQueueStyle => 'FLAT',
                == OutlinedQueueStyle => 'OUTLINED',
                _ => t.toString().replaceAll('QueueStyle', '').toUpperCase(),
              },
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(styleType: v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'TRANSITION STRATEGY',
              value: setup.transitionType,
              items: _transitionTypes,
              itemLabel: (final t) => switch (t) {
                == SlideTransitionStrategy => 'SLIDE',
                == FadeTransitionStrategy => 'FADE',
                == ScaleTransitionStrategy => 'SCALE',
                _ => t
                    .toString()
                    .replaceAll('TransitionStrategy', '')
                    .toUpperCase(),
              },
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(transitionType: v),
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            const StudioSectionHeader(title: 'BEHAVIOR'),
            StudioDropdownTile<Type>(
              label: 'DRAG BEHAVIOR',
              value: setup.dragBehaviorType,
              items: _behaviorTypes.where((final e) {
                if (e == Relocate || e == ReorderAndRelocate) {
                  return activePositions.length < QueuePosition.values.length ||
                      setup.dragBehaviorType == e;
                }
                return true;
              }).toList(),
              itemLabel: _formatBehaviorType,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(dragBehaviorType: v),
                    ),
                  ),
            ),
            if (setup.dragBehaviorType == Relocate ||
                setup.dragBehaviorType == ReorderAndRelocate) ...[
              const SizedBox(height: 12),
              RelocationSelector(
                selected: setup.relocateTargets,
                activePositions: activePositions,
                otherQueuesSlaves: otherQueuesSlaves,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(relocateTargets: v),
                      ),
                    ),
              ),
            ],
            if (setup.dragBehaviorType == Dismiss) ...[
              const SizedBox(height: 12),
              StudioDropdownTile<DismissZone>(
                label: 'DRAG DISMISS ZONE',
                value: setup.dragDismissZone,
                items: DismissZone.values,
                itemLabel: (final e) => switch (e) {
                  DismissZone.sideEdges => 'SIDE EDGES (LEFT / RIGHT)',
                  DismissZone.naturalDirection =>
                    'NATURAL DIRECTION (UP / DOWN)',
                },
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(dragDismissZone: v),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'LONG PRESS DRAG BEHAVIOR',
              value: setup.longPressBehaviorType,
              items: _behaviorTypes.where((final e) {
                if (e == Relocate || e == ReorderAndRelocate) {
                  return activePositions.length < QueuePosition.values.length ||
                      setup.longPressBehaviorType == e;
                }
                return true;
              }).toList(),
              itemLabel: _formatBehaviorType,
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(longPressBehaviorType: v),
                    ),
                  ),
            ),
            if (setup.longPressBehaviorType == Relocate ||
                setup.longPressBehaviorType == ReorderAndRelocate) ...[
              const SizedBox(height: 12),
              RelocationSelector(
                selected: setup.relocateTargets,
                activePositions: activePositions,
                otherQueuesSlaves: otherQueuesSlaves,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(relocateTargets: v),
                      ),
                    ),
              ),
            ],
            if (setup.longPressBehaviorType == Dismiss) ...[
              const SizedBox(height: 12),
              StudioDropdownTile<DismissZone>(
                label: 'LONG PRESS DISMISS ZONE',
                value: setup.longPressDismissZone,
                items: DismissZone.values,
                itemLabel: (final e) => switch (e) {
                  DismissZone.sideEdges => 'SIDE EDGES (LEFT / RIGHT)',
                  DismissZone.naturalDirection =>
                    'NATURAL DIRECTION (UP / DOWN)',
                },
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(longPressDismissZone: v),
                      ),
                    ),
              ),
            ],
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'CLOSE BUTTON VISIBILITY',
              value: setup.closeButtonBehaviorType,
              items: _closeButtonTypes,
              itemLabel: (final e) => switch (e) {
                == AlwaysVisible => 'ALWAYS VISIBLE',
                == VisibleOnHover => 'VISIBLE ON HOVER',
                == Hidden => 'HIDDEN',
                _ => e.toString().toUpperCase(),
              },
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(closeButtonBehaviorType: v),
                    ),
                  ),
            ),
            const SizedBox(height: 12),
            StudioDropdownTile<Type>(
              label: 'TAP BEHAVIOR',
              value: setup.tapBehaviorType,
              items: _tapBehaviorTypes,
              itemLabel: (final e) => switch (e) {
                == TapToDismiss => 'DISMISS',
                == TapToExpand => 'EXPAND / COLLAPSE',
                == TapToAct => 'ACT (CALLBACK)',
                == TapDisabled => 'DISABLED',
                _ => e.toString().toUpperCase(),
              },
              onChanged: (final v) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(tapBehaviorType: v),
                    ),
                  ),
            ),
            if (setup.tapBehaviorType == TapToAct) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.code_rounded,
                      size: 13,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'In production, supply a TapToAct(onTap: fn) '
                        'callback on the queue or per-notification.',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            const StudioSectionHeader(title: 'GROUPING'),
            StudioToggleTile(
              label: 'ENABLE BUNDLING',
              value: setup.groupingEnabled,
              onChanged: (final enable) => context.read<SetupBloc>().add(
                    UpdateQueue(
                      position,
                      setup.copyWith(groupingEnabled: enable),
                    ),
                  ),
            ),
            if (setup.groupingEnabled) ...[
              const SizedBox(height: 12),
              StudioSliderTile(
                label: 'BUNDLE AFTER (N CARDS)',
                value: setup.groupingThreshold.toDouble(),
                min: 2,
                max: 10,
                divisions: 8,
                onChanged: (final v) => context.read<SetupBloc>().add(
                      UpdateQueue(
                        position,
                        setup.copyWith(groupingThreshold: v.round()),
                      ),
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.secondary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.layers_outlined,
                        size: 13,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cards sharing the same channelName (or groupKey) '
                        'collapse into a bundle once their count reaches the '
                        'threshold. Swipe the visible card — only that one '
                        'exits. Hidden members’ timers are suspended while '
                        'off-screen.',
                        style: TextStyle(
                          fontSize: 10,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _DismissGroupButton(position: position),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact action button in the GROUPING section that calls
/// [NotificationController.dismissGroup] for the 'chat'
/// channel group key.
///
/// Demonstrates the explicit bulk-dismiss API introduced in G-03.
class _DismissGroupButton extends StatelessWidget {
  const _DismissGroupButton({required this.position});

  final QueuePosition position;

  /// The group key used by the Chat Burst / Group Dismiss scenarios.
  static const _defaultGroupKey = 'chat';

  @override
  Widget build(final BuildContext context) => SizedBox(
        width: double.infinity,
        child: Tooltip(
          message: "Calls coordinator.dismissGroup('$_defaultGroupKey') — "
              'clears the entire bundle atomically.',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF06B6D4)
                  : const Color(0xFF0E7490),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF06B6D4)
                    : const Color(0xFF0E7490),
                width: 1,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              backgroundColor: (Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF06B6D4)
                      : const Color(0xFF0E7490))
                  .withValues(alpha: 0.06),
            ),
            icon: const Icon(Icons.layers_clear_outlined, size: 14),
            label: const Text('DISMISS ACTIVE GROUP'),
            onPressed: () => NotificationScope.of(context).dismissGroup(
              _defaultGroupKey,
            ),
          ),
        ),
      );
}

/// A validation dialog to confirm removal of a queue position, warning about
/// any affected channels.
void _showConfirmDeleteDialog(
  final BuildContext context,
  final QueuePosition position,
  final List<ChannelSetup> channels,
  final VoidCallback onConfirm,
) {
  final colorScheme = StudioTheme.colorScheme;
  final affectedChannels = channels
      .where((final c) => c.position == position)
      .map((final c) => c.name.toUpperCase())
      .toList();

  showDialog(
    context: context,
    builder: (final ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
            size: 22,
          ),
          const SizedBox(width: 8),
          const Text('Delete Queue Position?'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to remove the queue at '
            '${position.name.toUpperCase()}?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This will delete its configuration, and any notifications routed '
            'here will fallback to the remaining active queues.',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          if (affectedChannels.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'AFFECTED CHANNELS:',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: colorScheme.error,
              ),
            ),
            const SizedBox(height: 4),
            ...affectedChannels.map(
              (final name) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Row(
                  children: [
                    Icon(
                      Icons.subdirectory_arrow_right_rounded,
                      size: 12,
                      color: colorScheme.error.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            'Cancel',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}
