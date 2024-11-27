import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/api_service.dart';

class TimetableWidget extends StatefulWidget {
  const TimetableWidget({Key? key}) : super(key: key);

  @override
  State<TimetableWidget> createState() => _TimetableWidgetState();
}

class _TimetableWidgetState extends State<TimetableWidget> {
  final List<String> _timeSlots = [
    '08:30-10:00',
    '10:15-11:45',
    '12:00-13:00',
    '13:00-14:30',
    '14:45-16:15',
    '16:30-18:00',
  ];

  final List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, List<Session>> _sessionsByDayAndTime = {};
  Map<String, String> _subjectNames = {}; // Subject ID to name mapping
  Map<String, String> _teacherNames = {}; // Teacher ID to name mapping

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    try {
      List<Session> sessions = await ApiService.fetchSessions();

      // Récupérer les informations des sujets et des enseignants
      List<String> subjectIds =
          sessions.map((session) => session.subjectId).toSet().toList();
      List<String> teacherIds =
          sessions.map((session) => session.teacherId).toSet().toList();

      // Fetch subject names and teacher names
      Map<String, String> subjectNames =
          await ApiService.fetchSubjectsByIds(subjectIds);
      Map<String, String> teacherNames =
          await ApiService.fetchTeachersByIds(teacherIds);

      // Organiser les sessions par jour et par plage horaire
      Map<String, List<Session>> groupedSessions = {
        for (var day in _days) day: []
      };

      for (var session in sessions) {
        if (groupedSessions.containsKey(session.sessionDate)) {
          groupedSessions[session.sessionDate]!.add(session);
        }
      }

      setState(() {
        _sessionsByDayAndTime = groupedSessions;
        _subjectNames = subjectNames;
        _teacherNames = teacherNames;
      });
    } catch (e) {
      debugPrint('Failed to fetch sessions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: Colors.grey),
      children: [
        TableRow(
          children: [
            const TableCell(
              child: Center(child: Text('Time / Day')),
            ),
            ..._timeSlots.map((slot) => Center(child: Text(slot))).toList(),
          ],
        ),
        ..._days.map((day) {
          return TableRow(
            children: [
              Center(child: Text(day)),
              ..._timeSlots.map((timeSlot) {
                // Filtrer les sessions par jour et par plage horaire
                List<Session> sessions = _sessionsByDayAndTime[day]!
                    .where((session) => _isSessionInTimeSlot(session, timeSlot))
                    .toList();

                return Center(
                  child: sessions.isNotEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Affiche le numéro de la salle en haut
                            Text(
                              "Room: ${sessions.first.roomId}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Affiche le nom du sujet au centre (récupéré par subjectId)
                            Text(
                              _subjectNames[sessions.first.subjectId] ??
                                  sessions.first.subjectId,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Affiche le nom du professeur en bas (récupéré par teacherId)
                            Text(
                              "Teacher: ${_teacherNames[sessions.first.teacherId] ?? sessions.first.teacherId}",
                              style: const TextStyle(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : const Text('-'),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ],
    );
  }

  bool _isSessionInTimeSlot(Session session, String timeSlot) {
    List<String> times = timeSlot.split('-');
    String start = times[0];
    String end = times[1];

    return session.startTime == start && session.endTime == end;
  }
}
