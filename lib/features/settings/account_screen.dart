import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/status.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/cloud_save.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_gateway.dart';
import '../../state/cloud_store.dart';
import '../../state/cloud_sync.dart';
import '../../state/controller.dart';
import '../../state/course_state.dart';

/// Passwords shorter than this are refused before anything is sent.
const minPasswordLength = 8;

/// Maps a cloud or sign-in problem to a translated sentence.
String cloudErrorText(AppLocalizations l, Object error) {
  if (error is AuthProblemException) {
    return switch (error.problem) {
      AuthProblem.invalidEmail => l.errorInvalidEmail,
      AuthProblem.weakPassword => l.errorWeakPassword,
      AuthProblem.emailInUse => l.errorEmailInUse,
      AuthProblem.wrongCredentials => l.errorWrongCredentials,
      AuthProblem.network => l.errorNetwork,
      AuthProblem.tooManyRequests => l.errorTooMany,
      AuthProblem.disabled => l.errorDisabled,
      AuthProblem.notAllowed => l.errorNotAllowed,
      AuthProblem.recentLogin => l.errorRecentLogin,
      AuthProblem.other => l.errorGeneric,
    };
  }
  if (error is CloudException) {
    return switch (error.error) {
      CloudError.tooNew => l.errorTooNew,
      CloudError.damaged => l.errorDamaged,
      CloudError.noCourse => l.errorNoCourse,
      CloudError.tooBig => l.errorTooBig,
    };
  }
  if (error is CloudUnavailable) return l.errorNetwork;
  if (error is UnsavedProgress) return l.errorUnsaved;
  if (error is CloudRefused) return l.errorRefused;
  return l.errorGeneric;
}

String _syncText(AppLocalizations l, SyncStatus s, DateFormat fmt) => switch (s.phase) {
      SyncPhase.unavailable => l.cloudUnavailable,
      SyncPhase.signedOut => l.cloudSignedOut,
      SyncPhase.syncing => l.cloudSyncing,
      SyncPhase.offline => l.cloudOffline,
      SyncPhase.error => l.cloudError,
      SyncPhase.conflict => l.cloudConflict,
      SyncPhase.idle => s.pending
          ? l.cloudPending
          : s.lastSynced == null
              ? l.cloudSignedOut
              : l.cloudSaved(fmt.format(s.lastSynced!.toLocal())),
    };

/// The title of a restore point: its own text for a milestone, else the
/// translated reason.
String pointTitle(AppLocalizations l, CloudCheckpoint p) => switch (p.reason) {
      CheckpointReason.milestone when p.label.isNotEmpty => p.label,
      CheckpointReason.milestone || CheckpointReason.daily => l.pointDaily,
      CheckpointReason.replaced => l.pointReplaced,
      CheckpointReason.reset => l.pointReset,
    };

bool _looksLikeEmail(String v) {
  final t = v.trim();
  return t.contains('@') && t.contains('.') && !t.contains(' ');
}

/// Shows what a restore point holds and puts it back if the learner agrees.
/// Returns true when the progress was replaced.
Future<bool> confirmAndRestore(
  BuildContext context,
  WidgetRef ref,
  CloudCheckpoint point,
) async {
  final l = AppLocalizations.of(context);
  final sum = summarize(point.save, preferredCourse: ref.read(activeCourseProvider));
  final date = DateFormat.yMMMd(l.localeName).add_Hm().format(point.createdAt.toLocal());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.restoreConfirmTitle),
      content: Text(l.restoreConfirmBody(date, sum.xp, sum.lessons, sum.streak)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.restoreConfirmAction),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await ref.read(cloudSyncProvider.notifier).restoreCheckpoint(point);
  } catch (e) {
    if (context.mounted) showToast(context, cloudErrorText(l, e), kind: StatusKind.error);
    return false;
  }
  if (context.mounted) showToast(context, l.restoreDone, kind: StatusKind.success);
  return true;
}

/// Lets the learner choose between this phone and the account. Returns true
/// when a choice was made. "Decide later" returns false and changes nothing.
Future<bool> showConflictDialog(
  BuildContext context,
  WidgetRef ref,
  SyncConflict conflict,
) async {
  final l = AppLocalizations.of(context);
  final fmt = DateFormat.yMMMd(l.localeName).add_Hm();
  final active = ref.read(activeCourseProvider);
  Widget card(String title, CloudSave save) {
    final sum = summarize(save, preferredCourse: active);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(l.pointSummary(sum.xp, sum.lessons, sum.streak)),
            Text(
              fmt.format(sum.savedAt.toLocal()),
              style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  final choice = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(l.conflictTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.conflictBody),
            const SizedBox(height: 8),
            card(l.conflictPhone, conflict.local),
            card(l.conflictAccount, conflict.cloud),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.conflictLater),
        ),
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.conflictUsePhone),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.conflictUseAccount),
        ),
      ],
    ),
  );
  if (choice == null || !context.mounted) return false;
  try {
    await ref.read(cloudSyncProvider.notifier).resolveConflict(useCloud: choice);
  } catch (e) {
    if (context.mounted) showToast(context, cloudErrorText(l, e), kind: StatusKind.error);
    return false;
  }
  if (choice && context.mounted) showToast(context, l.restoreDone, kind: StatusKind.success);
  return true;
}

/// Opens the choice between this phone and the account as soon as a sync
/// finds both changed. Asked once per cloud save, so "Decide later" is not
/// nagged; the account screen offers the choice again.
class ConflictHost extends ConsumerStatefulWidget {
  const ConflictHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ConflictHost> createState() => _ConflictHostState();
}

class _ConflictHostState extends ConsumerState<ConflictHost> {
  bool _open = false;
  int? _askedFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeAsk(ref.read(cloudSyncProvider));
    });
  }

  void _maybeAsk(SyncStatus s) {
    final c = s.conflict;
    if (s.phase != SyncPhase.conflict || c == null || _open || _askedFor == c.cloud.rev) {
      return;
    }
    _open = true;
    _askedFor = c.cloud.rev;
    showConflictDialog(context, ref, c).whenComplete(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cloudSyncProvider, (_, next) => _maybeAsk(next));
    return widget.child;
  }
}

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  List<CloudCheckpoint>? _points;
  String? _loadedFor;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) {
        showToast(context, cloudErrorText(AppLocalizations.of(context), e),
            kind: StatusKind.error);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadPoints() async {
    try {
      final list = await ref.read(cloudSyncProvider.notifier).loadCheckpoints();
      if (mounted) setState(() => _points = list);
    } catch (_) {
      // Offline: the list stays as it was.
    }
  }

  /// Fills the list once per account, and again after a restore or a sync.
  void _maybeLoad(SyncStatus s) {
    final uid = s.user?.uid;
    if (uid == null || _loadedFor == uid) return;
    _loadedFor = uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPoints();
    });
  }

  Future<void> _create() => _run(() async {
        final l = AppLocalizations.of(context);
        if (!_looksLikeEmail(_email.text)) {
          return _toast(l.errorInvalidEmail);
        }
        if (_password.text.length < minPasswordLength) {
          return _toast(l.errorWeakPassword);
        }
        await ref.read(cloudSyncProvider.notifier).createAccount(_email.text, _password.text);
        _password.clear();
        await _loadPoints();
      });

  void _toast(String message) {
    if (mounted) showToast(context, message, kind: StatusKind.error);
  }

  Future<void> _signOut() async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.accountSignOut),
        content: Text(l.accountSignOutBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.accountSignOut),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      final navigator = Navigator.of(context);
      await ref.read(cloudSyncProvider.notifier).signOutAndClear();
      navigator.popUntil((route) => route.isFirst);
    });
  }

  Future<void> _delete(CloudUser user) async {
    final l = AppLocalizations.of(context);
    final needsPassword = !user.isAnonymous && user.email != null;
    final password = await showDialog<String>(
      context: context,
      builder: (_) => _DeleteDialog(askPassword: needsPassword),
    );
    if (password == null) return;
    await _run(() async {
      final navigator = Navigator.of(context);
      await ref.read(cloudSyncProvider.notifier).deleteAccount(password: password);
      if (mounted) showToast(context, l.accountDeleted, kind: StatusKind.info);
      navigator.popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = ref.watch(cloudSyncProvider);
    final user = s.user;
    final fmt = DateFormat.yMMMd(l.localeName).add_Hm();
    _maybeLoad(s);
    final live = s.phase != SyncPhase.unavailable;
    final canSync = live &&
        user != null &&
        s.phase != SyncPhase.syncing &&
        s.phase != SyncPhase.conflict;
    return Scaffold(
      appBar: AppBar(title: Text(l.accountTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _statusCard(context, l, s, fmt, canSync),
          if (live && user != null && user.isAnonymous) ..._createForm(context, l),
          if (live && user == null)
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
              ),
              child: Text(l.accountHaveAccount),
            ),
          if (live && user != null && !user.isAnonymous) ..._signedIn(context, l, user),
          if (live && user != null) ..._pointsSection(context, l, fmt),
          if (live && user != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _busy ? null : () => _delete(user),
              icon: const Icon(Icons.delete_outline_rounded, color: Palette.tomato),
              label: Text(l.accountDelete, style: const TextStyle(color: Palette.tomato)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusCard(
    BuildContext context,
    AppLocalizations l,
    SyncStatus s,
    DateFormat fmt,
    bool canSync,
  ) {
    final bad = s.phase == SyncPhase.error || s.phase == SyncPhase.conflict;
    final icon = switch (s.phase) {
      SyncPhase.idle => Icons.cloud_done_rounded,
      SyncPhase.syncing => Icons.cloud_sync_rounded,
      SyncPhase.error || SyncPhase.conflict => Icons.warning_amber_rounded,
      _ => Icons.cloud_off_rounded,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: bad ? Palette.tomato : Palette.teal, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _syncText(l, s, fmt),
                    key: const Key('cloud-status'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            if (s.phase == SyncPhase.conflict && s.conflict != null) ...[
              const SizedBox(height: 12),
              BigButton(
                label: l.cloudChoose,
                icon: Icons.compare_arrows_rounded,
                onPressed: () => showConflictDialog(context, ref, s.conflict!),
              ),
            ] else if (canSync) ...[
              const SizedBox(height: 12),
              BigButton.secondary(
                label: l.cloudSaveNow,
                icon: Icons.cloud_upload_rounded,
                onPressed: _busy
                    ? null
                    : () => _run(() => ref.read(cloudSyncProvider.notifier).syncNow()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _createForm(BuildContext context, AppLocalizations l) => [
        const SizedBox(height: 16),
        Text(l.accountIntroAnonymous),
        const SizedBox(height: 12),
        TextField(
          key: const Key('account-email'),
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(labelText: l.accountEmail),
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('account-password'),
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          decoration: InputDecoration(
            labelText: l.accountPassword,
            helperText: l.accountPasswordHint,
          ),
        ),
        const SizedBox(height: 12),
        BigButton(
          label: l.accountCreate,
          icon: Icons.person_add_alt_1_rounded,
          onPressed: _busy ? null : _create,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busy
              ? null
              : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
                  ),
          child: Text(l.accountHaveAccount),
        ),
      ];

  List<Widget> _signedIn(BuildContext context, AppLocalizations l, CloudUser user) => [
        const SizedBox(height: 16),
        Text(l.accountSignedInAs(user.email ?? ''),
            key: const Key('account-email-shown'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        BigButton.secondary(
          label: l.accountSignOut,
          icon: Icons.logout_rounded,
          onPressed: _busy ? null : _signOut,
        ),
      ];

  List<Widget> _pointsSection(BuildContext context, AppLocalizations l, DateFormat fmt) {
    final points = _points;
    final active = ref.read(activeCourseProvider);
    return [
      SectionTitle(l.pointsTitle),
      Text(l.pointsIntro, style: TextStyle(color: Theme.of(context).hintColor)),
      const SizedBox(height: 10),
      if (points != null && points.isEmpty)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(child: Text(l.pointsEmpty)),
        ),
      for (final p in points ?? const <CloudCheckpoint>[])
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            child: ListTile(
              leading: Icon(
                p.reason == CheckpointReason.milestone
                    ? Icons.emoji_events_rounded
                    : Icons.history_rounded,
                color: Palette.teal,
              ),
              title: Text(pointTitle(l, p),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text(() {
                final sum = summarize(p.save, preferredCourse: active);
                return '${fmt.format(p.createdAt.toLocal())}\n'
                    '${l.pointSummary(sum.xp, sum.lessons, sum.streak)}';
              }()),
              isThreeLine: true,
              trailing: TextButton(
                onPressed: _busy
                    ? null
                    : () => _run(() async {
                          if (await confirmAndRestore(context, ref, p)) {
                            await _loadPoints();
                          }
                        }),
                child: Text(l.pointRestore),
              ),
            ),
          ),
        ),
    ];
  }
}

/// Asks the learner to confirm the deletion, with their password when the
/// account has one. Owns its text controller for the life of the dialog.
class _DeleteDialog extends StatefulWidget {
  const _DeleteDialog({required this.askPassword});

  final bool askPassword;

  @override
  State<_DeleteDialog> createState() => _DeleteDialogState();
}

class _DeleteDialogState extends State<_DeleteDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.accountDelete),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.accountDeleteBody),
          if (widget.askPassword) ...[
            const SizedBox(height: 12),
            TextField(
              key: const Key('delete-password'),
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(labelText: l.accountDeletePassword),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Palette.tomato),
          onPressed: () => Navigator.pop(context, _password.text),
          child: Text(l.delete),
        ),
      ],
    );
  }
}

/// Signs in to an existing account. Used on the first-run screen and from the
/// account screen. A copy of progress on the phone and one in the account lead
/// to a choice, which [ConflictHost] asks for.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _toast(String message, {StatusKind kind = StatusKind.error}) {
    if (mounted) showToast(context, message, kind: kind);
  }

  Future<void> _signIn() async {
    final l = AppLocalizations.of(context);
    if (!_looksLikeEmail(_email.text)) return _toast(l.errorInvalidEmail);
    if (_password.text.isEmpty) return _toast(l.errorWrongCredentials);
    setState(() => _busy = true);
    try {
      final navigator = Navigator.of(context);
      final route = ModalRoute.of(context);
      final wasOnboarded = ref.read(appProvider).onboarded;
      await ref.read(cloudSyncProvider.notifier).signIn(_email.text, _password.text);
      if (!mounted) return;
      final ready = ref.read(appProvider).onboarded;
      if (!wasOnboarded && !ready) _toast(l.signInNoProgress, kind: StatusKind.info);
      // A choice dialog may already be open on top of this screen. Remove
      // this screen by itself instead of popping whatever is on top.
      if (route != null && route.isActive && !route.isFirst) navigator.removeRoute(route);
    } catch (e) {
      _toast(cloudErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _forgot() async {
    final l = AppLocalizations.of(context);
    if (!_looksLikeEmail(_email.text)) return _toast(l.errorInvalidEmail);
    setState(() => _busy = true);
    try {
      await ref.read(cloudSyncProvider.notifier).sendPasswordReset(_email.text);
      _toast(l.accountResetSent, kind: StatusKind.info);
    } catch (e) {
      // The same answer for every address, so nobody can probe for accounts.
      if (e is AuthProblemException && e.problem == AuthProblem.network) {
        _toast(cloudErrorText(l, e));
      } else {
        _toast(l.accountResetSent, kind: StatusKind.info);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.signInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('signin-email'),
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l.accountEmail),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('signin-password'),
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l.accountPassword),
          ),
          const SizedBox(height: 16),
          BigButton(
            label: l.accountSignIn,
            icon: Icons.login_rounded,
            onPressed: _busy ? null : _signIn,
          ),
          TextButton(
            onPressed: _busy ? null : _forgot,
            child: Text(l.accountForgot),
          ),
        ],
      ),
    );
  }
}
