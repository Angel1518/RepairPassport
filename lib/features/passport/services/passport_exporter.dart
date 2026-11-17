import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/passport_models.dart';

class PassportExporter {
  static String buildCompactQrPayload({
    required Objeto object,
    required List<Reparacion> repairs,
  }) {
    final confirmed = repairs.where((r) => r.isConfirmed).toList();
    final totalCost = confirmed.fold<double>(0.0, (s, r) => s + r.costEur);
    final payload = {
      'schema': 'repairpassport.v1',
      'name': object.name,
      'brand': object.brandModel,
      'serial': object.serialNumber,
      'repairs_count': confirmed.length,
      'total_eur': double.parse(totalCost.toStringAsFixed(2)),
      'latest': confirmed
          .take(3)
          .map(
            (r) => {
              'd': DateFormat('yyyy-MM-dd').format(r.date),
              's': r.symptom,
              'f': r.solution,
            },
          )
          .toList(),
    };
    return jsonEncode(payload);
  }

  static String buildFullJson({
    required Objeto object,
    required List<Reparacion> repairs,
    required List<Pieza> parts,
  }) {
    final map = {
      'schema': 'repairpassport.full.v1',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'object': object.toMap(),
      'repairs': repairs.map((r) => r.toMap()).toList(),
      'parts': parts.map((p) => p.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static Uint8List buildZipBytes({
    required Objeto object,
    required List<Reparacion> repairs,
    required List<Pieza> parts,
  }) {
    final jsonStr = buildFullJson(
      object: object,
      repairs: repairs,
      parts: parts,
    );
    final jsonBytes = utf8.encode(jsonStr);
    final jsonHash = sha256.convert(jsonBytes).toString();

    final summary = StringBuffer()
      ..writeln('RepairPassport — Pasaporte de mantenimiento')
      ..writeln('Objeto: ${object.name}')
      ..writeln('Categoría: ${object.category}')
      ..writeln('Marca/Modelo: ${object.brandModel}')
      ..writeln('N.º de serie: ${object.serialNumber}')
      ..writeln('Reparaciones registradas: ${repairs.length}')
      ..writeln('Piezas registradas: ${parts.length}');

    final summaryBytes = utf8.encode(summary.toString());
    final manifest = utf8.encode(
      'passport.json  sha256:$jsonHash\n'
      'summary.txt    sha256:${sha256.convert(summaryBytes)}\n',
    );

    final archive = Archive()
      ..addFile(ArchiveFile('passport.json', jsonBytes.length, jsonBytes))
      ..addFile(ArchiveFile('summary.txt', summaryBytes.length, summaryBytes))
      ..addFile(ArchiveFile('manifest.sha256', manifest.length, manifest));

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static Future<Uint8List> buildPdfBytes({
    required Objeto object,
    required List<Reparacion> repairs,
    required List<Pieza> parts,
  }) async {
    final doc = pw.Document();
    final fmt = DateFormat('dd/MM/yyyy');

    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'RepairPassport · ${object.name}',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Paragraph(
            text:
                'Categoría: ${object.category} | Marca/Modelo: ${object.brandModel} | Serie: ${object.serialNumber}',
          ),
          if (object.notes.isNotEmpty) pw.Paragraph(text: object.notes),
          pw.SizedBox(height: 12),
          pw.Text(
            'Historial de reparaciones (${repairs.length})',
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          ...repairs.map((r) {
            final repairParts = parts.where((p) => p.repairId == r.id).toList();
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${fmt.format(r.date)} · ${r.symptom}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  if (r.solution.isNotEmpty) pw.Text('Solución: ${r.solution}'),
                  pw.Text(
                    'Realizado por: ${r.performedBy} · Coste: ${r.costEur.toStringAsFixed(2)} EUR · Garantía: ${r.warrantyMonths} meses',
                  ),
                  if (repairParts.isNotEmpty)
                    pw.Text(
                      'Piezas: ${repairParts.map((p) => '${p.name} (${p.partCode})').join(', ')}',
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    return doc.save();
  }
}

