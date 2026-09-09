// ignore_for_file: comment_references

part of 'behaviors.dart';

/// Controls when and how the close button appears on notifications.
///
/// The close button's visibility is expressed as an **opacity** value
/// (`0.0`–`1.0`) rather than a boolean, enabling smooth animated transitions
/// and platform-adaptive behavior without explicit device detection.
///
/// ### Implementations
///
/// | Behavior         | Resting | On Hover | Touch Devices          |
/// |------------------|---------|----------|------------------------|
/// | [AlwaysVisible]  | `1.0`   | `1.0`    | Always fully visible   |
/// | [VisibleOnHover] | `0.3`*  | `1.0`    | Subtly visible (0.3)   |
/// | [Hidden]         | `0.0`   | `0.0`    | Invisible, untappable  |
///
/// *`VisibleOnHover` uses progressive enhancement: it starts at `0.3`
/// (safe for touch), then upgrades to true hide/reveal (`0.0`/`1.0`)
/// once a mouse hover event is detected.
///
/// ### Zombie Prevention
///
/// [Hidden] removes the close button entirely. If used, the queue **must**
/// provide at least one other dismissal method (drag or long-press drag),
/// or `ConfigurationManager` will throw an [ArgumentError].
///
/// See also:
/// - `ConfigurationManager` input resilience validation, which enforces this.
sealed class QueueCloseButtonBehavior {
  /// Creates a close button behavior.
  const QueueCloseButtonBehavior();

  /// The button's resting opacity before any interaction.
  ///
  /// Returns a value between `0.0` (invisible) and `1.0` (fully visible).
  double get initialOpacity;

  /// Returns the target opacity in response to a mouse hover event.
  ///
  /// [isHovering] is `true` when the pointer enters, `false` when it exits.
  ///
  /// This is driven by [MouseRegion], which only fires for mouse pointers —
  /// never for touch. On touch-only devices, this method is never called
  /// and the button remains at [initialOpacity].
  double onHover({required final bool isHovering});
}

/// The close button is always fully visible (`1.0`), on every platform.
///
/// This is the default behavior and the safest choice — the button is
/// always visible and always tappable.
///
/// ```dart
/// NotificationQueue(
///   closeButtonBehavior: const AlwaysVisible(), // default
/// )
/// ```
final class AlwaysVisible extends QueueCloseButtonBehavior {
  /// Creates a behavior where the close button is always fully visible.
  ///
  /// Opacity is always `1.0` regardless of hover state or platform.
  /// This is the default for [NotificationQueue].
  const AlwaysVisible();

  @override
  double get initialOpacity => 1.0;

  @override
  double onHover({required final bool isHovering}) => 1.0;
}

/// The close button uses **progressive enhancement** to adapt to the
/// user's actual input device:
///
/// 1. **Before any hover**: the button renders at `0.3` opacity —
///    visible enough to discover and tap, but visually de-emphasized.
/// 2. **On first mouse hover**: the system detects that a mouse is present
///    and permanently upgrades to true hide/reveal (`0.0` → `1.0`).
/// 3. **After upgrade**: the button is fully hidden at rest and appears
///    only on hover, matching desktop conventions.
///
/// This approach is **evidence-based** rather than platform-based:
/// - A Surface Pro in tablet mode → no hover fires → stays at `0.3` ✓
/// - The same Surface Pro with a mouse → hover fires → upgrades ✓
/// - An iPad with a Magic Keyboard trackpad → hover fires → upgrades ✓
///
/// ```dart
/// NotificationQueue(
///   closeButtonBehavior: const VisibleOnHover(),
/// )
/// ```
final class VisibleOnHover extends QueueCloseButtonBehavior {
  /// Creates a behavior that adapts to the user's input device.
  ///
  /// Starts at `0.3` opacity (discoverable on touch), then upgrades
  /// to true hide/reveal (`0.0`/`1.0`) on the first mouse hover event.
  const VisibleOnHover();

  /// Flips to `true` the moment any hover event fires, proving a mouse
  /// is present. Once detected, it stays detected for the session.
  /// Global across all [VisibleOnHover] instances.
  static bool _mouseDetected = false;

  /// Resets the mouse-detection flag.
  ///
  /// Called during test teardowns to prevent test pollution
  /// between test runs that exercise hover interactions.
  static void resetMouseDetection() => _mouseDetected = false;

  @override
  double get initialOpacity => _mouseDetected ? 0.0 : 0.3;

  @override
  double onHover({required final bool isHovering}) {
    _mouseDetected = true;
    return isHovering ? 1.0 : 0.0;
  }
}

/// The close button is completely hidden (`0.0`) and non-interactive.
///
/// > **⚠️ Zombie Prevention**: Using [Hidden] requires the queue to have
/// > at least one gesture-based dismissal method (drag or long-press drag).
/// > Otherwise, notifications become undismissable "zombies" and
/// > [ConfigurationManager] will throw an [ArgumentError] at initialization.
///
/// ```dart
/// NotificationQueue(
///   closeButtonBehavior: const Hidden(),
///   dragBehavior: const Dismiss(), // Required!
/// )
/// ```
final class Hidden extends QueueCloseButtonBehavior {
  /// Creates a behavior where the close button is completely hidden.
  ///
  /// The button is invisible and non-interactive (opacity `0.0`).
  /// Requires an alternative dismissal method (e.g. `const Dismiss()`).
  const Hidden();

  @override
  double get initialOpacity => 0.0;

  @override
  double onHover({required final bool isHovering}) => 0.0;
}
