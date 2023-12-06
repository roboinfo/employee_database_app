class Employee {
  int id;
  String name;
  String lastName;
  String email;
  String avatar;

  Employee(
      {required this.id,
      required this.name,
      required this.lastName,
      required this.email,
      required this.avatar});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'email': email,
      'avatar': avatar
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      lastName: map['lastName'],
      email: map['email'],
      avatar: map['avatar'],
    );
  }
}
