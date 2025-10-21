class DeviceModel {
  final int? id;
  final int? customerId;
  final int? enterpriseId;
  final int? planId;
  final String? imei;
  final String? device;
  final int type; // 1 - Android, 2 - iOS, 3 - Android TV
  final String? identifier;
  final int? licenceType; // 0 - Demo, 1 - Basic, 2 - Business, 3 - Enterprise
  final String? code;
  final String? brand;
  final String? model;
  final String? manufacturer;
  final String? serie;
  final int status; // 1- Active, 2- Locked, 3- Removed, 4- Kiosk
  final String? ownerIdentifier;
  final String? ownerName;
  final String? ownerEmail;
  final String? ownerPhone;
  final String? ownerAddress;
  final String? dueDate;
  final String? fcmToken;
  final String? nextLockDate;
  final String? heartbeat;
  final double? lat;
  final double? lng;
  final String? createdAt;
  final String? updatedAt;

  DeviceModel({
    this.id,
    this.customerId,
    this.enterpriseId,
    this.planId,
    this.imei,
    this.device,
    required this.type,
    this.identifier,
    this.licenceType,
    this.code,
    this.brand,
    this.model,
    this.manufacturer,
    this.serie,
    this.status = 1,
    this.ownerIdentifier,
    this.ownerName,
    this.ownerEmail,
    this.ownerPhone,
    this.ownerAddress,
    this.dueDate,
    this.fcmToken,
    this.nextLockDate,
    this.heartbeat,
    this.lat,
    this.lng,
    this.createdAt,
    this.updatedAt,
  });

  // Crear desde JSON
  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'],
      customerId: json['customer_id'],
      enterpriseId: json['enterprise_id'],
      planId: json['plan_id'],
      imei: json['imei'],
      device: json['device'],
      type: json['type'] ?? 1,
      identifier: json['identifier'],
      licenceType: json['licence_type'],
      code: json['code'],
      brand: json['brand'],
      model: json['model'],
      manufacturer: json['manufacturer'],
      serie: json['serie'],
      status: json['status'] ?? 1,
      ownerIdentifier: json['owner_identifier'],
      ownerName: json['owner_name'],
      ownerEmail: json['owner_email'],
      ownerPhone: json['owner_phone'],
      ownerAddress: json['owner_address'],
      dueDate: json['due_date'],
      fcmToken: json['fcm_token'],
      nextLockDate: json['next_lock_date'],
      heartbeat: json['heartbeat'],
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  // Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (enterpriseId != null) 'enterprise_id': enterpriseId,
      if (planId != null) 'plan_id': planId,
      if (imei != null) 'imei': imei,
      if (device != null) 'device': device,
      'type': type,
      if (identifier != null) 'identifier': identifier,
      if (licenceType != null) 'licence_type': licenceType,
      if (code != null) 'code': code,
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (manufacturer != null) 'manufacturer': manufacturer,
      if (serie != null) 'serie': serie,
      'status': status,
      if (ownerIdentifier != null) 'owner_identifier': ownerIdentifier,
      if (ownerName != null) 'owner_name': ownerName,
      if (ownerEmail != null) 'owner_email': ownerEmail,
      if (ownerPhone != null) 'owner_phone': ownerPhone,
      if (ownerAddress != null) 'owner_address': ownerAddress,
      if (dueDate != null) 'due_date': dueDate,
      if (fcmToken != null) 'fcm_token': fcmToken,
      if (nextLockDate != null) 'next_lock_date': nextLockDate,
      if (heartbeat != null) 'heartbeat': heartbeat,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }

  // Obtener nombre del tipo de dispositivo
  String get typeName {
    switch (type) {
      case 1:
        return 'Android';
      case 2:
        return 'iOS';
      case 3:
        return 'Android TV';
      default:
        return 'Desconocido';
    }
  }

  // Obtener nombre del estado
  String get statusName {
    switch (status) {
      case 1:
        return 'Activo';
      case 2:
        return 'Bloqueado';
      case 3:
        return 'Removido';
      case 4:
        return 'Kiosk';
      default:
        return 'Desconocido';
    }
  }
}
