/// Short, human relative time (e.g. "just now", "5m ago", "3d ago", "2026-05-31").
String relativeTime(DateTime t) {
  final local = t.toLocal();
  final d = DateTime.now().difference(local);
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
