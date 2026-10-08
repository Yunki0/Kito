import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kito/app.dart';
import 'package:kito/features/inventory/domain/equipment_item.dart';
import 'package:kito/features/inventory/presentation/equipment_form_page.dart';
import 'package:kito/features/inventory/presentation/inventory_providers.dart';

void main() {
  testWidgets('shows the branded splash while the local database opens', (
    tester,
  ) async {
    final startup = Completer<void>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseReadyProvider.overrideWith((ref) => startup.future),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pump();

    expect(find.byKey(const ValueKey('splash')), findsOneWidget);
    expect(find.text('Kito'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byKey(const ValueKey('splash')), findsOneWidget);
    startup.complete();
  });

  testWidgets('shows the French inventory empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseReadyProvider.overrideWith((ref) async {}),
          equipmentProvider.overrideWith((ref) async => []),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kito'), findsOneWidget);
    expect(find.text('Votre inventaire commence ici'), findsOneWidget);
    expect(find.text('Ajouter du matériel'), findsWidgets);
    expect(find.text('Emprunts'), findsNothing);
    expect(find.text('Enregistrer une sortie'), findsNothing);
    expect(find.byType(NavigationDestination), findsNothing);
    expect(find.text('Journal'), findsNothing);
  });

  testWidgets('dashboard shows unusable stock without an activity section', (
    tester,
  ) async {
    final item = EquipmentItem(
      id: 'tent',
      name: 'Tente',
      category: 'Camping',
      newQuantity: 0,
      goodQuantity: 2,
      repairQuantity: 1,
      unusableQuantity: 3,
      lowStockThreshold: 0,
      isConsumable: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseReadyProvider.overrideWith((ref) async {}),
          equipmentProvider.overrideWith((ref) async => [item]),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hors service'), findsWidgets);
    expect(find.text('Activité récente'), findsNothing);
  });

  testWidgets('automatically uses the system dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseReadyProvider.overrideWith((ref) async {}),
          equipmentProvider.overrideWith((ref) async => []),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pumpAndSettle();

    final inventoryText = tester.element(
      find.text('Votre inventaire commence ici'),
    );
    expect(Theme.of(inventoryText).brightness, Brightness.dark);
    expect(find.text('Emprunts'), findsNothing);
  });

  testWidgets('offers sharing a backup from the actions menu', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseReadyProvider.overrideWith((ref) async {}),
          equipmentProvider.overrideWith((ref) async => []),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Partager une sauvegarde'), findsOneWidget);
  });

  testWidgets('keeps the save action visible on the equipment form', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: EquipmentFormPage(item: null)),
      ),
    );

    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
