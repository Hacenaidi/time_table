import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../api_endpoints.dart'; // Import the base URL for API endpoints

class ManageRoomsPage extends StatefulWidget {
  @override
  _ManageRoomsPageState createState() => _ManageRoomsPageState();
}

class _ManageRoomsPageState extends State<ManageRoomsPage> {
  List<Map<String, dynamic>> _rooms = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  // Fetch rooms from the API
  Future<void> _fetchRooms() async {
    final response = await http.get(Uri.parse('${ApiEndpoints.baseUrl}/rooms'));
    if (response.statusCode == 200) {
      final decodedRooms = jsonDecode(response.body) as List;
      setState(() {
        _rooms = decodedRooms.map((e) {
          return {
            "id": e['id'],
            "room_name": e['room_name'],
            "capacity": e['capacity'],
            "building": e['building'],
            "floor": e['floor'],
          };
        }).toList();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load rooms')),
      );
    }
  }

  // Add room functionality
  Future<void> _addRoom() async {
    final TextEditingController roomNameController = TextEditingController();
    final TextEditingController capacityController = TextEditingController();
    final TextEditingController buildingController = TextEditingController();
    final TextEditingController floorController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Room'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(roomNameController, 'Room Name'),
                _buildTextField(capacityController, 'Capacity'),
                _buildTextField(buildingController, 'Building'),
                _buildTextField(floorController, 'Floor'),
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
                final newRoomData = {
                  "room_name": roomNameController.text,
                  "capacity": int.parse(capacityController.text),
                  "building": buildingController.text,
                  "floor": int.parse(floorController.text),
                  "id": "r${DateTime.now().millisecondsSinceEpoch}",
                };

                final response = await http.post(
                  Uri.parse('${ApiEndpoints.baseUrl}/rooms'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(newRoomData),
                );

                if (response.statusCode == 201) {
                  Navigator.of(context).pop();
                  _fetchRooms();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add room')),
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

  // Edit room functionality
  Future<void> _editRoom(String roomId) async {
    final room = _rooms.firstWhere((room) => room["id"] == roomId);

    final TextEditingController roomNameController =
        TextEditingController(text: room["room_name"]);
    final TextEditingController capacityController =
        TextEditingController(text: room["capacity"].toString());
    final TextEditingController buildingController =
        TextEditingController(text: room["building"]);
    final TextEditingController floorController =
        TextEditingController(text: room["floor"].toString());

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Room'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildTextField(roomNameController, 'Room Name'),
                _buildTextField(capacityController, 'Capacity'),
                _buildTextField(buildingController, 'Building'),
                _buildTextField(floorController, 'Floor'),
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
                final updatedRoomData = {
                  "room_name": roomNameController.text,
                  "capacity": int.parse(capacityController.text),
                  "building": buildingController.text,
                  "floor": int.parse(floorController.text),
                  "id": room["id"], // Keep the same ID
                };

                final response = await http.put(
                  Uri.parse('${ApiEndpoints.baseUrl}/rooms/$roomId'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(updatedRoomData),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                  _fetchRooms();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update room')),
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

  // Delete room functionality
  Future<void> _deleteRoom(String roomId) async {
    final response = await http.delete(
      Uri.parse('${ApiEndpoints.baseUrl}/rooms/$roomId'),
    );
    if (response.statusCode == 200) {
      setState(() {
        _rooms.removeWhere((room) => room["id"] == roomId);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete room')),
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
      appBar: AppBar(title: const Text('Manage Rooms')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: _addRoom,
              icon: Icon(Icons.add),
              label: Text('Add Room'),
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
              itemCount: _rooms.length,
              itemBuilder: (context, index) {
                final room = _rooms[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  child: ListTile(
                    title:
                        Text(room['room_name'], style: TextStyle(fontSize: 18)),
                    subtitle: Text(
                      'Capacity: ${room['capacity']}\nBuilding: ${room['building']}\nFloor: ${room['floor']}',
                      style: TextStyle(fontSize: 14),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRoom(room["id"]),
                    ),
                    onTap: () => _editRoom(room["id"]),
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
