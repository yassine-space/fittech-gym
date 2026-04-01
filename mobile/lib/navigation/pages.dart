import 'package:equatable/equatable.dart';

class Pages extends Equatable {
  const Pages._();
  static const home = '/';
  static const singup = '/singup';
  static const login = '/login';
  @override
  List<Object?> get props => [home, singup, login];
}
