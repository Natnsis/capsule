import 'package:flutter/widgets.dart';

/// Renders the lightweight markup produced by the compose screen:
/// `**bold**`, `*italic*`, `~underline~`. Line breaks are preserved.
class Markup extends StatelessWidget {
  const Markup(this.source, {super.key, required this.style});

  final String source;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Text.rich(TextSpan(style: style, children: _spans(source, style)));
  }

  static final _token = RegExp(r'(\*\*|\*|~)');

  static List<InlineSpan> _spans(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    var bold = false, italic = false, underline = false;
    var buffer = StringBuffer();

    void flush() {
      if (buffer.isEmpty) return;
      spans.add(TextSpan(
        text: buffer.toString(),
        style: base.copyWith(
          fontWeight: bold ? FontWeight.w800 : null,
          fontStyle: italic ? FontStyle.italic : null,
          decoration: underline ? TextDecoration.underline : null,
        ),
      ));
      buffer = StringBuffer();
    }

    var i = 0;
    while (i < text.length) {
      final m = _token.matchAsPrefix(text, i);
      if (m != null) {
        flush();
        switch (m.group(0)) {
          case '**':
            bold = !bold;
          case '*':
            italic = !italic;
          case '~':
            underline = !underline;
        }
        i = m.end;
      } else {
        buffer.write(text[i]);
        i++;
      }
    }
    flush();
    return spans;
  }
}
