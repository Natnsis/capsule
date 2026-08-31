import 'package:flutter/widgets.dart';

/// A [TextEditingController] that keeps per-character bold/italic/underline
/// formatting. The text field shows the real styling — no `**` markers leak
/// into what the writer sees. Serialize with [markup] for storage; the
/// `Markup` widget renders that same string back.
class RichNoteController extends TextEditingController {
  static const int bold = 1;
  static const int italic = 2;
  static const int underline = 4;

  /// One bitmask per character of [text].
  List<int> _flags = <int>[];

  /// Formatting that will apply to the next characters typed at a collapsed
  /// caret (set by tapping B/I/U with nothing selected).
  int _pending = 0;
  bool _pendingActive = false;

  RichNoteController({String markup = ''}) : super() {
    final (plain, flags) = _parse(markup);
    _flags = flags;
    super.value = TextEditingValue(
      text: plain,
      selection: TextSelection.collapsed(offset: plain.length),
    );
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = super.value.text;
    final newText = newValue.text;
    if (oldText != newText) {
      _flags = _reflow(oldText, newText, _flags);
    }
    if (newValue.selection != super.value.selection && !newValue.selection.isCollapsed) {
      _pendingActive = false;
    }
    super.value = newValue;
  }

  /// True if the current selection (or caret) has [bit] active everywhere.
  bool isActive(int bit) {
    final sel = selection;
    if (!sel.isValid) return false;
    if (sel.isCollapsed) {
      if (_pendingActive) return (_pending & bit) != 0;
      final i = sel.start - 1;
      return i >= 0 && i < _flags.length && (_flags[i] & bit) != 0;
    }
    for (int k = sel.start; k < sel.end; k++) {
      if (k >= _flags.length || (_flags[k] & bit) == 0) return false;
    }
    return true;
  }

  void toggle(int bit) {
    final sel = selection;
    if (!sel.isValid) return;
    if (sel.isCollapsed) {
      if (!_pendingActive) {
        final i = sel.start - 1;
        _pending = (i >= 0 && i < _flags.length) ? _flags[i] : 0;
        _pendingActive = true;
      }
      _pending ^= bit;
      notifyListeners();
      return;
    }
    final remove = isActive(bit);
    for (int k = sel.start; k < sel.end && k < _flags.length; k++) {
      if (remove) {
        _flags[k] &= ~bit;
      } else {
        _flags[k] |= bit;
      }
    }
    notifyListeners();
  }

  /// Insert plain text at the caret (used for the bullet button).
  void insertPlain(String snippet) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    final newText = text.replaceRange(sel.start, sel.end, snippet);
    value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + snippet.length),
    );
  }

  String get markup {
    final b = StringBuffer();
    var cur = 0;
    for (int i = 0; i <= text.length; i++) {
      final f = i < text.length && i < _flags.length ? _flags[i] : 0;
      if (f != cur) {
        // close bits that turn off, open bits that turn on
        for (final bit in const [underline, italic, bold]) {
          if ((cur & bit) != 0 && (f & bit) == 0) b.write(_marker(bit));
        }
        for (final bit in const [bold, italic, underline]) {
          if ((cur & bit) == 0 && (f & bit) != 0) b.write(_marker(bit));
        }
        cur = f;
      }
      if (i < text.length) b.write(text[i]);
    }
    return b.toString();
  }

  static String _marker(int bit) => switch (bit) {
        bold => '**',
        italic => '*',
        underline => '~',
        _ => '',
      };

  // ---- change reconciliation -----------------------------------
  List<int> _reflow(String oldText, String newText, List<int> flags) {
    var p = 0;
    final minLen = oldText.length < newText.length ? oldText.length : newText.length;
    while (p < minLen && oldText.codeUnitAt(p) == newText.codeUnitAt(p)) {
      p++;
    }
    var s = 0;
    while (s < minLen - p &&
        oldText.codeUnitAt(oldText.length - 1 - s) ==
            newText.codeUnitAt(newText.length - 1 - s)) {
      s++;
    }
    final removedEnd = oldText.length - s;
    final insertedLen = newText.length - s - p;

    final left = flags.sublist(0, p.clamp(0, flags.length));
    final right = removedEnd <= flags.length
        ? flags.sublist(removedEnd.clamp(0, flags.length))
        : <int>[];

    int inheritFlag;
    if (_pendingActive) {
      inheritFlag = _pending;
    } else if (p > 0 && p - 1 < flags.length) {
      inheritFlag = flags[p - 1];
    } else {
      inheritFlag = 0;
    }
    final middle = List<int>.filled(insertedLen < 0 ? 0 : insertedLen, inheritFlag);

    return [...left, ...middle, ...right];
  }

  // ---- markup <-> (plain, flags) ------------------------------
  static (String, List<int>) _parse(String src) {
    final buf = StringBuffer();
    final flags = <int>[];
    var cur = 0;
    var i = 0;
    while (i < src.length) {
      if (src.startsWith('**', i)) {
        cur ^= bold;
        i += 2;
      } else if (src[i] == '*') {
        cur ^= italic;
        i += 1;
      } else if (src[i] == '~') {
        cur ^= underline;
        i += 1;
      } else {
        buf.write(src[i]);
        flags.add(cur);
        i += 1;
      }
    }
    return (buf.toString(), flags);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    if (text.isEmpty) return TextSpan(style: base, text: '');
    final children = <TextSpan>[];
    var i = 0;
    while (i < text.length) {
      final f = i < _flags.length ? _flags[i] : 0;
      var j = i;
      while (j < text.length && (j < _flags.length ? _flags[j] : 0) == f) {
        j++;
      }
      children.add(TextSpan(
        text: text.substring(i, j),
        style: base.copyWith(
          fontWeight: (f & bold) != 0 ? FontWeight.w800 : null,
          fontStyle: (f & italic) != 0 ? FontStyle.italic : null,
          decoration: (f & underline) != 0 ? TextDecoration.underline : null,
        ),
      ));
      i = j;
    }
    return TextSpan(style: base, children: children);
  }
}
