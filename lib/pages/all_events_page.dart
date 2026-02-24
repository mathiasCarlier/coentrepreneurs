import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:coentrepreneurs/models/event.dart';
import 'package:coentrepreneurs/models/user.dart' as user_model;
import 'package:coentrepreneurs/services/event_service.dart';
import 'package:coentrepreneurs/widgets/event_card_avec_inscription.dart';

/// Page calendrier listant toutes les rencontres.
class AllEventsPage extends StatefulWidget {
  final user_model.User currentUser;

  const AllEventsPage({super.key, required this.currentUser});

  @override
  State<AllEventsPage> createState() => _AllEventsPageState();
}

class _AllEventsPageState extends State<AllEventsPage> {
  final EventService _eventService = EventService();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
  }

  /// Normalise une date (sans heure) pour servir de clé.
  DateTime _normalise(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Construit la map jour → liste d'événements.
  Map<DateTime, List<Event>> _buildEventMap(List<Event> events) {
    final map = <DateTime, List<Event>>{};
    for (final e in events) {
      final key = _normalise(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rencontres'),
        backgroundColor:
            isDark ? const Color.fromARGB(255, 17, 17, 17) : Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Event>>(
        stream: _eventService.getAllEventsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('❌ Erreur: ${snapshot.error}'));
          }

          final allEvents = snapshot.data ?? [];
          final eventMap = _buildEventMap(allEvents);

          final selectedKey =
              _selectedDay != null ? _normalise(_selectedDay!) : null;
          final selectedEvents =
              (selectedKey != null ? eventMap[selectedKey] : null) ?? [];

          return Column(
            children: [
              // ── Calendrier ──────────────────────────────────
              TableCalendar<Event>(
                locale: 'fr_FR',
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    isSameDay(_selectedDay, day),
                eventLoader: (day) =>
                    eventMap[_normalise(day)] ?? [],
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Mois',
                },
                startingDayOfWeek: StartingDayOfWeek.monday,
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) {
                  _focusedDay = focused;
                },
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontWeight: FontWeight.bold),
                  leftChevronIcon: const Icon(Icons.chevron_left),
                  rightChevronIcon: const Icon(Icons.chevron_right),
                ),
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Color(0xFF2E6AE6),
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  outsideDaysVisible: false,
                ),
              ),

              const Divider(height: 1),

              // ── Liste des événements du jour sélectionné ────
              Expanded(
                child: selectedEvents.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune rencontre ce jour',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: selectedEvents.length,
                        itemBuilder: (context, index) => EventCard(
                          event: selectedEvents[index],
                          isDark: isDark,
                          currentUser: widget.currentUser,
                          showParticipantCount: false,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
