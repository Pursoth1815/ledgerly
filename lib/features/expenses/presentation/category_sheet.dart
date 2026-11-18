import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ledger/ledger_defaults.dart';
import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_check.dart';
import '../../../design_system/components/loopd_chip.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_glyph.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'providers/expense_providers.dart';

/// Opens Expense categories (mockup `CategorySheet.dc.html`, screen 10c):
/// every category with its icon, colour and this month's spending. Tapping
/// one edits it; New category adds one (screen 10d). Categories you added
/// can be deleted, several at once; their expenses move to Misc or another
/// category you choose. All of it stays in this one tall sheet, and the back
/// arrow or the phone's back returns to the list. There is no close button
/// (owner, 18 Nov 2026): swipe it down or press back on the list.
Future<void> showCategorySheet(BuildContext context, {DateTime Function() clock = DateTime.now}) =>
    showLoopdSheet<void>(
      context: context,
      tall: true,
      builder: (_) => CategorySheet(clock: clock),
    );

/// Opens the New category form on its own, as from the expense form, and
/// returns the new category's id, or null when closed without adding.
Future<String?> showNewCategorySheet(BuildContext context) =>
    showLoopdSheet<String>(context: context, tall: true, builder: (_) => const CategorySheet(startNew: true));

/// The category sheet: the list, the form to add or edit one, or choosing
/// ones to delete. One widget, as in the mockups; a Vault mode (screen 10e)
/// joins it with the Vault.
class CategorySheet extends ConsumerStatefulWidget {
  const CategorySheet({this.startNew = false, this.clock = DateTime.now, super.key});

  /// Open straight on the New category form, with no list to go back to.
  /// Adding closes the sheet with the new category's id.
  final bool startNew;
  final DateTime Function() clock;

  static const nameFieldKey = ValueKey('category-name');
  static const listKey = ValueKey('category-list');

  /// Said when every colour and icon is taken, here and in the expense form.
  static const fullMessage = 'You have ${LedgerEngine.categoryMax} categories, the most there can be';

  @override
  ConsumerState<CategorySheet> createState() => _CategorySheetState();
}

enum _View { list, form, select }

class _CategorySheetState extends ConsumerState<CategorySheet> {
  late _View _view = widget.startNew ? _View.form : _View.list;

  /// The category being edited; null on the New category form.
  LedgerCategory? _editing;

  /// Categories ticked for deleting.
  final _selected = <String>{};

  void _openForm(LedgerCategory? category) => setState(() {
    _editing = category;
    _view = _View.form;
  });

  void _backToList() => setState(() {
    _view = _View.list;
    _selected.clear();
  });

  void _startSelecting([LedgerCategory? first]) => setState(() {
    _view = _View.select;
    _selected.clear();
    if (first != null && !first.builtIn) _selected.add(first.id);
  });

  void _toggle(LedgerCategory category) => setState(() {
    if (!_selected.remove(category.id)) _selected.add(category.id);
  });

  /// Asks where their expenses go, then deletes [doomed].
  Future<void> _delete(List<LedgerCategory> doomed, List<LedgerCategory> all) async {
    if (doomed.isEmpty) return;
    final ledger = ref.read(ledgerEngineProvider);
    final ids = [for (final k in doomed) k.id];
    final count = await ledger.countCategoryExpenses(ids);
    if (!mounted) return;
    final moveTo = await showLoopdSheet<String>(
      context: context,
      builder: (_) => _DeleteSheet(
        doomed: doomed,
        expenses: count,
        targets: [
          for (final k in all)
            if (!ids.contains(k.id)) k,
        ],
      ),
    );
    if (moveTo == null || !mounted) return;
    try {
      await ledger.deleteCategories(ids, moveTo: moveTo);
    } on LedgerException {
      if (mounted) showLoopdToast(context, 'Could not delete. Try again.');
      return;
    }
    if (!mounted) return;
    final what = doomed.length == 1 ? doomed.single.name : '${doomed.length} categories';
    final target = all.firstWhere((k) => k.id == moveTo).name;
    showLoopdToast(context, count == 0 ? 'Deleted $what' : 'Deleted $what · expenses moved to $target');
    _backToList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final now = widget.clock();
    final spendingAsync = ref.watch(categorySpendingProvider(DateTime(now.year, now.month)));
    final failed = categoriesAsync.hasError || spendingAsync.hasError;
    final ready = categoriesAsync.hasValue && spendingAsync.hasValue;
    final title = switch (_view) {
      _View.list => 'Expense categories',
      _View.select => 'Delete categories',
      _View.form => _editing == null ? 'New category' : 'Edit category',
    };

    Widget body;
    if (failed) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LoopdErrorNote('Categories could not be loaded. Close this and open it again.'),
      );
    } else if (!ready) {
      body = const SizedBox.expand();
    } else if (_view == _View.form) {
      body = _CategoryForm(
        key: ValueKey(_editing?.id ?? 'new'),
        editing: _editing,
        categories: categoriesAsync.requireValue,
        onDone: (id, name) {
          if (widget.startNew) {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop(id);
            return;
          }
          showLoopdToast(context, _editing == null ? 'Added $name' : 'Saved $name');
          _backToList();
        },
      );
    } else {
      final all = categoriesAsync.requireValue;
      body = _CategoryList(
        key: CategorySheet.listKey,
        categories: all,
        spending: spendingAsync.requireValue,
        selecting: _view == _View.select,
        selected: _selected,
        onOpen: _openForm,
        onNew: () => _openForm(null),
        onToggle: _toggle,
        onStartSelecting: _startSelecting,
        onDelete: () => _delete([
          for (final k in all)
            if (_selected.contains(k.id)) k,
        ], all),
      );
    }

    final editing = _editing;
    final canDeleteThis = _view == _View.form && editing != null && !editing.builtIn;
    final inner = _view != _View.list && !widget.startNew;
    // Inside the sheet, the phone's back goes to the list, as the arrow does.
    return PopScope<Object?>(
      canPop: !inner,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToList();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (inner) ...[
                LoopdRoundButton(
                  icon: Icons.chevron_left_rounded,
                  iconSize: 22,
                  label: 'Back to categories',
                  size: 40,
                  background: c.surfaceRaised,
                  foreground: c.textPrimary,
                  onTap: _backToList,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: LoopdType.title.copyWith(color: c.textPrimary)),
                ),
              ),
              if (canDeleteThis && ready)
                LoopdRoundButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete ${editing.name}',
                  size: 40,
                  background: c.dangerTint,
                  foreground: c.danger,
                  onTap: () => _delete([editing], categoriesAsync.requireValue),
                ),
            ],
          ),
          const SizedBox(height: LoopdSpace.lg),
          Expanded(
            child: AnimatedSwitcher(duration: LoopdMotion.of(context).quick, child: body),
          ),
        ],
      ),
    );
  }
}

String _expenses(int count) => count == 1 ? '1 expense' : '$count expenses';

/// The square tile with a category's icon on its colour.
class CategoryTile extends StatelessWidget {
  const CategoryTile({required this.colour, required this.icon, this.size = 34, super.key});

  /// Index into [LoopdCategoryColours.expense].
  final int colour;
  final String icon;
  final double size;

  /// The icon is dark on every bright category colour, in both themes.
  static const _glyph = Color(0xFF0D0F14);

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: LoopdMotion.of(context).standard,
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: LoopdCategoryColours.expenseAt(colour),
      borderRadius: BorderRadius.circular(size * 0.32),
    ),
    child: Center(
      child: LoopdGlyph(icon, color: _glyph, size: size * 0.53),
    ),
  );
}

/// The list, or the same list with tick boxes on the categories you added
/// while choosing ones to delete.
class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.spending,
    required this.selecting,
    required this.selected,
    required this.onOpen,
    required this.onNew,
    required this.onToggle,
    required this.onStartSelecting,
    required this.onDelete,
    super.key,
  });

  final List<LedgerCategory> categories;
  final Map<String, int> spending;
  final bool selecting;
  final Set<String> selected;
  final ValueChanged<LedgerCategory> onOpen;
  final VoidCallback onNew;
  final ValueChanged<LedgerCategory> onToggle;
  final void Function([LedgerCategory? first]) onStartSelecting;
  final VoidCallback onDelete;

  /// Every colour and icon has its category.
  bool get full => categories.length >= LedgerEngine.categoryMax;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final anyOwn = categories.any((k) => !k.builtIn);
    final count = selected.length;
    final Widget bottom;
    if (selecting) {
      bottom = LoopdButton(
        label: count == 0 ? 'Delete' : (count == 1 ? 'Delete 1 category' : 'Delete $count categories'),
        icon: Icons.delete_outline_rounded,
        accent: c.danger,
        onTap: count == 0 ? null : onDelete,
      );
    } else if (full) {
      // At the limit, the button deletes instead of adding (owner, 18 Nov 2026).
      bottom = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${CategorySheet.fullMessage}. Delete one you added to make room.',
            textAlign: TextAlign.center,
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.sm),
          LoopdButton(
            label: 'Delete categories',
            icon: Icons.delete_outline_rounded,
            accent: c.danger,
            onTap: anyOwn ? onStartSelecting : null,
          ),
        ],
      );
    } else {
      bottom = Row(
        children: [
          Expanded(
            child: LoopdButton(label: 'New category', icon: Icons.add_rounded, onTap: onNew),
          ),
          if (anyOwn) ...[
            const SizedBox(width: LoopdSpace.md),
            LoopdRoundButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete categories',
              size: LoopdSize.button,
              background: c.dangerTint,
              foreground: c.danger,
              onTap: onStartSelecting,
            ),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selecting
              ? 'Tick the ones you added. The default ones always stay.'
              : 'Tap one to rename it or change its colour and icon.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.md),
        Expanded(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LoopdRadius.card),
                border: Border.all(color: c.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (index, category) in categories.indexed) ...[
                    if (index > 0) Divider(height: 1, thickness: 1, color: c.line),
                    _CategoryRow(
                      category: category,
                      spent: spending[category.id] ?? 0,
                      selecting: selecting,
                      selected: selected.contains(category.id),
                      index: index,
                      onTap: selecting ? (category.builtIn ? null : () => onToggle(category)) : () => onOpen(category),
                      onLongPress: selecting || category.builtIn ? null : () => onStartSelecting(category),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: LoopdSpace.lg),
        bottom,
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.spent,
    required this.selecting,
    required this.selected,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  final LedgerCategory category;
  final int spent;
  final bool selecting;
  final bool selected;

  /// Its place in the list, so neighbouring rows shake out of step.
  final int index;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = formatRupees(spent);
    final own = !category.builtIn;
    final row = Row(
      children: [
        _Shake(
          active: selecting && own,
          phase: index,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selecting && own) ...[
                // Only a picture: the whole row ticks it, and says so.
                SizedBox(
                  width: 28,
                  height: LoopdSize.minTouch,
                  child: OverflowBox(
                    maxWidth: LoopdSize.minTouch,
                    child: ExcludeSemantics(
                      child: LoopdCheck(done: selected, onChanged: null, label: category.name, color: c.danger),
                    ),
                  ),
                ),
                const SizedBox(width: LoopdSpace.sm),
              ],
              CategoryTile(colour: category.colour, icon: category.icon),
            ],
          ),
        ),
        const SizedBox(width: LoopdSpace.md),
        Expanded(
          child: Text(
            category.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(width: LoopdSpace.sm),
        if (selecting && !own)
          Text('Default', style: LoopdType.caption.copyWith(color: c.textMuted))
        else
          Text(
            amount,
            style: LoopdType.small.copyWith(
              color: c.textMuted,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        if (!selecting) ...[
          const SizedBox(width: LoopdSpace.xs),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
        ],
      ],
    );
    return AnimatedOpacity(
      duration: LoopdMotion.of(context).quick,
      opacity: selecting && !own ? 0.45 : 1,
      child: LoopdPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        label: selecting
            ? (own ? 'Delete ${category.name}' : '${category.name}, default')
            : '${category.name}, $amount this month',
        selected: selecting && own ? selected : null,
        pressedScale: 1,
        child: AnimatedContainer(
          duration: LoopdMotion.of(context).quick,
          color: selected ? c.dangerTint : const Color(0x00000000),
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: row,
        ),
      ),
    );
  }
}

/// The wobble of a category you can delete, as on a phone's home screen
/// when moving apps. Still when the phone asks for less motion.
class _Shake extends StatefulWidget {
  const _Shake({required this.active, required this.phase, required this.child});

  final bool active;
  final int phase;
  final Widget child;

  @override
  State<_Shake> createState() => _ShakeState();
}

class _ShakeState extends State<_Shake> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, value: 0.5, duration: const Duration(milliseconds: 140));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Shake old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final run = widget.active && !LoopdMotion.of(context).reduced;
    if (run && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!run && _controller.isAnimating) {
      _controller
        ..stop()
        ..value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || LoopdMotion.of(context).reduced) return widget.child;
    // About four degrees each way with a small sideways hop, quick enough
    // to read as a shake; odd rows move the other way.
    final sign = widget.phase.isEven ? 1.0 : -1.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = sign * (_controller.value - 0.5) * 2; // -1 to 1
        return Transform.translate(
          offset: Offset(t * 1.5, 0),
          child: Transform.rotate(angle: t * 0.07, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// Before deleting: where their expenses go. Misc unless another is chosen.
/// Returns the chosen category's id, or null when kept.
class _DeleteSheet extends StatefulWidget {
  const _DeleteSheet({required this.doomed, required this.expenses, required this.targets});

  final List<LedgerCategory> doomed;
  final int expenses;
  final List<LedgerCategory> targets;

  @override
  State<_DeleteSheet> createState() => _DeleteSheetState();
}

class _DeleteSheetState extends State<_DeleteSheet> {
  late String _moveTo = widget.targets.any((k) => k.id == miscCategoryId) ? miscCategoryId : widget.targets.first.id;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final one = widget.doomed.length == 1;
    final what = one ? widget.doomed.single.name : '${widget.doomed.length} categories';
    final target = widget.targets.firstWhere((k) => k.id == _moveTo);
    final has = widget.expenses > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Delete $what?', style: LoopdType.heading.copyWith(color: c.textPrimary)),
        const SizedBox(height: LoopdSpace.xs),
        Text(
          has ? '${_expenses(widget.expenses)} will move to ${target.name}.' : 'No expenses to move.',
          style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        if (has) ...[
          const SizedBox(height: LoopdSpace.lg),
          Text('Move to', style: LoopdType.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: LoopdSpace.sm),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.35),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: LoopdSpace.sm,
                runSpacing: LoopdSpace.sm,
                children: [
                  for (final k in widget.targets)
                    LoopdChip(
                      label: k.name,
                      dotColor: LoopdCategoryColours.expenseAt(k.colour),
                      selected: k.id == _moveTo,
                      onTap: () => setState(() => _moveTo = k.id),
                    ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: LoopdSpace.xl),
        Row(
          children: [
            Expanded(
              child: LoopdButton(
                label: 'Keep',
                style: LoopdButtonStyle.outlined,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: LoopdButton(label: 'Delete', accent: c.danger, onTap: () => Navigator.of(context).pop(_moveTo)),
            ),
          ],
        ),
      ],
    );
  }
}

/// New category or Edit category: a live preview, the name, the colours and
/// icons no other category has, then one green button.
class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.editing, required this.categories, required this.onDone, super.key});

  final LedgerCategory? editing;
  final List<LedgerCategory> categories;

  /// Called with the category's id and name once saved.
  final void Function(String id, String name) onDone;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  final _nameFocus = FocusNode(debugLabel: 'category-name');

  /// The other categories; their colours and icons are not offered.
  late final _others = widget.categories.where((k) => k.id != widget.editing?.id);

  /// Colours and icons free for this one, in palette order. Editing keeps
  /// its own among them.
  late final _colours = [
    for (var i = 0; i < LoopdCategoryColours.expense.length; i++)
      if (_others.every((k) => k.colour != i)) i,
  ];
  late final _icons = [
    for (final (key, label) in LoopdGlyph.expenseIcons)
      if (_others.every((k) => k.icon != key)) (key, label),
  ];

  // A new one starts on the first free colour and icon.
  late int _colour = widget.editing?.colour ?? _colours.firstOrNull ?? 0;
  late String _icon = widget.editing?.icon ?? _icons.firstOrNull?.$1 ?? 'star';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() => _error = null));
    // A new one opens the keyboard once the sheet is fully up, rather than
    // while it slides in.
    if (widget.editing == null) WidgetsBinding.instance.addPostFrameCallback((_) => _focusWhenUp());
  }

  void _focusWhenUp() {
    if (!mounted) return;
    final animation = ModalRoute.of(context)?.animation;
    if (animation == null || animation.isCompleted) {
      _nameFocus.requestFocus();
      return;
    }
    void listener(AnimationStatus status) {
      if (!status.isCompleted) return;
      animation.removeStatusListener(listener);
      if (mounted) _nameFocus.requestFocus();
    }

    animation.addStatusListener(listener);
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _name.dispose();
    super.dispose();
  }

  String get _clean => _name.text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Another category with this name, if any.
  LedgerCategory? get _sameName {
    final name = _clean.toLowerCase();
    if (name.isEmpty) return null;
    return widget.categories.where((k) => k.id != widget.editing?.id && k.name.toLowerCase() == name).firstOrNull;
  }

  bool get _changed {
    final editing = widget.editing;
    return editing == null || editing.name != _clean || editing.colour != _colour || editing.icon != _icon;
  }

  Future<void> _save() async {
    final ledger = ref.read(ledgerEngineProvider);
    final name = _clean;
    setState(() => _saving = true);
    try {
      final editing = widget.editing;
      final String id;
      if (editing == null) {
        id = await ledger.addCategory(name: name, colour: _colour, icon: _icon);
      } else {
        id = editing.id;
        await ledger.updateCategory(id, name: name, colour: _colour, icon: _icon);
      }
      if (mounted) widget.onDone(id, name);
    } on LedgerException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = switch (error.failure) {
          LedgerFailure.duplicateCategory => 'You already have a category called $name.',
          LedgerFailure.categoryLookTaken => 'That colour or icon was just taken. Pick another.',
          LedgerFailure.categoryLimit => '${CategorySheet.fullMessage}.',
          _ => 'Check the name: up to ${LedgerEngine.categoryNameMax} letters.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final colour = LoopdCategoryColours.expenseAt(_colour);
    final same = _sameName;
    final error = same != null ? 'You already have a category called ${same.name}.' : _error;
    final ready = _clean.isNotEmpty && same == null && _changed && !_saving;
    final editing = widget.editing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _Preview(
                name: _clean.isEmpty ? 'Category name' : _clean,
                colour: _colour,
                icon: _icon,
                subtitle: 'Expense category · shows on every payment',
              ),
              const SizedBox(height: LoopdSpace.lg),
              _Label('Name'),
              const SizedBox(height: 6),
              TextField(
                key: CategorySheet.nameFieldKey,
                controller: _name,
                focusNode: _nameFocus,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(LedgerEngine.categoryNameMax)],
                cursorColor: colour,
                style: LoopdType.heading.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'e.g. Coffee',
                  hintStyle: LoopdType.heading.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: c.surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LoopdRadius.inner),
                    borderSide: BorderSide(color: colour, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(LoopdRadius.inner),
                    borderSide: BorderSide(color: colour, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: LoopdSpace.lg),
              _Label('Colour'),
              const SizedBox(height: LoopdSpace.sm),
              _ColourRow(colours: _colours, selected: _colour, onPick: (index) => setState(() => _colour = index)),
              const SizedBox(height: LoopdSpace.lg),
              _Label('Icon'),
              const SizedBox(height: LoopdSpace.sm),
              _IconGrid(icons: _icons, selected: _icon, colour: colour, onPick: (icon) => setState(() => _icon = icon)),
              if (error != null) ...[const SizedBox(height: LoopdSpace.lg), LoopdErrorNote(error)],
              const SizedBox(height: LoopdSpace.lg),
            ],
          ),
        ),
        LoopdButton(label: editing == null ? 'Add category' : 'Save changes', onTap: ready ? _save : null),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(text, style: LoopdType.caption.copyWith(color: context.colors.textMuted));
}

class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.colour, required this.icon, required this.subtitle});

  final String name;
  final int colour;
  final String icon;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: 'Preview, $name',
      container: true,
      child: Container(
        padding: const EdgeInsets.all(LoopdSpace.lg),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(LoopdRadius.cardLarge)),
        child: Row(
          children: [
            CategoryTile(colour: colour, icon: icon, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LoopdType.heading.copyWith(color: c.textPrimary, fontSize: 19),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The free colours, eight to a row; the chosen one has a ring around it.
class _ColourRow extends StatelessWidget {
  const _ColourRow({required this.colours, required this.selected, required this.onPick});

  /// Indexes into [LoopdCategoryColours.expense].
  final List<int> colours;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        children: [
          for (final index in colours)
            SizedBox(
              width: constraints.maxWidth / 8,
              child: LoopdPressable(
                onTap: () => onPick(index),
                selected: index == selected,
                label: 'Colour ${index + 1}',
                child: SizedBox(
                  height: LoopdSize.minTouch,
                  child: Center(
                    child: AnimatedContainer(
                      duration: motion.quick,
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: LoopdCategoryColours.expense[index],
                        shape: BoxShape.circle,
                        boxShadow: index == selected
                            ? [
                                // The outer ring first, then the gap over it.
                                BoxShadow(color: LoopdCategoryColours.expense[index], spreadRadius: 5),
                                BoxShadow(color: c.surface, spreadRadius: 3),
                              ]
                            : const [],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The free icons in six columns; the chosen one fills with the colour.
class _IconGrid extends StatelessWidget {
  const _IconGrid({required this.icons, required this.selected, required this.colour, required this.onPick});

  /// Key and spoken label, as in [LoopdGlyph.expenseIcons].
  final List<(String, String)> icons;
  final String selected;
  final Color colour;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    const gap = LoopdSpace.sm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 5 * gap) / 6;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (key, label) in icons)
              SizedBox(
                width: width,
                child: LoopdPressable(
                  onTap: () => onPick(key),
                  selected: key == selected,
                  label: '$label icon',
                  child: AnimatedContainer(
                    duration: motion.quick,
                    height: 48,
                    decoration: BoxDecoration(
                      color: key == selected ? colour : const Color(0x00000000),
                      borderRadius: BorderRadius.circular(LoopdRadius.tile),
                      border: Border.all(color: key == selected ? colour : c.line, width: key == selected ? 1.5 : 1),
                    ),
                    child: Center(
                      child: LoopdGlyph(key, color: key == selected ? const Color(0xFF0D0F14) : c.textSecondary),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
