import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sorteosdominicanos_app/app/app_features.dart';
import 'package:sorteosdominicanos_app/app/theme/app_theme.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/application/publishable_catalog.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/data/dreams_catalog_loader.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/domain/catalog_validation.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dream_decoder_page.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dream_dictionary_page.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dream_table_page.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dreams_content_state.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dreams_navigation.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/dreams_numbers_home_page.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/widgets/dreams_entry_widgets.dart';
import 'package:sorteosdominicanos_app/features/dreams_numbers/presentation/widgets/dreams_shared_widgets.dart';

Widget testApp(Widget child) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: child,
    );

PublishableDreamsCatalog approvedCatalog() {
  final json = jsonDecode(
    File('test/fixtures/dreams_numbers_fixture.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final metadata = json['metadata'] as Map<String, dynamic>;
  metadata['schemaVersion'] = '1.2.0';
  metadata['editorialStatus'] = 'approved';
  final evidence = <Map<String, dynamic>>[];
  for (final source in json['sources'] as List<dynamic>) {
    source['rightsStatus'] = 'authorized';
    source['verificationStatus'] = 'verified';
    final sourceId = source['id'] as String;
    evidence.add({
      'id': 'evidence_$sourceId',
      'sourceId': sourceId,
      'rightsHolder': 'Titular sintético',
      'authorizationType': 'writtenPermission',
      'legalBasisType': 'explicitPermission',
      'evidenceReference': 'fixture://$sourceId',
      'evidenceDate': '2026-01-01',
      'validFrom': '2026-01-01',
      'validUntil': '2027-12-31',
      'indefiniteTermJustification': null,
      'territory': 'worldwide',
      'territories': <String>[],
      'commercialUseAllowed': true,
      'redistributionAllowed': true,
      'derivativeWorksAllowed': true,
      'attributionRequired': false,
      'restrictions': <String>[],
      'reviewStatus': 'approved',
      'reviewedAt': '2026-01-02',
      'scopeType': 'fullSource',
      'scopeReferences': [sourceId],
    });
  }
  for (final claim in json['claims'] as List<dynamic>) {
    claim['verificationStatus'] = 'verified';
    claim['rightsEvidenceIds'] = ['evidence_${claim['sourceId']}'];
  }
  for (final interpretation in json['interpretations'] as List<dynamic>) {
    interpretation['verificationStatus'] = 'verified';
    interpretation['publicationStatus'] = 'approved';
    interpretation['rightsEvidenceIds'] =
        (interpretation['sourceReferences'] as List<dynamic>)
            .map((id) => 'evidence_$id')
            .toList();
  }
  json['rightsEvidence'] = evidence;
  json['articles'] = <dynamic>[];
  final catalog = DreamsCatalogLoader().loadString(jsonEncode(json));
  return const PublishableCatalogGate()
      .evaluate(
        catalog,
        context: PublicationContext(referenceDate: DateTime.utc(2026, 11, 9)),
      )
      .catalog!;
}

void main() {
  group('module navigation', () {
    test('feature flag is disabled by default', () {
      expect(AppFeatures.dreamsNumbersEnabled, isFalse);
    });

    testWidgets('hides the promotional card and drawer entry when disabled',
        (tester) async {
      await tester.pumpWidget(testApp(
        Scaffold(
          body: Column(
            children: [
              DreamsModulePromoCard(enabled: false, onTap: () {}),
              DreamsDrawerTile(enabled: false, onTap: () {}),
            ],
          ),
        ),
      ));

      expect(find.text('Sueños y Números Dominicanos'), findsNothing);
      expect(find.text('Sueños y Números'), findsNothing);
    });

    testWidgets('blocks navigation when the feature is disabled',
        (tester) async {
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => openDreamsNumbersModule(context, enabled: false),
            child: const Text('Intentar abrir'),
          ),
        ),
      )));

      await tester.tap(find.text('Intentar abrir'));
      await tester.pumpAndSettle();
      expect(find.byType(DreamsNumbersHomePage), findsNothing);
    });

    testWidgets('opens from the home promotional card and returns',
        (tester) async {
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => Scaffold(
          body: DreamsModulePromoCard(
            enabled: true,
            onTap: () => openDreamsNumbersModule(context, enabled: true),
          ),
        ),
      )));

      await tester.tap(find.text('Sueños y Números Dominicanos'));
      await tester.pumpAndSettle();
      expect(find.byType(DreamsNumbersHomePage), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(DreamsModulePromoCard), findsOneWidget);
    });

    testWidgets('opens the same module from the drawer entry', (tester) async {
      await tester.pumpWidget(testApp(Builder(
        builder: (context) => Scaffold(
          body: DreamsDrawerTile(
            enabled: true,
            onTap: () => openDreamsNumbersModule(context, enabled: true),
          ),
        ),
      )));

      await tester.tap(find.text('Sueños y Números'));
      await tester.pumpAndSettle();
      expect(find.byType(DreamsNumbersHomePage), findsOneWidget);
    });

    testWidgets('provides access to all six branches', (tester) async {
      await tester.pumpWidget(testApp(const DreamsNumbersHomePage()));
      const titles = [
        'Tabla Dominicana de Sueños',
        'Diccionario de Sueños',
        'Descifrador de Sueños',
        'Tradiciones y Creencias',
        'Variantes y Expresiones',
        'Numerología Dominicana',
      ];

      for (final title in titles) {
        await tester.scrollUntilVisible(find.text(title), 160);
        expect(find.text(title), findsOneWidget);
      }
    });
  });

  group('responsive and accessible presentation', () {
    testWidgets('fits a narrow screen with enlarged text', (tester) async {
      tester.view.physicalSize = const Size(320, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(1.8),
        ),
        child: testApp(const DreamsNumbersHomePage()),
      ));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(dreamsCulturalNotice), findsOneWidget);
    });

    testWidgets('renders the six explicit content states', (tester) async {
      for (final state in DreamsContentState.values) {
        await tester.pumpWidget(testApp(
          Scaffold(
            body: SingleChildScrollView(
              child: DreamsContentStateView(state: state),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('branch behavior without authorized content', () {
    testWidgets('table renders 00 and 99 and changes the selection',
        (tester) async {
      await tester.pumpWidget(testApp(const DreamTablePage()));
      expect(find.text('00'), findsWidgets);
      expect(find.text('99'), findsOneWidget);

      await tester.tap(find.text('07'));
      await tester.pump();
      expect(find.text('Asociaciones para 07'), findsOneWidget);
      expect(find.text('Sin contenido autorizado'), findsOneWidget);
    });

    testWidgets('dictionary search remains empty without a catalog',
        (tester) async {
      await tester.pumpWidget(testApp(const DreamDictionaryPage()));
      await tester.enterText(find.byType(TextField), 'símbolo inexistente');
      await tester.pump();
      expect(find.text('Contenido en preparación'), findsOneWidget);
    });

    testWidgets('decoder handles empty text and does not expose numbers',
        (tester) async {
      await tester.pumpWidget(testApp(const DreamDecoderPage()));
      await tester.tap(find.text('Descifrar sueño'));
      await tester.pump();
      expect(find.text('Escribe una descripción antes de iniciar el análisis.'),
          findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Símbolo prueba A');
      await tester.tap(find.text('Descifrar sueño'));
      await tester.pump();
      expect(find.text('Sin contenido autorizado'), findsOneWidget);
      expect(find.text('10'), findsNothing);
      expect(find.text('20'), findsNothing);
    });
  });

  group('branches with a safe catalog', () {
    testWidgets('table renders approved claims without merging conflicts',
        (tester) async {
      await tester
          .pumpWidget(testApp(DreamTablePage(catalog: approvedCatalog())));
      await tester.tap(find.text('10'));
      await tester.pump();

      expect(find.text('Símbolo Prueba A'), findsOneWidget);
      expect(
          find.textContaining('Fuente sintética autorizada'), findsOneWidget);
    });

    testWidgets('dictionary searches through the safe wrapper', (tester) async {
      await tester
          .pumpWidget(testApp(DreamDictionaryPage(catalog: approvedCatalog())));
      await tester.enterText(find.byType(TextField), 'símbolo prueba a');
      await tester.pump();

      expect(find.text('Símbolo Prueba A'), findsOneWidget);
      expect(find.text('10, 20'), findsOneWidget);
    });

    testWidgets('decoder analyzes only through the safe wrapper',
        (tester) async {
      await tester
          .pumpWidget(testApp(DreamDecoderPage(catalog: approvedCatalog())));
      await tester.enterText(find.byType(TextField), 'Vi una señal alfa.');
      await tester.tap(find.text('Descifrar sueño'));
      await tester.pump();

      expect(find.text('Símbolo Prueba A'), findsOneWidget);
      expect(find.textContaining('10, 20'), findsOneWidget);
    });
  });

  group('editorial boundary', () {
    test('rejects the synthetic fixture at the presentation boundary', () {
      final catalog = DreamsCatalogLoader().loadString(
        File('test/fixtures/dreams_numbers_fixture.json').readAsStringSync(),
      );
      final result = const PublishableCatalogGate().evaluate(
        catalog,
        context: PublicationContext(referenceDate: DateTime.utc(2026, 11, 9)),
      );
      expect(result.isAvailable, isFalse);
      expect(result.catalog, isNull);
      expect(result.issues, isNotEmpty);
    });

    test('production assets do not reference synthetic fixtures', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final fixture = jsonDecode(
        File('test/fixtures/dreams_numbers_fixture.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(pubspec, isNot(contains('test/fixtures')));
      expect(jsonEncode(fixture), contains('simbolo_prueba_a'));
      expect(
        Directory('assets')
            .listSync(recursive: true)
            .whereType<File>()
            .any((file) => file.path.contains('dreams_numbers_fixture')),
        isFalse,
      );
    });

    test('production presentation cannot accept a raw DreamsCatalog', () {
      final presentationSources = Directory(
        'lib/features/dreams_numbers/presentation',
      )
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'));

      for (final file in presentationSources) {
        expect(
          RegExp(r'\bDreamsCatalog\b').hasMatch(file.readAsStringSync()),
          isFalse,
          reason: '${file.path} must use PublishableDreamsCatalog instead.',
        );
      }
    });
  });
}
