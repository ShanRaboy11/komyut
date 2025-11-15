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