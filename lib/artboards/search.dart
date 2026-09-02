import 'package:flutter/material.dart';
import '../app_state.dart';
import '../capsule_format.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'sealed_detail.dart';
import 'open_day.dart';

/// Search across every capsule on the device by title.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _q = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() => _q = _controller.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final all = store.capsules;
    final results =
        _q.isEmpty ? all : all.where((c) => c.title.toLowerCase().contains(_q)).toList();

    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => back(context),
                    child: IconChip(
                      size: 46,
                      radius: 23,
                      color: C.glass,
                      child: Icon(Icons.arrow_back, size: 20, color: C.ink),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: C.glass,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: C.glassLine),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 19, color: C.muted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              cursorColor: C.ink,
                              style: C.t(15, weight: FontWeight.w600, color: C.ink),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Search capsules',
                                hintStyle: C.t(15, weight: FontWeight.w600, color: C.muted3),
                              ),
                            ),
                          ),
                          if (_q.isNotEmpty)
                            GestureDetector(
                              onTap: _controller.clear,
                              child: Icon(Icons.close, size: 18, color: C.muted),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: results.isEmpty
                    ? Center(
                        child: Text(
                          _q.isEmpty
                              ? 'No capsules yet.'
                              : 'No capsules match “${_controller.text.trim()}”',
                          style: C.t(14, weight: FontWeight.w600, color: C.muted),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: results.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _row(context, results[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, Capsule c) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => go(
        context,
        c.sealed
            ? SealedDetailScreen(capsuleId: c.id, title: c.title, openOn: c.openAt)
            : OpenDayScreen(title: c.title),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: C.glassSoft, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: capsuleGradient(c.id),
                ),
              ),
              alignment: Alignment.center,
              child: LockGlyph(size: 18, color: C.plum, stroke: 1.8, open: !c.sealed),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(15.5, weight: FontWeight.w700, letterSpacing: -.01)),
                  const SizedBox(height: 2),
                  Text(capsuleSubtitle(c, AppScope.of(context).openMomentOf(c)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: C.t(12.5, weight: FontWeight.w500, color: C.muted)),
                ],
              ),
            ),
            Text(c.sealed ? 'Sealed' : 'Opened',
                style: C.t(11.5, weight: FontWeight.w700, color: C.muted3)),
          ],
        ),
      ),
    );
  }
}
