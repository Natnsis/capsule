import 'package:flutter/material.dart';
import '../nav.dart';
import '../app_state.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'home.dart';
import 'profile.dart';
import 'capsule_list.dart';
import 'new_capsule.dart';

/// The signed-in app container: swaps the primary tabs and owns the floating
/// bottom navigation bar plus the detached compose button beside it.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    AppScope.of(context); // repaint on theme change
    return Scaffold(
      backgroundColor: C.paper,
      extendBody: true,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: const [
              HomeScreen(),
              CapsuleListScreen(),
              ProfileScreen(),
            ],
          ),
          Positioned(
            left: 26,
            right: 26,
            bottom: 30,
            child: Row(
              children: [
                Expanded(
                  child: FrostedBar(
                    children: [
                      NavIcon(
                        LockGlyph(
                            size: 20,
                            color: _index == 0 ? C.onFill : C.muted,
                            stroke: 1.8),
                        label: 'Home',
                        active: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      NavIcon(
                        Icon(Icons.grid_view_rounded,
                            size: 19, color: _index == 1 ? C.onFill : C.muted),
                        label: 'Capsules',
                        active: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      NavIcon(
                        Icon(Icons.person_outline,
                            size: 20, color: _index == 2 ? C.onFill : C.muted),
                        label: 'Profile',
                        active: _index == 2,
                        onTap: () => setState(() => _index = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ComposeButton(onTap: () => go(context, const NewCapsuleScreen())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The standalone "new capsule" action, sitting apart from the nav bar.
class _ComposeButton extends StatelessWidget {
  const _ComposeButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: C.fill,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF321E50).withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: -8,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Icon(Icons.add, size: 26, color: C.onFill),
      ),
    );
  }
}
