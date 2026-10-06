import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kito/app.dart';
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
          movementsProvider.overrideWith((ref) async => []),
          historyProvider.overrideWith((ref) async => []),
        ],
        child: const KitoApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kito'), findsOneWidget);
    expect(find.text('Votre inventaire commence ici'), findsOneWidget);
    expect(find.text('Ajouter du matériel'), findsWidgets);
    expect(find.text('Emprunts'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
  });
}
