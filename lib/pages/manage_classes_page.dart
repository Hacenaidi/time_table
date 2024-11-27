import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_endpoints.dart';

class ManageClassesPage extends StatefulWidget {
  @override
  _ManageClassesPageState createState() => _ManageClassesPageState();
}

class _ManageClassesPageState extends State<ManageClassesPage> {
  List<Map<String, dynamic>> _classes = [];
  List<Map<String, dynamic>> _students = [];
  List<Map<String, dynamic>> _subjects = [];

  @override
  void initState() {
    super.initState();
    _fetchClasses();
    _fetchStudents();
    _fetchSubjects();
  }

  // Récupérer les classes
  Future<void> _fetchClasses() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/classes'));
    if (response.statusCode == 200) {
      final decodedClasses = jsonDecode(response.body) as List;
      setState(() {
        _classes = decodedClasses.map((e) {
          return {
            "id": e['id'],
            "class_id": e['class_id'],
            "subject_id": e['subject_id'],
            "class_name": e['class_name'],
            "students": List<String>.from(e['students'] ?? []),
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du chargement des classes')),
      );
    }
  }

  // Récupérer les étudiants
  Future<void> _fetchStudents() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/students'));
    if (response.statusCode == 200) {
      final decodedStudents = jsonDecode(response.body) as List;
      setState(() {
        _students = decodedStudents.map((e) {
          return {
            "id": e['id'],
            "name": "${e['first_name']} ${e['last_name']}",
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du chargement des étudiants')),
      );
    }
  }

  // Récupérer les matières
  Future<void> _fetchSubjects() async {
    final response =
        await http.get(Uri.parse('${ApiEndpoints.baseUrl}/subjects'));
    if (response.statusCode == 200) {
      final decodedSubjects = jsonDecode(response.body) as List;
      setState(() {
        _subjects = decodedSubjects.map((e) {
          return {
            "id": e['id'],
            "name": e['subject_name'],
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec du chargement des matières')),
      );
    }
  }

  // Ajouter ou modifier une classe
  Future<void> _addOrEditClass({Map<String, dynamic>? existingClass}) async {
    final TextEditingController classNameController = TextEditingController(
        text: existingClass != null ? existingClass["class_name"] : '');

    String? selectedSubjectId = existingClass?["subject_id"];
    List<String> selectedStudentIds = existingClass != null
        ? List<String>.from(existingClass["students"])
        : [];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              existingClass != null ? 'Modifier Classe' : 'Ajouter Classe'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(classNameController, 'Nom de la classe'),
                DropdownButtonFormField<String>(
                  value: selectedSubjectId,
                  decoration: const InputDecoration(
                    labelText: 'Sélectionnez une matière',
                    border: OutlineInputBorder(),
                  ),
                  items: _subjects.map<DropdownMenuItem<String>>((subject) {
                    return DropdownMenuItem<String>(
                      value: subject['id'],
                      child: Text(subject['name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSubjectId = value;
                    });
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    selectedStudentIds = await _selectStudents(
                      selectedStudentIds: selectedStudentIds,
                    );
                  },
                  child: const Text('Sélectionnez des étudiants'),
                ),
                Text(
                  'Étudiants sélectionnés : ${selectedStudentIds.map((id) {
                    final student = _students.firstWhere(
                        (student) => student['id'] == id,
                        orElse: () => {"name": "Inconnu"});
                    return student['name'];
                  }).join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final classData = {
                  "class_id": existingClass?["class_id"] ??
                      "c${DateTime.now().millisecondsSinceEpoch}",
                  "subject_id": selectedSubjectId,
                  "class_name": classNameController.text,
                  "students": selectedStudentIds,
                  "id": existingClass?["id"] ??
                      "c${DateTime.now().millisecondsSinceEpoch}",
                };

                final response = existingClass != null
                    ? await http.put(
                        Uri.parse(
                            '${ApiEndpoints.baseUrl}/classes/${existingClass["id"]}'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(classData),
                      )
                    : await http.post(
                        Uri.parse('${ApiEndpoints.baseUrl}/classes'),
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode(classData),
                      );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  Navigator.of(context).pop();
                  _fetchClasses();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Échec de l\'enregistrement')),
                  );
                }
              },
              child: Text(existingClass != null ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        );
      },
    );
  }

  // Sélection des étudiants
  Future<List<String>> _selectStudents({
    required List<String> selectedStudentIds,
  }) async {
    List<String> tempSelectedIds = List.from(selectedStudentIds);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Sélectionnez des étudiants'),
              content: SingleChildScrollView(
                child: Column(
                  children: _students.map((student) {
                    final isSelected = tempSelectedIds.contains(student["id"]);
                    return CheckboxListTile(
                      title: Text(student["name"]),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelectedIds.add(student["id"]);
                          } else {
                            tempSelectedIds.remove(student["id"]);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Valider'),
                ),
              ],
            );
          },
        );
      },
    );

    return tempSelectedIds;
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Future<void> _deleteClass(String classId) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/classes/$classId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _classes.removeWhere((cls) => cls["id"] == classId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete class')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer les Classes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => _addOrEditClass(),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une Classe'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _classes.length,
              itemBuilder: (context, index) {
                final cls = _classes[index];
                final subjectName = _subjects.firstWhere(
                  (subject) => subject['id'] == cls['subject_id'],
                  orElse: () => {"name": "Inconnu"},
                )['name'];

                return Card(
                  margin: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  elevation: 4,
                  child: ListTile(
                    title:
                        Text(cls['class_name'], style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Matière : $subjectName\nÉtudiants : ${cls['students'].map((id) {
                        final student = _students.firstWhere(
                            (student) => student['id'] == id,
                            orElse: () => {"name": "Inconnu"});
                        return student['name'];
                      }).join(', ')}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteClass(cls["id"]),
                    ),
                    onTap: () => _addOrEditClass(existingClass: cls),
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
