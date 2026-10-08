/// Dátum- és időformázás (en_GB): 08/10/2026, 07:30, "Thursday, 8 October 2026".
/// Szándékosan függőség nélkül, hogy egyszerűen tesztelhető legyen.
library;

const _weekdays = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
];

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _two(int n) => n.toString().padLeft(2, '0');

/// 08/10/2026
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 07:30
String formatTime(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

/// 08/10/2026 07:30
String formatDateTime(DateTime d) => '${formatDate(d)} ${formatTime(d)}';

/// Thursday, 8 October 2026
String formatDayHeader(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

/// 2026-10-08 (ISO 8601 – exportokhoz, fájlnevekhez)
String formatIsoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// 2026-10-08T07:30:00 – helyi idő, időzóna nélkül (adatbázis)
String formatLocalIsoDateTime(DateTime d) =>
    '${formatIsoDate(d)}T${_two(d.hour)}:${_two(d.minute)}:${_two(d.second)}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
