import 'package:flutter/material.dart';
import 'package:time_table/pages/manage_student_page.dart';
import 'package:time_table/pages/manage_subject_page.dart';
import '../pages/manage_teachers_page.dart';
import '../pages/manage_classes_page.dart';
import '../pages/manage_rooms_page.dart';

class AdminNavbar extends StatelessWidget {
  const AdminNavbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin Options',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
          ListTile(
            title: const Text('Manage Teachers'),
            leading: const Icon(Icons.person),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageTeachersPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Classes'),
            leading: const Icon(Icons.class_),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageClassesPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Rooms'),
            leading: const Icon(Icons.meeting_room),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageRoomsPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Studnets'),
            leading: const Icon(Icons.school),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageStudentsPage()),
              );
            },
          ),
          ListTile(
            title: const Text('Manage Subjects'),
            leading: const Icon(Icons.book),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageSubjectsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
