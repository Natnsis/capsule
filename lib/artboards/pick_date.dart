import 'package:flutter/material.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December'
];

/// The "choose the open day" sheet (design screen 05). Presented with
/// [showModalBottomSheet]; pops with the selected [DateTime].
class PickDateSheet extends StatefulWidget {
  const PickDateSheet({super.key, this.title = '', this.note = ''});
  final String title;
  final String note;

  @override
  State<PickDateSheet> createState() => _PickDateSheetState();
}

class _PickDateSheetState extends State<PickDateSheet> {
  final DateTime _today = DateTime.now();
  late DateTime _month = DateTime(_today.year, _today.month);
  late DateTime? _selected = DateTime(_today.year, _today.month, _today.day);

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;
  int get _leadingBlanks => (DateTime(_month.year, _month.month, 1).weekday + 6) % 7;

  /// Viewing the current calendar month — can't page earlier than this.
  bool get _atFloor =>
      _month.year == _today.year && _month.month == _today.month;

  /// A day in the current month that has already passed.
  bool _isPast(int day) => _atFloor && day < _today.day;

  int _monthsBetween(DateTime a, DateTime b) => (b.year - a.year) * 12 + (b.month - a.month);

  AppStore get _store => AppScope.of(context);

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    final sealedMonths = _monthsBetween(DateTime(_today.year, _today.month), _month);
    return Stack(
      children: [
        // Dimmed letter preview behind the sheet.
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [C.bgMid, C.bgBottom],
              ),
            ),
            child: Opacity(
              opacity: .55,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 90, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title.isEmpty ? 'Your capsule' : widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: C.t(34, weight: FontWeight.w800, letterSpacing: -.03)),
                    const SizedBox(height: 16),
                    Text(
                      widget.note.isEmpty
                          ? 'Once you pick a day and seal it, this capsule stays locked — even to you — until it opens.'
                          : widget.note,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(16, color: C.plum2, height: 1.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: Container(color: const Color(0x591E142D))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.9,
            ),
            decoration: BoxDecoration(
              color: C.paper,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
            ),
            padding: EdgeInsets.fromLTRB(
                24, 14, 24, 36 + MediaQuery.viewInsetsOf(context).bottom),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: C.faint2,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: _pickYear,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                      '${_months[_month.month - 1]}, ${_month.year}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: C.t(26,
                                          weight: FontWeight.w800, letterSpacing: -.03)),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.expand_more, size: 22, color: C.muted3),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sealedMonths <= 0
                                ? 'Opens this month'
                                : 'Sealed for $sealedMonths month${sealedMonths == 1 ? '' : 's'}',
                            style: C.t(13, weight: FontWeight.w600, color: C.muted3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        _chevron(
                            Icons.keyboard_arrow_up,
                            _atFloor
                                ? null
                                : () => setState(() => _month =
                                    DateTime(_month.year, _month.month - 1))),
                        const SizedBox(width: 8),
                        _chevron(Icons.keyboard_arrow_down,
                            () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.8,
                  children: [
                    for (final d in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                      Center(
                        child: Text(d, style: C.t(11, weight: FontWeight.w700, color: C.weekday)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.92,
                  children: [
                    for (int i = 0; i < _leadingBlanks; i++) const SizedBox.shrink(),
                    for (int d = 1; d <= _daysInMonth; d++)
                      _day(d,
                          selected: _selected?.day == d &&
                              _selected?.month == _month.month &&
                              _selected?.year == _month.year,
                          disabled: _isPast(d)),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _quick('1 year', () => _jump(12)),
                    const SizedBox(width: 10),
                    _quick('5 years', () => _jump(60)),
                    if (_store.hasBirthday) ...[
                      const SizedBox(width: 10),
                      _quick('My birthday', () {
                        final d = _store.nextBirthday();
                        if (d != null) _jumpToDate(d);
                      }),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  child: Container(
                    height: 62,
                    decoration: BoxDecoration(
                      color: _selected == null ? C.lav4 : C.fill,
                      borderRadius: BorderRadius.circular(31),
                    ),
                    alignment: Alignment.center,
                    child: Text('Continue to seal',
                        style: C.t(17,
                            weight: FontWeight.w700,
                            color: _selected == null ? C.faint : C.onFill)),
                  ),
                ),
              ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _jump(int months) {
    setState(() {
      _month = DateTime(_today.year, _today.month + months);
      _selected = DateTime(_month.year, _month.month, _today.day.clamp(1, _daysInMonth));
    });
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: C.paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _YearSheet(first: _today.year, selected: _month.year),
    );
    if (picked == null) return;
    setState(() {
      // Never land on a month that's already gone.
      final month = picked == _today.year && _month.month < _today.month
          ? _today.month
          : _month.month;
      _month = DateTime(picked, month);
      if (_selected != null) {
        final dim = DateTime(picked, month + 1, 0).day;
        _selected = DateTime(picked, month, _selected!.day.clamp(1, dim));
      }
    });
  }

  void _jumpToDate(DateTime d) {
    setState(() {
      _month = DateTime(d.year, d.month);
      _selected = DateTime(d.year, d.month, d.day);
    });
  }

  Widget _chevron(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .35 : 1,
          child: IconChip(
            size: 44,
            radius: 22,
            color: C.lav1,
            child: Icon(icon, size: 22, color: C.ink),
          ),
        ),
      );

  Widget _day(int n, {bool selected = false, bool disabled = false}) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled
            ? null
            : () => setState(() => _selected = DateTime(_month.year, _month.month, n)),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? C.fill : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            '$n',
            style: C.t(15,
                weight: selected ? FontWeight.w700 : FontWeight.w600,
                color: disabled ? C.faint : (selected ? C.onFill : C.ink3)),
          ),
        ),
      );

  Widget _quick(String label, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 40,
            decoration: BoxDecoration(color: C.lav1, borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: C.t(13.5, weight: FontWeight.w700, color: C.slate)),
          ),
        ),
      );
}

/// "Jump to year" wheel. Owns its scroll controller so it survives the sheet's
/// dismiss animation without being disposed underneath a live widget.
class _YearSheet extends StatefulWidget {
  const _YearSheet({required this.first, required this.selected});
  final int first;
  final int selected;

  @override
  State<_YearSheet> createState() => _YearSheetState();
}

class _YearSheetState extends State<_YearSheet> {
  late final List<int> _years =
      [for (int y = widget.first; y <= widget.first + 50; y++) y];
  late int _sel = widget.selected;
  late final FixedExtentScrollController _ctrl =
      FixedExtentScrollController(initialItem: _sel - widget.first);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 5,
              margin: const EdgeInsets.only(bottom: 18),
              decoration:
                  BoxDecoration(color: C.faint2, borderRadius: BorderRadius.circular(3)),
            ),
            Text('Jump to year', style: C.t(17, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            SizedBox(
              height: 176,
              child: ListWheelScrollView.useDelegate(
                controller: _ctrl,
                itemExtent: 44,
                physics: const FixedExtentScrollPhysics(),
                onSelectedItemChanged: (i) => _sel = _years[i],
                childDelegate: ListWheelChildBuilderDelegate(
                  childCount: _years.length,
                  builder: (_, i) => Center(
                    child: Text('${_years[i]}',
                        style: C.t(21, weight: FontWeight.w700, color: C.ink3)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(_sel),
              child: Container(
                height: 54,
                width: double.infinity,
                decoration:
                    BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(27)),
                alignment: Alignment.center,
                child: Text('Done', style: C.t(16, weight: FontWeight.w700, color: C.onFill)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
