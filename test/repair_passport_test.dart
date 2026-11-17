import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repair_passport/core/theme/app_theme.dart';
import 'package:repair_passport/features/passport/controllers/passport_controller.dart';
import 'package:repair_passport/features/passport/data/passport_repository.dart';
import 'package:repair_passport/features/passport/models/passport_models.dart';
import 'package:repair_passport/features/passport/services/passport_exporter.dart';
import 'package:repair_passport/features/passport/ui/objects_screen.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;

  test('PassportExporter builds valid QR JSON, ZIP with manifest, and PDF', () async {
    final obj = Objeto(
      id: 'obj_1',
      name: 'Cafetera Espresso',
      category: 'Hogar',
      brandModel: 'Gaggia Classic',
      serialNumber: 'GC-9921',
      createdAt: DateTime(2026, 11, 17),
    );
    final repair = Reparacion(
      id: 'rep_1',
      objectId: 'obj_1',
      date: DateTime(2026, 10, 5),
      symptom: 'Fuga en grupo',
      solution: 'Cambio de junta silicona 8.5mm',
      costEur: 14.5,
      warrantyMonths: 12,
    );
    const part = Pieza(
      id: 'part_1',
      repairId: 'rep_1',
      name: 'Junta grupo silicona',
      partCode: 'SIL-85',
      costEur: 9.5,
    );

    final qrJson = jsonDecode(
      PassportExporter.buildCompactQrPayload(object: obj, repairs: [repair]),
    ) as Map<String, dynamic>;
    expect(qrJson['schema'], 'repairpassport.v1');
    expect(qrJson['repairs_count'], 1);
    expect(qrJson['total_eur'], 14.5);

    final zipBytes = PassportExporter.buildZipBytes(
      object: obj,
      repairs: [repair],
      parts: [part],
    );
    final decodedZip = ZipDecoder().decodeBytes(zipBytes);
    expect(
      decodedZip.files.map((f) => f.name),
      containsAll(['passport.json', 'summary.txt', 'manifest.sha256']),
    );

    final pdfBytes = await PassportExporter.buildPdfBytes(
      object: obj,
      repairs: [repair],
      parts: [part],
    );
    expect(pdfBytes.length, greaterThan(500));
  });

  test('PassportRepository persists objects, repairs and parts in SQLite', () async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: PassportRepository.createSchema,
    );
    final repo = PassportRepository(testDb: db);
    final obj = Objeto(
      id: 'obj_db',
      name: 'Taladro percutor',
      category: 'Herramientas',
      createdAt: DateTime(2026, 11, 17),
    );
    await repo.upsertObject(obj);
    await repo.saveRepairWithParts(
      repair: Reparacion(
        id: 'rep_db',
        objectId: 'obj_db',
        date: DateTime(2026, 11, 17),
        symptom: 'Escobillas gastadas',
        solution: 'Sustitución de escobillas',
        costEur: 12,
      ),
      parts: const [
        Pieza(id: 'p_db', repairId: 'rep_db', name: 'Juego escobillas 6x9'),
      ],
    );

    expect((await repo.listObjects()).length, 1);
    expect((await repo.listRepairs()).length, 1);
    expect((await repo.listParts()).length, 1);

    await repo.deleteObject('obj_db');
    expect(await repo.listObjects(), isEmpty);
    expect(await repo.listRepairs(), isEmpty);
    expect(await repo.listParts(), isEmpty);
    await db.close();
  });

  testWidgets('ObjectsScreen handles 320px width and 200% TextScaler with long names', (tester) async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: PassportRepository.createSchema,
    );
    final repo = PassportRepository(testDb: db);
    await repo.upsertObject(
      Objeto(
        id: 'obj_long',
        name: 'Objeto_${'X' * 100}',
        category: 'Electrónica',
        brandModel: 'Modelo_${'Y' * 60}',
        createdAt: DateTime(2026, 11, 17),
      ),
    );

    await tester.binding.setSurfaceSize(const Size(320, 568));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [passportRepositoryProvider.overrideWithValue(repo)],
        child: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(2.0),
          ),
          child: MaterialApp(
            theme: AppTheme.light(accent: const Color(0xFF15803D)),
            home: const ObjectsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
    await db.close();
  });
}
