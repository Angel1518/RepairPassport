class Objeto {
  const Objeto({
    required this.id,
    required this.name,
    required this.category,
    this.brandModel = '',
    this.serialNumber = '',
    this.purchaseDate,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String name;
  final String category;
  final String brandModel;
  final String serialNumber;
  final DateTime? purchaseDate;
  final String notes;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
        'brand_model': brandModel,
        'serial_number': serialNumber,
        'purchase_date_iso': purchaseDate?.toIso8601String(),
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };

  factory Objeto.fromMap(Map<String, dynamic> map) => Objeto(
        id: map['id'] as String,
        name: map['name'] as String,
        category: map['category'] as String? ?? 'General',
        brandModel: map['brand_model'] as String? ?? '',
        serialNumber: map['serial_number'] as String? ?? '',
        purchaseDate: map['purchase_date_iso'] != null
            ? DateTime.tryParse(map['purchase_date_iso'] as String)
            : null,
        notes: map['notes'] as String? ?? '',
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}

class Reparacion {
  const Reparacion({
    required this.id,
    required this.objectId,
    required this.date,
    required this.symptom,
    required this.solution,
    this.performedBy = 'Propio / DIY',
    this.costEur = 0.0,
    this.warrantyMonths = 0,
    this.isConfirmed = true,
  });

  final String id;
  final String objectId;
  final DateTime date;
  final String symptom;
  final String solution;
  final String performedBy;
  final double costEur;
  final int warrantyMonths;
  final bool isConfirmed;

  Reparacion copyWith({
    String? symptom,
    String? solution,
    String? performedBy,
    double? costEur,
    int? warrantyMonths,
    bool? isConfirmed,
  }) {
    return Reparacion(
      id: id,
      objectId: objectId,
      date: date,
      symptom: symptom ?? this.symptom,
      solution: solution ?? this.solution,
      performedBy: performedBy ?? this.performedBy,
      costEur: costEur ?? this.costEur,
      warrantyMonths: warrantyMonths ?? this.warrantyMonths,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'object_id': objectId,
        'date_iso': date.toIso8601String(),
        'symptom': symptom,
        'solution': solution,
        'performed_by': performedBy,
        'cost_eur': costEur,
        'warranty_months': warrantyMonths,
        'is_confirmed': isConfirmed ? 1 : 0,
      };

  factory Reparacion.fromMap(Map<String, dynamic> map) => Reparacion(
        id: map['id'] as String,
        objectId: map['object_id'] as String,
        date: DateTime.parse(map['date_iso'] as String),
        symptom: map['symptom'] as String,
        solution: map['solution'] as String? ?? '',
        performedBy: map['performed_by'] as String? ?? 'Propio / DIY',
        costEur: (map['cost_eur'] as num?)?.toDouble() ?? 0.0,
        warrantyMonths: map['warranty_months'] as int? ?? 0,
        isConfirmed: (map['is_confirmed'] as int? ?? 1) == 1,
      );
}

class Pieza {
  const Pieza({
    required this.id,
    required this.repairId,
    required this.name,
    this.partCode = '',
    this.source = '',
    this.costEur = 0.0,
  });

  final String id;
  final String repairId;
  final String name;
  final String partCode;
  final String source;
  final double costEur;

  Map<String, dynamic> toMap() => {
        'id': id,
        'repair_id': repairId,
        'name': name,
        'part_code': partCode,
        'source': source,
        'cost_eur': costEur,
      };

  factory Pieza.fromMap(Map<String, dynamic> map) => Pieza(
        id: map['id'] as String,
        repairId: map['repair_id'] as String,
        name: map['name'] as String,
        partCode: map['part_code'] as String? ?? '',
        source: map['source'] as String? ?? '',
        costEur: (map['cost_eur'] as num?)?.toDouble() ?? 0.0,
      );
}

class Adjunto {
  const Adjunto({
    required this.id,
    required this.objectId,
    this.repairId,
    required this.label,
    required this.localPath,
    required this.sha256,
  });

  final String id;
  final String objectId;
  final String? repairId;
  final String label;
  final String localPath;
  final String sha256;

  Map<String, dynamic> toMap() => {
        'id': id,
        'object_id': objectId,
        'repair_id': repairId,
        'label': label,
        'local_path': localPath,
        'sha256': sha256,
      };

  factory Adjunto.fromMap(Map<String, dynamic> map) => Adjunto(
        id: map['id'] as String,
        objectId: map['object_id'] as String,
        repairId: map['repair_id'] as String?,
        label: map['label'] as String,
        localPath: map['local_path'] as String,
        sha256: map['sha256'] as String? ?? '',
      );
}

class Exportacion {
  const Exportacion({
    required this.id,
    required this.objectId,
    required this.format,
    required this.createdAt,
    required this.sha256,
  });

  final String id;
  final String objectId;
  final String format; // 'qr', 'json', 'zip', 'pdf'
  final DateTime createdAt;
  final String sha256;

  Map<String, dynamic> toMap() => {
        'id': id,
        'object_id': objectId,
        'format': format,
        'created_at': createdAt.toIso8601String(),
        'sha256': sha256,
      };

  factory Exportacion.fromMap(Map<String, dynamic> map) => Exportacion(
        id: map['id'] as String,
        objectId: map['object_id'] as String,
        format: map['format'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        sha256: map['sha256'] as String? ?? '',
      );
}

