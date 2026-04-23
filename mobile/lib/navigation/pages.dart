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
  // pages.dart - Add these if needed
static const coachClients = '/coach/clients';
static const coachPrograms = '/coach/programs';
static const coachSchedule = '/coach/schedule';
static const coachMessages = '/coach/messages';
static const coachProfile = '/coach/profile';

  @override
  List<Object?> get props => [home, singup, login];
}
