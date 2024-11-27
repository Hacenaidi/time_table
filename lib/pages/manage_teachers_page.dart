import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_endpoints.dart'; // Import the base URL for API endpoints

class ManageTeachersPage extends StatefulWidget {
  @override
  _ManageTeachersPageState createState() => _ManageTeachersPageState();
}

class _ManageTeachersPageState extends State<ManageTeachersPage> {
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  // Fetch teachers from the API
  Future<void> _fetchTeachers() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/teachers'));
    if (response.statusCode == 200) {
      final decodedTeachers = jsonDecode(response.body) as List;
      setState(() {
        _teachers = decodedTeachers.map((e) {
          return {
            "id": e['id'],
            "name": (e['first_name'] ?? '') + ' ' + (e['last_name'] ?? ''),
            "first_name": e['first_name'],
            "last_name": e['last_name'],
            "email": e['email'],
            "department": e['department'],
            "phone": e['phone'],
          };
        }).toList();
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load teachers')),
      );
    }
  }

  // Add teacher functionality
  Future<void> _addTeacher() async {
    final TextEditingController firstNameController = TextEditingController();
    final TextEditingController lastNameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController departmentController = TextEditingController();
    final TextEditingController phoneController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Teacher'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(firstNameController, 'First Name'),
                _buildTextField(lastNameController, 'Last Name'),
                _buildTextField(emailController, 'Email'),
                _buildTextField(departmentController, 'Department'),
                _buildTextField(phoneController, 'Phone'),
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
                final newTeacherData = {
                  "teacher_id":
                      "T${DateTime.now().millisecondsSinceEpoch}", // Unique ID
                  "first_name": firstNameController.text,
                  "last_name": lastNameController.text,
                  "email": emailController.text,
                  "department": departmentController.text,
                  "phone": phoneController.text,
                  "id": "a${DateTime.now().millisecondsSinceEpoch}",
                };

                final response = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/teachers'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(newTeacherData),
                );

                if (response.statusCode == 201) {
                  Navigator.of(context).pop();
                  _fetchTeachers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add teacher')),
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

  // Edit teacher functionality
  Future<void> _editTeacher(String teacherId) async {
    final teacher =
        _teachers.firstWhere((teacher) => teacher["id"] == teacherId);

    final TextEditingController firstNameController =
        TextEditingController(text: teacher["first_name"]);
    final TextEditingController lastNameController =
        TextEditingController(text: teacher["last_name"]);
    final TextEditingController emailController =
        TextEditingController(text: teacher["email"]);
    final TextEditingController departmentController =
        TextEditingController(text: teacher["department"]);
    final TextEditingController phoneController =
        TextEditingController(text: teacher["phone"]);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Teacher'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(firstNameController, 'First Name'),
                _buildTextField(lastNameController, 'Last Name'),
                _buildTextField(emailController, 'Email'),
                _buildTextField(departmentController, 'Department'),
                _buildTextField(phoneController, 'Phone'),
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
                final updatedTeacherData = {
                  "teacher_id": teacherId,
                  "first_name": firstNameController.text,
                  "last_name": lastNameController.text,
                  "email": emailController.text,
                  "department": departmentController.text,
                  "phone": phoneController.text,
                  "id": teacher["id"], // Keep the same ID
                };

                final response = await http.put(
                  Uri.parse('${ApiEndpoints.baseUrl}/teachers/$teacherId'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(updatedTeacherData),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchTeachers();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update teacher')),
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

  // Delete teacher functionality
  Future<void> _deleteTeacher(String teacherId) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/teachers/$teacherId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _teachers.removeWhere((teacher) => teacher["id"] == teacherId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete teacher')),
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
      appBar: AppBar(title: const Text('Manage Teachers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addTeacher,
              icon: Icon(Icons.add),
              label: Text('Add Teacher'),
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
              itemCount: _teachers.length,
              itemBuilder: (context, index) {
                final teacher = _teachers[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    title:
                        Text(teacher['name'], style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Department: ${teacher['department']}\nPhone: ${teacher['phone']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTeacher(teacher["id"]),
                    ),
                    onTap: () => _editTeacher(teacher["id"]),
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
