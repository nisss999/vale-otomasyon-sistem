import 'dart:math';

class ParkedCar {
  final int? id;
  final String plate;
  final double latitude;
  final double longitude;
  final String timestamp;
  final String? note;
  final String? floorInfo;
  final String carType;
  final String ticketCode;
  final String keyLocation;
  final bool isDelivered;
  final String? deliveredTimestamp;

  ParkedCar({
    this.id,
    required this.plate,
    required this.latitude,
    required this.longitude,
    String? timestamp,
    this.note,
    this.floorInfo,
    this.carType = 'Sedan',
    String? ticketCode,
    this.keyLocation = 'Cebimde',
    this.isDelivered = false,
    this.deliveredTimestamp,
  })  : timestamp = timestamp ?? DateTime.now().toIso8601String(),
        ticketCode = ticketCode ?? _generateTicketCode();

  static String _generateTicketCode() {
    final random = Random();
    final number = 1000 + random.nextInt(9000);
    return '#VALE-$number';
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'plate': plate,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp,
      'note': note,
      'floorInfo': floorInfo,
      'carType': carType,
      'ticketCode': ticketCode,
      'keyLocation': keyLocation,
      'isDelivered': isDelivered ? 1 : 0,
      'deliveredTimestamp': deliveredTimestamp,
    };
  }

  factory ParkedCar.fromMap(Map<String, dynamic> map) {
    return ParkedCar(
      id: map['id'] as int?,
      plate: map['plate'] as String? ?? '',
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      timestamp: map['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      note: map['note'] as String?,
      floorInfo: map['floorInfo'] as String?,
      carType: map['carType'] as String? ?? 'Sedan',
      ticketCode: map['ticketCode'] as String? ?? _generateTicketCode(),
      keyLocation: map['keyLocation'] as String? ?? 'Cebimde',
      isDelivered: (map['isDelivered'] as int? ?? 0) == 1,
      deliveredTimestamp: map['deliveredTimestamp'] as String?,
    );
  }

  Duration get totalDuration {
    try {
      final startTime = DateTime.parse(timestamp);
      final endTime = deliveredTimestamp != null
          ? DateTime.parse(deliveredTimestamp!)
          : DateTime.now();
      return endTime.difference(startTime);
    } catch (_) {
      return Duration.zero;
    }
  }

  String get formattedDuration {
    final duration = totalDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours saat $minutes dk';
    } else if (minutes > 0) {
      return '$minutes dk';
    } else {
      return '1 dk\'dan az';
    }
  }
}
