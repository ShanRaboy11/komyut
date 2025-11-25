class NotifItem {
  final String id;
  final String virtualId;
  final String tripId;
  final String variant; // 'trips', 'wallet', 'rewards'
  final String title;
  final String timeOrDate;
  bool isRead;
  final DateTime sortDate;
  final Map<String, dynamic>? payload; // {trip_id, status, amount, ...}
  final bool isLocal;

  NotifItem({
    required this.id,
    required this.virtualId,
    this.tripId = '',
    required this.variant,
    required this.title,
    required this.timeOrDate,
    required this.isRead,
    required this.sortDate,
    this.payload,
    this.isLocal = false,
  });
}
