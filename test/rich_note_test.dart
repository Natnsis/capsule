import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capsule/rich_note_controller.dart';

void main() {
  test('typing plain text produces no markers', () {
    final c = RichNoteController();
    c.value = const TextEditingValue(
        text: 'hello world', selection: TextSelection.collapsed(offset: 11));
    expect(c.text, 'hello world');
    expect(c.markup, 'hello world');
  });

  test('selecting a range and toggling bold wraps only that range', () {
    final c = RichNoteController();
    c.value = const TextEditingValue(
        text: 'hello world', selection: TextSelection.collapsed(offset: 11));
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 5); // "hello"
    c.toggle(RichNoteController.bold);
    expect(c.markup, '**hello** world');
    expect(c.text, 'hello world'); // visible text stays clean
  });

  test('toggling bold twice on the same range removes it', () {
    final c = RichNoteController(markup: '**hi** there');
    expect(c.text, 'hi there');
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
    c.toggle(RichNoteController.bold);
    expect(c.markup, 'hi there');
  });

  test('overlapping italic + underline serialize and parse round-trip', () {
    final c = RichNoteController();
    c.value = const TextEditingValue(
        text: 'abcdef', selection: TextSelection.collapsed(offset: 6));
    c.selection = const TextSelection(baseOffset: 1, extentOffset: 4); // bcd
    c.toggle(RichNoteController.italic);
    c.selection = const TextSelection(baseOffset: 2, extentOffset: 5); // cde
    c.toggle(RichNoteController.underline);
    final markup = c.markup;
    final round = RichNoteController(markup: markup);
    expect(round.text, 'abcdef');
    expect(round.markup, markup);
  });

  test('deleting text keeps the remaining formatting aligned', () {
    final c = RichNoteController(markup: 'a**bold**c');
    expect(c.text, 'aboldc');
    // delete the leading "a"
    c.value = const TextEditingValue(
        text: 'boldc', selection: TextSelection.collapsed(offset: 0));
    expect(c.markup, '**bold**c');
  });
}
