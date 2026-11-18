/// The thirteen categories every install starts with (proposal section 4,
/// mockup `CategorySheet.dc.html`): name, colour index (0–15) and icon key.
/// No two share a colour or an icon (owner, 18 Nov 2026).
const defaultCategories = <(String id, String name, int colour, String icon)>[
  ('category-food', 'Food', 0, 'food'),
  ('category-snacks', 'Snacks', 1, 'snack'),
  ('category-groceries', 'Groceries', 2, 'grocery'),
  ('category-travel', 'Travel', 3, 'bus'),
  ('category-shopping', 'Shopping', 4, 'bag'),
  ('category-bills', 'Bills', 5, 'bill'),
  ('category-health', 'Health', 6, 'health'),
  ('category-fuel', 'Fuel', 7, 'fuel'),
  ('category-fun', 'Fun', 12, 'star'),
  ('category-rent', 'Rent', 10, 'home'),
  ('category-subscriptions', 'Subscriptions', 8, 'repeat'),
  ('category-gifts', 'Gifts', 9, 'gift'),
  (miscCategoryId, 'Misc', 24, 'dots'),
];

/// Misc, the default home for the expenses of a deleted category.
const miscCategoryId = 'category-misc';

/// The ids of [defaultCategories]; these can never be deleted.
final defaultCategoryIds = {for (final (id, _, _, _) in defaultCategories) id};
