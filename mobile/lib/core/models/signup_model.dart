//Define all fields the user will fill
//Convert them to JSON for Django



class SignupData {
  String prenom = '';
  String nom = '';
  String email = '';
  String password = '';
  String phone = '';
  int role = 0;
  List<String> goals = [];

  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "phone": phone,
    };
  }
}