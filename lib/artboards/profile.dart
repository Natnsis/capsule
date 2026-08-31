import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../nav.dart';
import '../services.dart';
import '../tokens.dart';
import '../widgets/common.dart';
import 'create_pin.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  // Real OS state, re-checked whenever the screen (re)appears. The toggles
  // reflect `stored preference AND this` — never just the stored bool.
  bool _notifGranted = false;
  bool _bioEnrolled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncPermissions());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from the system settings screen — pick up any change.
    if (state == AppLifecycleState.resumed) _syncPermissions();
  }

  Future<void> _syncPermissions() async {
    final granted = await Notifier.instance.isGranted;
    final enrolled = await Biometrics.instance.isEnrolled;
    if (!mounted) return;
    final store = AppScope.read(context);
    // If the OS capability is gone, drop the stored opt-in so the two stay in
    // sync and the user has to grant it again to turn the feature back on.
    if (!granted && store.notificationsEnabled) store.setNotificationsEnabled(false);
    if (!enrolled && store.biometricEnabled) store.setBiometricEnabled(false);
    setState(() {
      _notifGranted = granted;
      _bioEnrolled = enrolled;
    });
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context); // repaint on theme / birthday change
    final notifOn = store.notificationsEnabled && _notifGranted;
    final bioOn = store.biometricEnabled && _bioEnrolled;
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
                  GestureDetector(
                    onTap: () => _pickProfileImage(context),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Avatar(size: 78, borderWidth: 4),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: C.fill,
                              shape: BoxShape.circle,
                              border: Border.all(color: C.paper, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Icon(Icons.photo_camera_rounded, size: 13, color: C.onFill),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => AppScope.read(context).toggleBrightness(),
                        child: IconChip(
                          size: 40,
                          radius: 20,
                          color: C.glass,
                          child: Icon(
                            C.isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                            size: 19,
                            color: C.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _pickProfileImage(context),
                        child: IconChip(
                          size: 40,
                          radius: 20,
                          color: C.glass,
                          child: Icon(Icons.image_outlined, size: 19, color: C.ink),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _stat('${store.capsules.where((c) => !c.isDraft).length}', 'Capsules'),
                const SizedBox(width: 10),
                _stat('${store.sealedCapsules.length}', 'Sealed'),
                const SizedBox(width: 10),
                _stat(_longest(store), 'Longest'),
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
                    'Enter current, then choose a new one',
                    trailing: Icon(Icons.chevron_right, size: 18, color: C.muted3),
                    onTap: () => go(context, const CreatePinScreen(change: true)),
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
                    bioOn
                        ? 'Offer fingerprint lock when sealing'
                        : _bioEnrolled
                            ? 'Off · capsules seal without biometrics'
                            : 'No fingerprint / face unlock set up on this device',
                    trailing: GestureDetector(
                      onTap: _toggleBiometric,
                      child: Toggle(on: bioOn),
                    ),
                    onTap: _toggleBiometric,
                  ),
                  _divider(),
                  _settingRow(
                    Icon(Icons.notifications_none_rounded, size: 19, color: C.ink),
                    'Notifications',
                    notifOn
                        ? 'Reminders sent when a capsule opens'
                        : _notifGranted
                            ? 'Off · reminders only show in-app'
                            : 'Not allowed · turn on to grant permission',
                    trailing: GestureDetector(
                      onTap: _toggleNotifications,
                      child: Toggle(on: notifOn),
                    ),
                    onTap: _toggleNotifications,
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

  String _longest(AppStore store) {
    var maxDays = 0;
    for (final c in store.capsules) {
      if (c.isDraft) continue;
      final d = c.openAt.difference(c.createdAt).inDays;
      if (d > maxDays) maxDays = d;
    }
    if (maxDays <= 0) return '—';
    if (maxDays < 60) return '${maxDays}d';
    if (maxDays < 365) return '${(maxDays / 30).round()}mo';
    final y = (maxDays / 365);
    return y >= 10 ? '${y.round()}y' : '${y.toStringAsFixed(1).replaceAll('.0', '')}y';
  }

  Future<void> _pickProfileImage(BuildContext context) async {
    final store = AppScope.read(context);
    try {
      const group = XTypeGroup(
          label: 'images', extensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic']);
      final picked = await openFile(acceptedTypeGroups: const [group]);
      if (picked == null) return;
      final dir = Directory(
          p.join((await getApplicationDocumentsDirectory()).path, 'profile'));
      await dir.create(recursive: true);
      // Replace whatever avatar was there before.
      for (final f in dir.listSync()) {
        if (f is File) {
          try {
            await f.delete();
          } catch (_) {}
        }
      }
      final ext = p.extension(picked.name).toLowerCase();
      final dest = p.join(dir.path, 'avatar${ext.isEmpty ? '.img' : ext}');
      await File(picked.path).copy(dest);
      await store.setProfileImageFile(dest);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t set that image.')),
        );
      }
    }
  }

  Future<void> _toggleNotifications() async {
    final store = AppScope.read(context);
    final on = store.notificationsEnabled && _notifGranted;
    if (on) {
      store.setNotificationsEnabled(false);
      setState(() {});
      return;
    }
    // Turning on: always go through the OS. Every attempt re-prompts, or routes
    // to Settings once the prompt can no longer be shown.
    if (await Notifier.instance.isPermanentlyDenied) {
      _toast('Allow notifications for Capsule in Settings, then come back.');
      await Notifier.instance.openSettings();
      return;
    }
    final granted = await Notifier.instance.request();
    if (granted) {
      store.setNotificationsEnabled(true);
    } else if (await Notifier.instance.isPermanentlyDenied) {
      _toast('Allow notifications for Capsule in Settings, then come back.');
      await Notifier.instance.openSettings();
    } else {
      _toast('Notifications stay off until you allow them.');
    }
    await _syncPermissions();
  }

  Future<void> _toggleBiometric() async {
    final store = AppScope.read(context);
    final on = store.biometricEnabled && _bioEnrolled;
    if (on) {
      store.setBiometricEnabled(false);
      setState(() {});
      return;
    }
    // Turning on: needs a fingerprint / face actually enrolled on the device.
    final enrolled = await Biometrics.instance.isEnrolled;
    if (!enrolled) {
      _toast('Set up a fingerprint or face unlock in your phone settings first.');
      final opened = await Biometrics.instance.openEnrollment();
      if (!opened) await Notifier.instance.openSettings();
      await _syncPermissions();
      return;
    }
    if (!mounted) return;
    // Confirm it works before switching it on.
    final ok = await Biometrics.instance
        .authenticate(context, 'Confirm to turn on biometric sealing');
    if (ok) {
      store.setBiometricEnabled(true);
    } else {
      _toast('Biometric check didn’t pass — left off.');
    }
    await _syncPermissions();
  }

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
        // Fixed height + shrink-to-fit value → all three cards match exactly,
        // whatever the number or the "Longest" string turns out to be.
        child: Container(
          height: 86,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: C.glass,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    maxLines: 1,
                    style: C.t(28, weight: FontWeight.w800, letterSpacing: -.03)),
              ),
              const SizedBox(height: 3),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: C.t(12.5, weight: FontWeight.w700, color: C.muted)),
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
