/// Data for the version 6 step: from then on no two categories share a
/// colour or an icon (owner, 18 Nov 2026). Frozen with that step; never
/// change it, even if the defaults or the icon set change later.
library;

/// The four defaults that shared a colour move to one of the eight new ones.
const _newDefaultColours = {'category-fun': 12, 'category-rent': 10, 'category-subscriptions': 8, 'category-gifts': 9};

/// The sixteen colours (0 to 15) and twenty-four icons of version 6.
const _colourCount = 16;
const _icons = [
  'food', 'snack', 'grocery', 'bus', 'bag', 'bill', 'health', 'fuel', 'star', 'home', 'repeat', 'gift', //
  'phone', 'car', 'plane', 'film', 'book', 'cap', 'paw', 'dumbbell', 'scissors', 'wifi', 'bolt', 'shirt',
];

/// Gives each category, in list order, a colour and an icon no earlier one
/// has: its own when still free, otherwise the first free one. Takes and
/// returns (id, colour, icon); the defaults come first in the list, so they
/// keep their looks and a category added later gives way.
///
/// Throws [StateError] when there are more categories than colours, which
/// the app never allowed past version 5 in practice (twelve defaults plus a
/// few added while testing).
List<(String, int, String)> uniqueCategoryLooks(List<(String, int, String)> categories) {
  if (categories.length > _colourCount) throw StateError('More than $_colourCount categories');
  final colours = <int>{};
  final icons = <String>{};
  final out = <(String, int, String)>[];
  for (final (id, colour, icon) in categories) {
    final wanted = _newDefaultColours[id] ?? colour;
    final pickedColour = !colours.contains(wanted) && wanted >= 0 && wanted < _colourCount
        ? wanted
        : List.generate(_colourCount, (i) => i).firstWhere((i) => !colours.contains(i));
    final pickedIcon = icons.contains(icon) ? _icons.firstWhere((i) => !icons.contains(i)) : icon;
    colours.add(pickedColour);
    icons.add(pickedIcon);
    out.add((id, pickedColour, pickedIcon));
  }
  return out;
}
