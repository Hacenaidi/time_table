import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_endpoints.dart'; // Import the base URL for API endpoints

class ManageStudentsPage extends StatefulWidget {
  @override
  _ManageStudentsPageState createState() => _ManageStudentsPageState();
}

class _ManageStudentsPageState extends State<ManageStudentsPage> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  // Fetch students from the API
  Future<void> _fetchStudents() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/students'));
    if (response.statusCode == 200) {
      final decodedStudents = jsonDecode(response.body) as List;
      setState(() {
        _students = decodedStudents.map((e) {
          return {
            "id": e['id'],
            "name": (e['first_name'] ?? '') + ' ' + (e['last_name'] ?? ''),
            "first_name": e['first_name'],
            "last_name": e['last_name'],
            "email": e['email'],
            "class": e['class'],
            "phone": e['phone'],
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load students')),
      );
    }
  }

  // Add student functionality
  Future<void> _addStudent() async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController classController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(firstNameController, 'First Name'),
                _buildTextField(lastNameController, 'Last Name'),
                _buildTextField(emailController, 'Email'),
                _buildTextField(classController, 'class'),
                _buildTextField(phoneController, 'phone'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newStudentData = {
                  "student_id":
                      "S${DateTime.now().millisecondsSinceEpoch}", // Unique ID
                  "first_name": firstNameController.text,
                  "last_name": lastNameController.text,
                  "email": emailController.text,
                  "class": classController.text,
                  "phone": phoneController.text,
                  "id": "a${DateTime.now().millisecondsSinceEpoch}",
                };

                final response = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/students'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(newStudentData),
                );

                if (response.statusCode == 201) {
                  Navigator.of(context).pop();
                  _fetchStudents();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add student')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  // Edit student functionality
  Future<void> _editStudent(String studentId) async {
    final student =
        _students.firstWhere((student) => student["id"] == studentId);

    final TextEditingController firstNameController =
        TextEditingController(text: student["first_name"]);
    final TextEditingController lastNameController =
        TextEditingController(text: student["last_name"]);
    final TextEditingController emailController =
        TextEditingController(text: student["email"]);
    final TextEditingController classController =
        TextEditingController(text: student["class"]);
    final TextEditingController phoneController =
        TextEditingController(text: student["phone"]);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Student'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(firstNameController, 'First Name'),
                _buildTextField(lastNameController, 'Last Name'),
                _buildTextField(emailController, 'Email'),
                _buildTextField(classController, 'class'),
                _buildTextField(phoneController, 'phone'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedStudentData = {
                  "student_id": studentId,
                  "first_name": firstNameController.text,
                  "last_name": lastNameController.text,
                  "email": emailController.text,
                  "class": classController.text,
                  "phone": phoneController.text,
                  "id": student["id"], // Keep the same ID
                };

                final response = await http.put(
                  Uri.parse('${ApiEndpoints.baseUrl}/students/$studentId'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(updatedStudentData),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchStudents();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update student')),
                  );
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  // Delete student functionality
  Future<void> _deleteStudent(String studentId) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/students/$studentId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _students.removeWhere((student) => student["id"] == studentId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete student')),
      );
    }
  }

  // Custom method for TextFields
  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Theme.of(context).primaryColor),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Students')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addStudent,
              icon: Icon(Icons.add),
              label: Text('Add Student'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _students.length,
              itemBuilder: (context, index) {
                final student = _students[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    title:
                        Text(student['name'], style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Class: ${student['class']}\nPhone: ${student['phone']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteStudent(student["id"]),
                    ),
                    onTap: () => _editStudent(student["id"]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
