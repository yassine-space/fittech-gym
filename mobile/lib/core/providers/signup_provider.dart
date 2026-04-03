//This file stores data while user moves between singup pages


import 'package:flutter/material.dart';
import '../models/signup_model.dart';


class SignupProvider extends ChangeNotifier {
  SignupData data = SignupData();
  void updateGoals(List<String> value) { data.goals = value; notifyListeners(); }
  void updatePrenom(String value)   { data.prenom = value;   notifyListeners(); }
  void updateNom(String value)      { data.nom = value;      notifyListeners(); }
  void updateEmail(String value)    { data.email = value;    notifyListeners(); }
  void updatePassword(String value) { data.password = value; notifyListeners(); }
  void updatePhone(String value)    { data.phone = value;    notifyListeners(); }
  void updateRole(int value)        { data.role = value;     notifyListeners(); }
}