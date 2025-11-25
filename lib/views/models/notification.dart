class NotifItem {
  final String id; // DB ID or Virtual ID
  final String virtualId; // Unique Key for UI (e.g., "start_123")
  final String tripId;
  final String variant; // 'trips', 'wallet', 'others'
  final String title;
  final String timeOrDate;
  bool isRead;
  final DateTime sortDate;
  final Map<String, dynamic>? payload; // {trip_id: ..., status: ...}
  final bool isLocal; // True for hardcoded Wallet/Others

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
