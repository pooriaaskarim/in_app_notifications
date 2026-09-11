# Changelog

## [0.4.1] - 2026-09-12

### Studio & Web Deployment
- **Web Release Display Fix**: Fixed an issue in the Studio web app where configurator options and generated code snippets displayed minified type names in web release builds.

## [0.4.0] - 2026-08-30

### Breaking API Changes (Deprecated Surface Removal)
- **Removed Legacy Static Singleton Facade**: Removed `FlutterNotificationQueue` static facade. `NotificationController` and `NotificationScope` are now the canonical API for all notification queue management.
- **Removed `FnqEvent` Typedef**: Standardized on `sealed class NotificationEvent` for all lifecycle event subscriptions.
- **Removed Legacy Action Factory**: Removed `@Deprecated factory NotificationAction.onTap`. Use `NotificationAction.button` or gesture intents (`TapBehavior`, `DragBehavior`) instead.
- **Removed `NotificationWidget.show()`**: Notifications are dispatched as `AppNotification` payloads via `controller.show(...)` or `NotificationScope.of(context).show(...)`.

## [0.3.2] - 2026-08-26

### Studio Application & Web Deployment
- **GitHub Pages CI/CD Workflow**: Added automated GitHub Actions workflow (`deploy_pages.yml`) to compile and deploy the NFQ Studio web app (`example/`) to GitHub Pages on version tag pushes (`v*`).
- **Interactive Web Demo Link**: Integrated a prominent `img.shields.io` for-the-badge demo button in `README.md` directing users to the hosted NFQ Studio live web app.
- **Mobile Floating Action Button (FAB)**: Added a scroll-responsive floating action button in NFQ Studio for narrow screen viewports, enabling instant notification preview triggers on mobile devices.

## [0.3.1] - 2026-08-14

### Memory Teardown & Resource Hardening
- **Automated Timer Teardown**: Added `ditchAllDismissTimers()` to `QueueWidgetState` and integrated it into `QueueCoordinator.dispose()` to ensure active tickers and auto-dismiss timers across all registered queues stop immediately on coordinator/controller disposal.
- **Animation Ticker Teardown**: Prevented active `_snapBackController` animation leaks in `DraggableTransitionsState` and invoked `ditchDismissTimer()` prior to disposing `NotificationWidgetState`.
- **OverlayPortal Controller Teardown**: Ensured `OverlayPortalController` and scope bindings detach cleanly on widget unmounting.

### Test Suite Hardening
- **Multi-Tenant Scope Verification**: Added unit and widget test suite in `notification_scope_test.dart` covering multi-tenant subtree isolation, scope nesting overrides, unmount detachment, and graceful timer teardown.

## [0.3.0] - 2026-08-14

### Architectural Evolution (v1.0 Preparation)
- **`NotificationController` Facade**: Introduced an explicit `NotificationController` to own configuration (`queues`, `channels`), active state, event streams, and history logging. Replaces global static state with clean dependency injection.
- **`NotificationScope` Integration**: Introduced `NotificationScope` (`StatefulWidget` & `InheritedWidget`) to provide scoped access to `NotificationController` via `NotificationScope.of(context)`.
- **`AppNotification` Intent Payload**: Separated data payload from widget rendering state. Applications dispatch immutable `AppNotification` payloads via `controller.show(AppNotification(...))`.
- **Expanded Controller Surface**: Added `show`, `tryShow`, `dismiss`, `dismissAll`, `dismissNewest`, `dismissGroup`, `relocate`, `reorder`, `snooze`, `pin`, `unpin`, `getHistory`, `clearHistory`, and `events` directly to `NotificationController`.
- **Sealed Event Hierarchy**: Renamed `FnqEvent` base class to `NotificationEvent` (`typedef FnqEvent = NotificationEvent` provided for backward compatibility).
- **Deprecation Path**: Marked `FlutterNotificationQueue`, `NotificationWidget.show()`, and direct `NotificationWidget` instantiation as `@Deprecated`. See `doc/migration_v0_4.md` for complete migration guidance.

### Bug Fixes & Stability
- **Reorder & Relocate Null Safety**: Resolved unexpected `null` value errors and unmounted state crashes during card reordering and relocation interactions.
- **Context-Aware Scope Resolution**: Implemented a 3-tier coordinator lookup hierarchy (`explicit -> NotificationScope.maybeCoordinatorOf(context) -> FlutterNotificationQueue.coordinator`) across UI overlay, queue widgets, and draggable transitions, preventing scoped `NotificationController` instances from defaulting to global static singletons.
- **Blueprint Coordinator Preservation**: Preserved `coordinator` references across `copyToQueue` (relocation) and `copyForRequeue` (snooze) blueprint copies.
- **Unmounted Timer Prevention**: Prevented calling `initDismissTimer()` on unmounting notification states after successful relocation.

### Documentation & Tooling
- **Migration Guide**: Added comprehensive migration documentation in `doc/migration_v0_4.md`.
- **Studio Application**: Refactored `example/` Studio app to showcase `NotificationController` and `NotificationScope` patterns.

## [0.2.0] - 2026-07-19

### Consolidated API & Subclass Removal
- **Simplified NotificationQueue:** Removed all 8 specialized subclasses (`TopLeftQueue`, etc.) in favor of a single, highly configurable concrete `NotificationQueue` class with a `const` constructor.
- **QueuePosition Helpers:** Simplified `generateQueue()` on `QueuePosition` to directly build `NotificationQueue` instances, removing duplicate subclass-generation switch blocks.

### Internal State Decoupling
- **Introduced NotificationEntry:** Decoupled `NotificationWidget` configuration blueprint from active runtime state (dismiss timers, pinned lifecycle, resolved priority) by introducing the internal `NotificationEntry` wrapper class.
- **QueueCoordinator & Layout State:** Refactored state-storage maps and animation list managers to use `NotificationEntry`, preventing potential `GlobalKey` conflicts.

## [0.1.0] - 2026-07-10

### Initial Public Preview Baseline

All features from early pre-releases (`0.4.0` - `0.7.0`) consolidated into a single unified public baseline.

#### Interaction Engine (Physics & Reordering)
- **Reorder Behavior:** Users can pick up notifications and seamlessly rearrange them within their queue, empowering sophisticated inbox management.
- **Overlap Mechanics:** Replaced legacy gap-based targeting with a deeply physical "Overlap Target" model. The engine dynamically calculates the 2D bounding `Rect` of every active notification on the fly to yield precise target indices.
- **Perfect Deadband Hysteresis:** Implemented a "Gravity Well" (Target-Centric State) algorithm. The active drop zone applies a persistent 40-pixel magnetic lock to its own hit-test calculations, generating a flawless 80-pixel optical deadband that is 100% immune to pointer jitter, velocity spikes, and physical hand vibrations.
- **Premium Bounding Reticles:** Replaced the destructive horizontal center-line drop indicator with a Selection Reticle. Hovering over a card instantly frames its exterior in a glowing border while subtly darkening the interior (Recess Effect).
- **Self-Target Suppression:** The physics engine natively understands "cancel" drags. Hovering a payload over its own original starting slot visually suppresses all target feedback, rendering an empty placeholder hole so the user can comfortably drop the card back to safely abort.
- **Smooth Height & Spring Snapbacks:** Added dynamic height transitions when notifications expand or collapse, and physical spring snapback physics for aborted cancel drags.
- **Visual Grab Cursors:** Added grab and grabbing cursor states on draggable cards to improve desktop UX.

#### Layout, Grouping & Customization
- **Notification Grouping & Bundling:** Introduced dynamic stack configuration parameters (custom layer count, offsets, scales), recursive-safe swipe dismissals with reason propagation, and non-overlapping indicators with direction-aware tap-to-expand.
- **Visual Boundaries:** Added per-queue `maxWidth` constraints and layout collision delegate resolution.
- **Adaptive Close Button:** Opacity-based model (`0.0`–`1.0`) with subtle presence for touch devices (starts at `0.3` opacity for discoverability) and progressive enhancement (hidden until hover on desktop).
- **Hover-to-Pause Dismissal:** Hovering over a notification card pauses its auto-dismiss timer, which resumes smoothly when the pointer leaves.

#### Core API & Observability
- **Dynamic Channel Parking:** Introduced runtime routing updates where dragging/relocating a notification card dynamically updates the routing rules for all future notifications of its channel.
- **Event History Log:** Added an in-memory, LIFO bounded ring buffer (`maxHistoryEntries`) to capture notification events. Added `getHistory()` for querying with filters (channelName, dismissReason, since, limit) and `clearHistory()` for cache management.
- **Zero-overhead Disabling:** When disabled (`maxHistoryEntries` is set to `0` or less), the history subscription is completely cancelled and detached, guaranteeing zero runtime performance or memory overhead.
- **Logd Core Integration:** Upgraded logging package to `logd` version `^0.8.6` and integrated package-wide structured log handlers.
- **Stable Event Proxy:** Replaced transient event streams with a persistent broadcast proxy stream to prevent zombie listeners across configure/reset cycles.
- **Per-Notification Permanence:** Added `permanent: true` flag to individual `NotificationWidget`s to bypass channel-level default dismiss durations.
