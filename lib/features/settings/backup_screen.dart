import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/status.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/backup.dart';
import '../../l10n/app_localizations.dart';
import '../../state/backup_files.dart';
import '../../state/backup_service.dart';

/// Maps a backup problem to a translated sentence.
String backupErrorText(AppLocalizations l, Object error) {
  if (error is BackupException) {
    return switch (error.error) {
      BackupError.unreadable => l.errorUnreadable,
      BackupError.notMultilingo => l.errorNotMultilingo,
      BackupError.tooNew => l.errorTooNew,
      BackupError.damaged => l.errorDamaged,
      BackupError.noCourse => l.errorNoCourse,
    };
  }
  return l.errorGeneric;
}

/// Shows what a backup contains and restores it if the learner agrees.
/// Returns true when progress was replaced. Shared by this screen, the
/// restore points list and the first-run screen.
Future<bool> confirmAndRestore(
  BuildContext context,
  WidgetRef ref,
  BackupEnvelope env,
) async {
  final l = AppLocalizations.of(context);
  final service = ref.read(backupServiceProvider);
  final BackupSummary summary;
  try {
    summary = service.summarize(env);
  } catch (e) {
    showToast(context, backupErrorText(l, e), kind: StatusKind.error);
    return false;
  }
  final date = DateFormat.yMMMd(l.localeName).add_Hm().format(summary.createdAt.toLocal());
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l.restoreConfirmTitle),
      content: Text(l.restoreConfirmBody(
        date,
        summary.xp,
        summary.lessons,
        summary.streak,
      )),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l.restoreConfirmAction),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return false;
  try {
    await service.restore(env);
  } catch (e) {
    if (context.mounted) showToast(context, backupErrorText(l, e), kind: StatusKind.error);
    return false;
  }
  if (context.mounted) showToast(context, l.restoreDone, kind: StatusKind.success);
  return true;
}

/// Lets the learner choose a backup file and restore it.
Future<bool> importFromFile(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final BackupEnvelope env;
  try {
    final text = await ref.read(backupFilesProvider).pickText();
    if (text == null) return false; // cancelled
    env = BackupEnvelope.decode(text);
  } catch (e) {
    if (context.mounted) showToast(context, backupErrorText(l, e), kind: StatusKind.error);
    return false;
  }
  if (!context.mounted) return false;
  return confirmAndRestore(context, ref, env);
}

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  DateTime? _fileTime;

  @override
  void initState() {
    super.initState();
    _readFileTime();
  }

  Future<void> _readFileTime() async {
    final file = await ref.read(backupServiceProvider).rollingFile();
    final time = await file.exists() ? await file.lastModified() : null;
    if (mounted) setState(() => _fileTime = time);
  }

  Future<void> _run(Future<void> Function() job) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) showToast(context, backupErrorText(AppLocalizations.of(context), e), kind: StatusKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() => _run(() async {
        final l = AppLocalizations.of(context);
        final file = await ref.read(backupServiceProvider).writeRolling();
        final saved = await ref.read(backupFilesProvider).saveAs(await file.readAsBytes());
        if (saved && mounted) showToast(context, l.backupSaved, kind: StatusKind.success);
        await _readFileTime();
      });

  Future<void> _share(Rect? origin) => _run(() async {
        final file = await ref.read(backupServiceProvider).writeRolling();
        await ref.read(backupFilesProvider).share(file, origin: origin);
        await _readFileTime();
      });

  Future<void> _import() => _run(() async {
        await importFromFile(context, ref);
      });

  Future<String?> _askLabel({String? initial, required String title}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _LabelDialog(title: title, initial: initial),
    );
  }

  Future<void> _createCheckpoint() => _run(() async {
        final l = AppLocalizations.of(context);
        final label = await _askLabel(title: l.checkpointCreate);
        if (label == null) return;
        await ref.read(backupServiceProvider).createCheckpoint(label);
        if (mounted) {
          setState(() {});
          showToast(context, l.checkpointCreated, kind: StatusKind.success);
        }
      });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final service = ref.watch(backupServiceProvider);
    final points = service.checkpoints();
    final fmt = DateFormat.yMMMd(l.localeName).add_Hm();
    return Scaffold(
      appBar: AppBar(title: Text(l.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.backupIntro),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l.backupFileCard,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(l.backupFileName(backupFileName)),
                  if (_fileTime != null)
                    Text(fmt.format(_fileTime!.toLocal()),
                        style: TextStyle(color: Theme.of(context).hintColor)),
                  const SizedBox(height: 4),
                  Text(l.backupFileHint,
                      style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12)),
                  const SizedBox(height: 14),
                  BigButton(
                    label: l.backupSaveButton,
                    icon: Icons.save_alt_rounded,
                    onPressed: _busy ? null : _save,
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (btn) => BigButton.secondary(
                      label: l.backupShareButton,
                      icon: Icons.ios_share_rounded,
                      onPressed: _busy
                          ? null
                          : () {
                              final box = btn.findRenderObject() as RenderBox?;
                              final origin = box == null || !box.hasSize
                                  ? null
                                  : box.localToGlobal(Offset.zero) & box.size;
                              _share(origin);
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  BigButton.secondary(
                    label: l.backupImportButton,
                    icon: Icons.upload_file_rounded,
                    onPressed: _busy ? null : _import,
                  ),
                ],
              ),
            ),
          ),
          SectionTitle(l.checkpointsTitle),
          Text(l.checkpointsIntro,
              style: TextStyle(color: Theme.of(context).hintColor)),
          const SizedBox(height: 10),
          BigButton.secondary(
            label: l.checkpointCreate,
            icon: Icons.add_rounded,
            onPressed: _busy ? null : _createCheckpoint,
          ),
          const SizedBox(height: 10),
          if (points.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text(l.checkpointsEmpty)),
            ),
          for (final p in points) _checkpointTile(context, l, service, p, fmt),
        ],
      ),
    );
  }

  Widget _checkpointTile(
    BuildContext context,
    AppLocalizations l,
    BackupService service,
    BackupEnvelope p,
    DateFormat fmt,
  ) {
    final sum = service.summarize(p);
    final title = p.kind == BackupKind.auto && p.label == 'Automatic'
        ? l.checkpointAuto
        : p.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: ListTile(
          leading: Icon(
            p.kind == BackupKind.auto ? Icons.history_rounded : Icons.bookmark_rounded,
            color: Palette.teal,
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(
            '${fmt.format(p.createdAt.toLocal())}\n'
            '${l.checkpointSummary(sum.xp, sum.lessons, sum.streak)}',
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            enabled: !_busy,
            onSelected: (v) => _onMenu(v, p),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'restore', child: Text(l.checkpointRestore)),
              if (p.kind == BackupKind.manual)
                PopupMenuItem(value: 'rename', child: Text(l.checkpointRename)),
              PopupMenuItem(value: 'delete', child: Text(l.checkpointDelete)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onMenu(String action, BackupEnvelope p) => _run(() async {
        final l = AppLocalizations.of(context);
        final service = ref.read(backupServiceProvider);
        switch (action) {
          case 'restore':
            await confirmAndRestore(context, ref, p);
          case 'rename':
            final label = await _askLabel(initial: p.label, title: l.checkpointRename);
            if (label != null) await service.renameCheckpoint(p.id, label);
          case 'delete':
            await service.deleteCheckpoint(p.id);
            if (mounted) showToast(context, l.checkpointDeleted, kind: StatusKind.info);
        }
        if (mounted) setState(() {});
      });
}

/// Asks for a short name. Owns its text controller, so the controller lives
/// exactly as long as the dialog, including its closing animation.
class _LabelDialog extends StatefulWidget {
  const _LabelDialog({required this.title, this.initial});

  final String title;
  final String? initial;

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: maxLabelLength,
        decoration: InputDecoration(labelText: l.checkpointLabelField),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(l.save),
        ),
      ],
    );
  }
}
