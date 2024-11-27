import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_endpoints.dart'; // Import the base URL for API endpoints

class ManageSubjectsPage extends StatefulWidget {
  @override
  _ManageSubjectsPageState createState() => _ManageSubjectsPageState();
}

class _ManageSubjectsPageState extends State<ManageSubjectsPage> {
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  // Fetch subjects from the API
  Future<void> _fetchSubjects() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/subjects'));
    if (response.statusCode == 200) {
      final decodedSubjects = jsonDecode(response.body) as List;
      setState(() {
        _subjects = decodedSubjects.map((e) {
          return {
            "id": e['id'],
            "subject_name": e['subject_name'],
            "subject_code": e['subject_code'],
            "department": e['department'],
            "description": e['description'],
            "subject_id": e['subject_id'], // hidden field
          };
        }).toList();
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load subjects')),
      );
    }
  }

  // Add subject functionality
  Future<void> _addSubject() async {
    final TextEditingController subjectNameController = TextEditingController();
    final TextEditingController subjectCodeController = TextEditingController();
    final TextEditingController departmentController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subject'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(subjectNameController, 'Subject Name'),
                _buildTextField(subjectCodeController, 'Subject Code'),
                _buildTextField(departmentController, 'Department'),
                _buildTextField(descriptionController, 'Description'),
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
                final newSubjectData = {
                  "subject_id":
                      "S${DateTime.now().millisecondsSinceEpoch}", // Unique ID
                  "subject_name": subjectNameController.text,
                  "subject_code": subjectCodeController.text,
                  "department": departmentController.text,
                  "description": descriptionController.text,
                  "id": "a${DateTime.now().millisecondsSinceEpoch}",
                };

                final response = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/subjects'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(newSubjectData),
                );

                if (response.statusCode == 201) {
                  Navigator.of(context).pop();
                  _fetchSubjects();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add subject')),
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

  // Edit subject functionality
  Future<void> _editSubject(String subjectId) async {
    final subject =
        _subjects.firstWhere((subject) => subject["id"] == subjectId);

    final TextEditingController subjectNameController =
        TextEditingController(text: subject["subject_name"]);
    final TextEditingController subjectCodeController =
        TextEditingController(text: subject["subject_code"]);
    final TextEditingController departmentController =
        TextEditingController(text: subject["department"]);
    final TextEditingController descriptionController =
        TextEditingController(text: subject["description"]);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Subject'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(subjectNameController, 'Subject Name'),
                _buildTextField(subjectCodeController, 'Subject Code'),
                _buildTextField(departmentController, 'Department'),
                _buildTextField(descriptionController, 'Description'),
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
                final updatedSubjectData = {
                  "subject_id": subjectId,
                  "subject_name": subjectNameController.text,
                  "subject_code": subjectCodeController.text,
                  "department": departmentController.text,
                  "description": descriptionController.text,
                  "id": subject["id"], // Keep the same ID
                };

                print(updatedSubjectData);
                final response = await http.put(
                  Uri.parse('${ApiEndpoints.baseUrl}/subjects/$subjectId'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(updatedSubjectData),
                );

                print(response.statusCode);
                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchSubjects();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update subject')),
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

  // Delete subject functionality
  Future<void> _deleteSubject(String subjectId) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/subjects/$subjectId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _subjects.removeWhere((subject) => subject["subject_id"] == subjectId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete subject')),
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
      appBar: AppBar(title: const Text('Manage Subjects')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addSubject,
              icon: Icon(Icons.add),
              label: Text('Add Subject'),
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
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    title: Text(subject['subject_name'],
                        style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Code: ${subject['subject_code']}\nDepartment: ${subject['department']}\nDescription: ${subject['description']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteSubject(subject["id"]),
                    ),
                    onTap: () => _editSubject(subject["id"]),
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
