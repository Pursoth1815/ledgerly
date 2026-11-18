import 'package:loopd/core/ledger/ledger_engine.dart';

/// Adds the twelve categories that take a fresh install to the limit: the
/// colours and icons the thirteen defaults leave free.
Future<List<String>> fillCategories(LedgerEngine ledger) async {
  const colours = [11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
  const icons = [
    'phone',
    'car',
    'plane',
    'film',
    'book',
    'cap',
    'paw',
    'dumbbell',
    'scissors',
    'wifi',
    'bolt',
    'shirt',
  ];
  return [
    for (var i = 0; i < colours.length; i++)
      await ledger.addCategory(name: 'Extra ${i + 1}', colour: colours[i], icon: icons[i]),
  ];
}
