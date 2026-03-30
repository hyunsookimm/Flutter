import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/file_service.dart';
import 'detail_page.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final FileService _fileService = FileService();

  // date string (yyyy-MM-dd) → list of DiaryEntry
  Map<String, List<DiaryEntry>> _eventMap = {};
  bool _isLoading = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await _fileService.getDiaryEntries();
    final map = <String, List<DiaryEntry>>{};
    for (final e in entries) {
      map.putIfAbsent(e.date, () => []).add(e);
    }
    if (mounted) {
      setState(() {
        _eventMap = map;
        _isLoading = false;
      });
    }
  }

  List<DiaryEntry> _eventsFor(DateTime day) {
    final key =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return _eventMap[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    final entries = _eventsFor(selectedDay);
    if (entries.isEmpty) return;

    if (entries.length == 1) {
      _openDetail(entries.first);
    } else {
      _showPickerSheet(entries);
    }
  }

  Future<void> _openDetail(DiaryEntry entry) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          path: entry.path,
          date: entry.date,
          time: entry.time,
        ),
      ),
    );
    _loadEntries();
  }

  void _showPickerSheet(List<DiaryEntry> entries) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              '${entries.first.date} — ${entries.length}개의 일기',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const Divider(height: 0),
          ListView.builder(
            shrinkWrap: true,
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.amber.shade100,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ),
                title: Text(
                  e.title.isNotEmpty ? e.title : '(제목 없음)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(e.time.isNotEmpty ? e.time : ''),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  _openDetail(e);
                },
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('일기 달력'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.amber))
          : Column(
              children: [
                TableCalendar<DiaryEntry>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) =>
                      isSameDay(_selectedDay, day),
                  eventLoader: _eventsFor,
                  onDaySelected: _onDaySelected,
                  onPageChanged: (day) =>
                      setState(() => _focusedDay = day),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Colors.amber.shade300,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle:
                        const TextStyle(color: Colors.black),
                    todayTextStyle: const TextStyle(color: Colors.black),
                    markerDecoration: const BoxDecoration(
                      color: Colors.deepOrange,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 3,
                    outsideDaysVisible: false,
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold),
                    leftChevronIcon: const Icon(Icons.chevron_left,
                        color: Colors.black54),
                    rightChevronIcon: const Icon(Icons.chevron_right,
                        color: Colors.black54),
                    headerPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                    ),
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle: TextStyle(color: Colors.black87),
                    weekendStyle: TextStyle(color: Colors.redAccent),
                  ),
                ),
                const Divider(height: 0),
                Expanded(
                  child: _buildSelectedDayList(),
                ),
              ],
            ),
    );
  }

  Widget _buildSelectedDayList() {
    final entries =
        _selectedDay == null ? [] : _eventsFor(_selectedDay!);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_note, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('이 날의 일기가 없습니다.',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.amber.shade100,
              child: const Icon(Icons.book, color: Colors.amber),
            ),
            title: Text(
              e.title.isNotEmpty ? e.title : '(제목 없음)',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              e.time.isNotEmpty ? '작성 시각: ${e.time}' : e.date,
              style: const TextStyle(fontSize: 12),
            ),
            trailing:
                const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () => _openDetail(e),
          ),
        );
      },
    );
  }
}
