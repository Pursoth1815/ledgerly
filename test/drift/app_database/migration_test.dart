// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/app_database.dart';

import 'generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  // Version 1 had no tables, so v1 to v2 has no data to preserve. Add a
  // data-integrity test for any later step that changes existing tables.

  test(
    '5 to 6 gives every category its own colour and icon, keeping the rest',
    () async {
      final schema = await verifier.schemaAt(5);
      final raw = schema.rawDatabase;
      // The twelve version 5 defaults (shared colours), plus two added while
      // testing Part 4 with a colour and an icon a default already had.
      const v5 = [
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
        ('mine-coffee', 'Coffee', 2, 'snack'),
        ('mine-pets', 'Pets', 7, 'star'),
      ];
      for (final (i, (id, name, colour, icon)) in v5.indexed) {
        raw.execute(
          "INSERT INTO accounts (id, kind, name, is_default, created_at) VALUES (?, 'category', ?, 0, 0)",
          [id, name],
        );
        raw.execute(
          'INSERT INTO categories (account_id, colour, icon, sort_order) VALUES (?, ?, ?, ?)',
          [id, colour, icon, i],
        );
      }

      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 6);
      final rows = await db
          .customSelect(
            'SELECT account_id, colour, icon, sort_order FROM categories',
          )
          .get();
      final looks = {
        for (final row in rows)
          row.read<String>('account_id'): (
            row.read<int>('colour'),
            row.read<String>('icon'),
          ),
      };
      await db.close();

      expect(looks, hasLength(14), reason: 'every row is kept');
      expect(
        looks.values.map((l) => l.$1).toSet(),
        hasLength(14),
        reason: 'no shared colour',
      );
      expect(
        looks.values.map((l) => l.$2).toSet(),
        hasLength(14),
        reason: 'no shared icon',
      );
      expect(looks['category-food'], (
        0,
        'food',
      ), reason: 'unshared defaults keep their looks');
      expect(looks['category-fun'], (12, 'star'));
      expect(looks['category-rent'], (10, 'home'));
      expect(looks['category-subscriptions'], (8, 'repeat'));
      expect(looks['category-gifts'], (9, 'gift'));
      expect(looks['mine-coffee'], (
        11,
        'phone',
      ), reason: 'an added one gives way to the first free ones');
      expect(looks['mine-pets'], (13, 'car'));
    },
  );
}
