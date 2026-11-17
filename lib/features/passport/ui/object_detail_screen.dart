import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/ai/ai_controller.dart';
import '../../../core/ai/privacy_preview_dialog.dart';
import '../controllers/passport_controller.dart';
import '../models/passport_models.dart';
import '../services/passport_exporter.dart';

class ObjectDetailScreen extends ConsumerWidget {
  const ObjectDetailScreen({super.key, required this.objectId});

  final String objectId;

  Future<void> _showAddRepairDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final symptomCtrl = TextEditingController();
    final solutionCtrl = TextEditingController();
    final byCtrl = TextEditingController(text: 'Propio / DIY');
    final costCtrl = TextEditingController(text: '0');
    final partNameCtrl = TextEditingController();
    final partCodeCtrl = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar reparación'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: symptomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Síntoma o fallo',
                    hintText: 'Ej. Batería agotada al 20%',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: solutionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Solución aplicada',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: byCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Realizado por',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: costCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coste total (€)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: partNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Pieza sustituida (opcional)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: partCodeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Referencia de pieza (opcional)',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (saved == true && symptomCtrl.text.trim().isNotEmpty) {
      final parts = <Pieza>[];
      if (partNameCtrl.text.trim().isNotEmpty) {
        parts.add(
          Pieza(
            id: 'part_${DateTime.now().microsecondsSinceEpoch}',
            repairId: 'pending',
            name: partNameCtrl.text.trim(),
            partCode: partCodeCtrl.text.trim(),
          ),
        );
      }

      await ref.read(passportControllerProvider.notifier).addRepair(
            objectId: objectId,
            date: DateTime.now(),
            symptom: symptomCtrl.text,
            solution: solutionCtrl.text,
            performedBy: byCtrl.text,
            costEur: double.tryParse(costCtrl.text.replaceAll(',', '.')) ?? 0.0,
            parts: parts,
          );
    }
  }

  Future<void> _showQrDialog(
    BuildContext context,
    Objeto obj,
    List<Reparacion> repairs,
  ) async {
    final payload = PassportExporter.buildCompactQrPayload(
      object: obj,
      repairs: repairs,
    );
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pasaporte QR offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 220,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Escaneable sin internet con el resumen de reparaciones confirmadas.',
              style: Theme.of(ctx).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportZipOrPdf({
    required BuildContext context,
    required Objeto obj,
    required List<Reparacion> repairs,
    required List<Pieza> parts,
    required bool asPdf,
  }) async {
    try {
      final dir = await getTemporaryDirectory();
      final fileName = asPdf
          ? 'pasaporte_${obj.id}.pdf'
          : 'pasaporte_${obj.id}.zip';
      final file = File(p.join(dir.path, fileName));
      final bytes = asPdf
          ? await PassportExporter.buildPdfBytes(
              object: obj,
              repairs: repairs,
              parts: parts,
            )
          : PassportExporter.buildZipBytes(
              object: obj,
              repairs: repairs,
              parts: parts,
            );
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)],
          subject: 'Pasaporte ${obj.name}');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  Future<void> _runAiNoteHelper(
    BuildContext context,
    WidgetRef ref,
    Objeto obj,
  ) async {
    final aiSettings = ref.read(aiSettingsProvider);
    if (!aiSettings.enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activa la IA BYOK en Ajustes si deseas usarla.'),
        ),
      );
      return;
    }

    final reviewed = await showPrivacyPreviewDialog(
      context: context,
      settings: aiSettings,
      initialText:
          'Objeto: ${obj.name}\nNota informal: ',
      title: 'Estructurar nota técnica con IA',
    );
    if (reviewed == null || reviewed.isEmpty) return;

    try {
      await ref
          .read(passportControllerProvider.notifier)
          .proposeRepairWithAi(objectId: obj.id, reviewedNotes: reviewed);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error IA: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(passportControllerProvider);
    final theme = Theme.of(context);
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Pasaporte del objeto')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRepairDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Reparación'),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (data) {
          final obj =
              data.objects.where((o) => o.id == objectId).firstOrNull;
          if (obj == null) {
            return const Center(child: Text('Objeto no encontrado.'));
          }
          final repairs =
              data.repairs.where((r) => r.objectId == obj.id).toList();
          final repairIds = repairs.map((r) => r.id).toSet();
          final parts =
              data.parts.where((p) => repairIds.contains(p.repairId)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              Text(obj.name, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                '${obj.category}${obj.brandModel.isNotEmpty ? ' · ${obj.brandModel}' : ''}${obj.serialNumber.isNotEmpty ? ' · S/N ${obj.serialNumber}' : ''}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _showQrDialog(context, obj, repairs),
                    icon: const Icon(Icons.qr_code_2),
                    label: const Text('QR Offline'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportZipOrPdf(
                      context: context,
                      obj: obj,
                      repairs: repairs,
                      parts: parts,
                      asPdf: true,
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Exportar PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportZipOrPdf(
                      context: context,
                      obj: obj,
                      repairs: repairs,
                      parts: parts,
                      asPdf: false,
                    ),
                    icon: const Icon(Icons.folder_zip_outlined),
                    label: const Text('Exportar ZIP'),
                  ),
                  TextButton.icon(
                    onPressed: () => _runAiNoteHelper(context, ref, obj),
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Estructurar nota (IA)'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Línea temporal (${repairs.length})',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (repairs.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Aún no hay reparaciones registradas para este objeto.',
                    ),
                  ),
                )
              else
                ...repairs.map((r) {
                  final rParts =
                      parts.where((p) => p.repairId == r.id).toList();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    r.symptom,
                                    style: theme.textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  fmt.format(r.date),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                            if (r.solution.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(r.solution,
                                  style: theme.textTheme.bodyLarge),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Chip(label: Text(r.performedBy)),
                                Chip(
                                    label: Text(
                                        '${r.costEur.toStringAsFixed(2)} €')),
                                if (!r.isConfirmed)
                                  ActionChip(
                                    label: const Text('Confirmar propuesta'),
                                    onPressed: () => ref
                                        .read(passportControllerProvider
                                            .notifier)
                                        .confirmRepair(r),
                                  ),
                                ...rParts.map(
                                  (pt) => Chip(
                                    avatar: const Icon(Icons.memory, size: 16),
                                    label: Text(pt.name),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

