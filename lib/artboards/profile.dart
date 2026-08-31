import 'package:flutter/material.dart';
import '../app_state.dart';
import '../nav.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'create_pin.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme / birthday change
    return Screen(
      decoration: BoxDecoration(gradient: C.screenGradient),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 150),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const Avatar(size: 78, borderWidth: 4),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bereket A.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: C.t(26, weight: FontWeight.w800, letterSpacing: -.03)),
                        const SizedBox(height: 2),
                        Text('On this device since Sep 2024',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: C.t(13.5, weight: FontWeight.w600, color: C.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => AppScope.read(context).toggleBrightness(),
                    child: IconChip(
                      size: 46,
                      radius: 23,
                      color: C.glass,
                      child: Icon(
                        C.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                        size: 20,
                        color: C.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('6', 'Capsules'),
                const SizedBox(width: 10),
                _stat('4', 'Sealed'),
                const SizedBox(width: 10),
                _stat('2y', 'Longest'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: C.glass,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                children: [
                  _settingRow(
                    LockGlyph(size: 19, color: C.ink, stroke: 1.8),
                    'Change PIN',
                    null,
                    trailing: Icon(Icons.chevron_right, size: 18, color: C.muted3),
                    onTap: () => go(context, const CreatePinScreen()),
                  ),
                  _divider(),
                  _settingRow(
                    Icon(Icons.cake_outlined, size: 19, color: C.ink),
                    'Birthday',
                    store.hasBirthday
                        ? _fmtDate(store.birthday!)
                        : 'Not set · used for capsule open dates',
                    trailing: Icon(Icons.chevron_right, size: 18, color: C.muted3),
                    onTap: () => _pickBirthday(context),
                  ),
                  _divider(),
                  _settingRow(
                    Icon(Icons.fingerprint, size: 19, color: C.ink),
                    'Biometric sealing',
                    'Required to seal every capsule',
                    trailing: const Toggle(on: true),
                  ),
                  _divider(),
                  _settingRow(
                    Icon(Icons.notifications_none_rounded, size: 19, color: C.ink),
                    'Notifications',
                    store.notificationsEnabled
                        ? 'Allowed on this device'
                        : 'Off · reminders won’t be sent',
                    trailing: GestureDetector(
                      onTap: () => AppScope.read(context)
                          .setNotificationsEnabled(!store.notificationsEnabled),
                      child: Toggle(on: store.notificationsEnabled),
                    ),
                    onTap: () => AppScope.read(context)
                        .setNotificationsEnabled(!store.notificationsEnabled),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _comingSoonCard(),
          ],
        ),
      ),
    );
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  String _fmtDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  Future<void> _pickBirthday(BuildContext context) async {
    final store = AppScope.read(context);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: store.birthday ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select your birthday',
    );
    if (picked != null) store.setBirthday(picked);
  }

  Widget _stat(String value, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: C.glass,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: C.t(30, weight: FontWeight.w800, letterSpacing: -.03)),
              Text(label, style: C.t(12.5, weight: FontWeight.w700, color: C.muted)),
            ],
          ),
        ),
      );

  Widget _divider() =>
      Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 14), color: C.lav5);

  Widget _settingRow(Widget icon, String title, String? sub,
          {required Widget trailing, VoidCallback? onTap}) =>
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: C.lav6, borderRadius: BorderRadius.circular(15)),
                alignment: Alignment.center,
                child: icon,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: C.t(15.5, weight: FontWeight.w700)),
                    if (sub != null) ...[
                      const SizedBox(height: 1),
                      Text(sub, style: C.t(12.5, weight: FontWeight.w500, color: C.muted)),
                    ],
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      );

  Widget _comingSoonCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [C.card1, C.card2],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -50,
              bottom: -60,
              child: Blob(
                size: 170,
                opacity: C.isDark ? .5 : .9,
                center: const Alignment(-0.3, -0.4),
                colors: const [Color(0xFFF6DCE2), Color(0xFF7E4FAE)],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: C.glass,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      alignment: Alignment.center,
                      child: Text('COMING SOON',
                          style: C.t(11.5,
                              weight: FontWeight.w800, color: C.ink2, letterSpacing: .08)),
                    ),
                    Icon(Icons.file_upload_outlined, size: 20, color: C.ink2),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Back up capsules to your account',
                    style: C.t(20, weight: FontWeight.w800, letterSpacing: -.02, color: C.ink2)),
                const SizedBox(height: 6),
                SizedBox(
                  width: 250,
                  child: Text(
                    'Optional sign-in so a sealed capsule survives a lost phone. Still sealed, still unopenable.',
                    style: C.t(13.5, color: C.ink2, height: 1.55),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 44,
                  width: 150,
                  decoration: BoxDecoration(
                    color: C.glass,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  alignment: Alignment.center,
                  child: Text('Notify me',
                      style: C.t(14, weight: FontWeight.w700, color: C.ink2)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
