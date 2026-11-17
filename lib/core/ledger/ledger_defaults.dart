/// The twelve categories every install starts with (proposal section 4,
/// mockup `CategorySheet.dc.html`): name, colour index (0–7) and icon key.
const defaultCategories = <(String id, String name, int colour, String icon)>[
  ('category-food', 'Food', 0, 'food'),
  ('category-snacks', 'Snacks', 1, 'snack'),
  ('category-groceries', 'Groceries', 2, 'grocery'),
  ('category-travel', 'Travel', 3, 'bus'),
  ('category-shopping', 'Shopping', 4, 'bag'),
  ('category-bills', 'Bills', 5, 'bill'),
  ('category-health', 'Health', 6, 'health'),
  ('category-fuel', 'Fuel', 7, 'fuel'),
  ('category-fun', 'Fun', 1, 'star'),
  ('category-rent', 'Rent', 3, 'home'),
  ('category-subscriptions', 'Subscriptions', 4, 'repeat'),
  ('category-gifts', 'Gifts', 0, 'gift'),
];
