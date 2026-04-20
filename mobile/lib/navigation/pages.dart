import 'package:equatable/equatable.dart';

class Pages extends Equatable {
  const Pages._();
  static const home = '/';
  static const singup = '/singup';
  static const login = '/login';
  static const membreDashboard = '/membrE';
  static const coachDashboard = '/coache';
  static const forgotPassword = '/forgot';
  static const emailSent = '/emailsent';
  @override
  List<Object?> get props => [home, singup, login];
}
