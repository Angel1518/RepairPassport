import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_controller.dart';
import '../data/passport_repository.dart';
import '../models/passport_models.dart';

final passportRepositoryProvider = Provider<PassportRepository>(
  (ref) => PassportRepository(),
);

class PassportState {
  const PassportState({
    this.objects = const [],
    this.repairs = const [],
    this.parts = const [],
  });

  final List<Objeto> objects;
  final List<Reparacion> repairs;
  final List<Pieza> parts;
}

class PassportController extends AsyncNotifier<PassportState> {
  @override
  Future<PassportState> build() async => _loadAll();

  PassportRepository get _repo => ref.read(passportRepositoryProvider);

  Future<PassportState> _loadAll() async {
    final objects = await _repo.listObjects();
    final repairs = await _repo.listRepairs();
    final parts = await _repo.listParts();
    return PassportState(objects: objects, repairs: repairs, parts: parts);
  }

  Future<Objeto> addObject({
    required String name,
    required String category,
    String brandModel = '',
    String serialNumber = '',
    String notes = '',
  }) async {
    final obj = Objeto(
      id: 'obj_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      category: category.trim().isEmpty ? 'General' : category.trim(),
      brandModel: brandModel.trim(),
      serialNumber: serialNumber.trim(),
      notes: notes.trim(),
      createdAt: DateTime.now(),
    );
    await _repo.upsertObject(obj);
    state = AsyncData(await _loadAll());
    return obj;
  }

  Future<void> deleteObject(String objectId) async {
    await _repo.deleteObject(objectId);
    state = AsyncData(await _loadAll());
  }

  Future<void> addRepair({
    required String objectId,
    required DateTime date,
    required String symptom,
    required String solution,
    String performedBy = 'Propio / DIY',
    double costEur = 0.0,
    int warrantyMonths = 0,
    List<Pieza> parts = const [],
    bool isConfirmed = true,
  }) async {
    final repairId = 'rep_${DateTime.now().microsecondsSinceEpoch}';
    final repair = Reparacion(
      id: repairId,
      objectId: objectId,
      date: date,
      symptom: symptom.trim(),
      solution: solution.trim(),
      performedBy: performedBy.trim().isEmpty ? 'Propio / DIY' : performedBy.trim(),
      costEur: costEur,
      warrantyMonths: warrantyMonths,
      isConfirmed: isConfirmed,
    );
    final linkedParts = parts
        .map(
          (p) => Pieza(
            id: p.id,
            repairId: repairId,
            name: p.name,
            partCode: p.partCode,
            source: p.source,
            costEur: p.costEur,
          ),
        )
        .toList();

    await _repo.saveRepairWithParts(repair: repair, parts: linkedParts);
    state = AsyncData(await _loadAll());
  }

  Future<void> confirmRepair(Reparacion repair) async {
    await _repo.saveRepairWithParts(
      repair: repair.copyWith(isConfirmed: true),
    );
    state = AsyncData(await _loadAll());
  }

  Future<void> proposeRepairWithAi({
    required String objectId,
    required String reviewedNotes,
  }) async {
    final ai = ref.read(aiSettingsProvider.notifier);
    final resp = await ai.runStructured(
      taskInstruction:
          'Estructura una nota técnica informal de reparación en síntoma, solución y coste estimado si aparece explícito. '
          'No inventes precios, piezas ni fechas.',
      reviewedText: reviewedNotes,
      jsonSchemaHint: '''
{
  "symptom": "problema observado",
  "solution": "arreglo realizado",
  "cost_eur": 0,
  "parts": [{"name": "pieza", "part_code": ""}]
}''',
    );

    final json = resp.parsedJson;
    if (json == null) return;
    final symptom = json['symptom']?.toString().trim() ?? '';
    if (symptom.isEmpty) return;

    final rawParts = json['parts'] as List<dynamic>? ?? const [];
    final now = DateTime.now().microsecondsSinceEpoch;
    final parts = <Pieza>[];
    for (var i = 0; i < rawParts.length; i++) {
      final p = rawParts[i];
      if (p is! Map<String, dynamic>) continue;
      final name = p['name']?.toString().trim() ?? '';
      if (name.isEmpty) continue;
      parts.add(
        Pieza(
          id: 'part_${now}_$i',
          repairId: 'pending',
          name: name,
          partCode: p['part_code']?.toString() ?? '',
        ),
      );
    }

    await addRepair(
      objectId: objectId,
      date: DateTime.now(),
      symptom: symptom,
      solution: json['solution']?.toString() ?? '',
      costEur: double.tryParse(json['cost_eur']?.toString() ?? '0') ?? 0.0,
      parts: parts,
      isConfirmed: false,
    );
  }
}

final passportControllerProvider =
    AsyncNotifierProvider<PassportController, PassportState>(
  PassportController.new,
);

