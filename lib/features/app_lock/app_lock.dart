/// App lock and app-switcher privacy (proposal section 11; mockup
/// `AppLock.dc.html`). Public file of the feature.
library;

export 'presentation/app_lock_gate.dart' show AppLockGate;
export 'presentation/app_lock_sheet.dart' show AppLockSheet, showAppLockSheet;
export 'presentation/lock_screen.dart' show LockScreen;
export 'presentation/providers/app_lock_providers.dart' show AppLockRefusal, appLockClockProvider, appLockProvider;
