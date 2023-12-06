import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:employee_database_app/employee_model.dart';

class EmployeeList extends StatefulWidget {
  @override
  _EmployeeListState createState() => _EmployeeListState();
}

class _EmployeeListState extends State<EmployeeList>
    with TickerProviderStateMixin {
  late Database _database;
  late TabController _tabController;
  List<Employee> _employees = [];

  @override
  void initState() {
    super.initState();
    _initDatabase().then((_) {
      _loadEmployees();
    });
  }

  Future<void> _editEmployee(BuildContext context, Employee employee) async {
    TextEditingController nameController =
    TextEditingController(text: employee.name);
    TextEditingController lastNameController =
    TextEditingController(text: employee.lastName);
    TextEditingController emailController =
    TextEditingController(text: employee.email);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Employee'),
          content: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Save the edited data
                employee.name = nameController.text;
                employee.lastName = lastNameController.text;
                employee.email = emailController.text;
                await _updateEmployee(employee);
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );

    _loadEmployees(); // Refresh the employee list after editing
  }

  Future<void> _updateEmployee(Employee employee) async {
    await _database.update(
      'employees',
      employee.toMap(),
      where: 'id = ?',
      whereArgs: [employee.id],
    );
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'employee_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE employees(id INTEGER PRIMARY KEY, name TEXT, lastName TEXT, email TEXT, avatar TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> _fetchData() async {
    final response =
    await http.get(Uri.parse('https://reqres.in/api/users?page=1'));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final List<dynamic> users = jsonData['data'];

      for (var user in users) {
        final employee = Employee(
          id: user['id'],
          name: user['first_name'],
          email: user['email'],
          lastName: user['last_name'],
          avatar: user['avatar'],
        );
        await _insertEmployee(employee);
      }
    }
  }

  Future<void> _insertEmployee(Employee employee) async {
    await _database.insert(
      'employees',
      employee.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _loadEmployees() async {
    final List<Map<String, dynamic>> maps = await _database.query('employees');
    setState(() {
      _employees = List.generate(maps.length, (i) {
        return Employee.fromMap(maps[i]);
      });
      _tabController = TabController(vsync: this, length: _employees.length);
    });
  }

  Future<void> _deleteEmployee(int id) async {
    await _database.delete('employees', where: 'id = ?', whereArgs: [id]);
    _loadEmployees();
  }

  Future<void> _refreshData() async {
    await _database.delete('employees');
    await _fetchData();
    _loadEmployees();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _employees.isEmpty
        ? Scaffold(
      appBar: AppBar(
        title: Text('Vritti List'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _refreshData();
              setState(() {});
            },
          ),
        ],
      ),
      body: Center(
          child: Text(
            'No data available. Tap the refresh button to fetch data.', style: TextStyle(fontSize: 10),)),
    )
        : Scaffold(
      appBar: AppBar(
        title: Text('Vritti List'),
        backgroundColor: Colors.blue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              await _refreshData();
              setState(() {});
            },
          ),
        ],
        bottom: TabBar(
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white,
          indicator: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10)),
              color: Colors.white),
          controller: _tabController,
          tabs: _employees.map((e) => Tab(text: e.name)).toList(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _employees.map((e) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Card(
                    elevation: 5,
                    margin: EdgeInsets.all(10),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _editEmployee(context, e);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: Text('Edit'),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  _deleteEmployee(e.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: Text('Delete'),
                              ),
                              SizedBox(
                                width: 20,
                              ),
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: NetworkImage(e.avatar),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 20,
                          ),
                          Text(
                            'First Name: ${e.name}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Last Name: ${e.lastName}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Email: ${e.email}',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),

                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
