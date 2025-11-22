class ChartDataPoint {
  final String label;
  final int count;

  ChartDataPoint({
    required this.label,
    required this.count,
  });
}

class TripItem {
  final String tripId;
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;
  final double fareAmount;
  final double distanceKm;
  final String? driverName;
  final String? vehiclePlate;
  final String? driverId;

  TripItem({
    required this.tripId,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.tripCode,
    required this.status,
    required this.fareAmount,
    required this.distanceKm,
    this.driverName,
    this.vehiclePlate,
    this.driverId,
  });
}

class AnalyticsData {
  final String period;
  final int totalTrips;
  final double totalDistance;
  final double totalSpent;

  AnalyticsData({
    required this.period,
    required this.totalTrips,
    required this.totalDistance,
    required this.totalSpent,
  });
}

class TripDetails {
  final String tripId;
  final String date;
  final String time;
  final String from;
  final String to;
  final String tripCode;
  final String status;
  final double fareAmount;
  final double distanceKm;
  final String? driverName;
  final String? vehiclePlate;
  final String? driverId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int passengerCount;
  final String? originStopId;
  final String? destinationStopId;
  final List<Map<String, dynamic>>? routeStops;
  final double? originLat;
  final double? originLng;
  final double? destLat;
  final double? destLng;
  final String? transactionNumber;
  final String? passengerName;

  TripDetails({
    required this.tripId,
    required this.date,
    required this.time,
    required this.from,
    required this.to,
    required this.tripCode,
    required this.status,
    required this.fareAmount,
    required this.distanceKm,
    this.driverName,
    this.vehiclePlate,
    this.driverId,
    required this.startedAt,
    this.endedAt,
    required this.passengerCount,
    this.originStopId,
    this.destinationStopId,
    this.routeStops,
    this.originLat,
    this.originLng,
    this.destLat,
    this.destLng,
    this.transactionNumber,
    this.passengerName,
  });

  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  String get formattedDuration {
    final dur = duration;
    if (dur == null) return 'Ongoing';
    
    final hours = dur.inHours;
    final minutes = dur.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  String get formattedStartTime {
    final hour = startedAt.hour > 12 ? startedAt.hour - 12 : startedAt.hour;
    final period = startedAt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${startedAt.minute.toString().padLeft(2, '0')}$period';
  }

  String get formattedEndTime {
    if (endedAt == null) return 'Ongoing';
    final hour = endedAt!.hour > 12 ? endedAt!.hour - 12 : endedAt!.hour;
    final period = endedAt!.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${endedAt!.minute.toString().padLeft(2, '0')}$period';
  }
}