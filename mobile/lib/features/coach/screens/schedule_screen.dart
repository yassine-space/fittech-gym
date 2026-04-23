import 'package:flutter/material.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF5EDE8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Color(0xFF8B4513),
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'PERFORMANCE LAB',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFFD44820),
                      letterSpacing: 1.2,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.notifications_none, color: Color(0xFF1C1C1C), size: 24),
                ],
              ),
              SizedBox(height: 24),

              // Title
              Text(
                'MASTER SCHEDULE',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Optimize your training cycles and athlete availability across the lab.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A7060),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),

              // Calendar Section
              _CalendarSection(),
              SizedBox(height: 24),

              // Today's Schedule & Availability Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TodaySchedule()),
                  SizedBox(width: 16),
                  Expanded(child: _AvailabilityCard()),
                ],
              ),
              SizedBox(height: 24),

              // Daily Flow Section
              _DailyFlow(),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarSection extends StatelessWidget {
  const _CalendarSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OCTOBER 2024',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.chevron_left, size: 20, color: Color(0xFFD44820)),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 20, color: Color(0xFFD44820)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'THE CALENDAR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A7060),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          // Week days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeekDay('MON'),
              _WeekDay('TUE'),
              _WeekDay('WED'),
              _WeekDay('THU'),
              _WeekDay('FRI'),
              _WeekDay('SAT'),
              _WeekDay('SUN'),
            ],
          ),
          const SizedBox(height: 8),
          // Dates row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DateNumber('28'),
              _DateNumber('29'),
              _DateNumber('30'),
              _DateNumber('1', isToday: true),
              _DateNumber('2'),
              _DateNumber('3'),
              _DateNumber('4'),
            ],
          ),
          const SizedBox(height: 8),
          // Dates row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DateNumber('5'),
              _DateNumber('6'),
              _DateNumber('7', isBooked: true),
              _DateNumber('8'),
              _DateNumber('9'),
              _DateNumber('10'),
              _DateNumber('11'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD44820),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'TODAY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD44820).withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'BOOKED SESSION',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _WeekDay(String day) {
    return Text(
      day,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Color(0xFF9A7060),
      ),
    );
  }

  Widget _DateNumber(String date, {bool isToday = false, bool isBooked = false}) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isToday ? const Color(0xFFD44820) : (isBooked ? const Color(0xFFD44820).withOpacity(0.15) : Colors.transparent),
      ),
      child: Center(
        child: Text(
          date,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isToday ? Colors.white : const Color(0xFF1C1C1C),
          ),
        ),
      ),
    );
  }
}

class _TodaySchedule extends StatelessWidget {
  const _TodaySchedule();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S HEAT",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD44820),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '4 SESSIONS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SessionItem('08:00 AM', 'Elena Rodriguez', 'HYPERTROPHY BLOCK'),
          const Divider(height: 16, color: Color(0xFFF0E0D8)),
          _SessionItem('10:30 AM', 'Marcus Chen', 'POWER & SPEED'),
          const Divider(height: 16, color: Color(0xFFF0E0D8)),
          _SessionItem('01:00 PM', 'Sarah J. Miller', 'ACTIVE NOW', isActive: true),
        ],
      ),
    );
  }

  Widget _SessionItem(String time, String name, String program, {bool isActive = false}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF3DB87A) : const Color(0xFFD44820),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFD44820),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              Text(
                program,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9A7060),
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3DB87A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'ACTIVE NOW',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: Color(0xFF3DB87A),
              ),
            ),
          ),
      ],
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABILITY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _AvailabilityItem('Evening Slots', '4-8 PM'),
          const SizedBox(height: 12),
          _AvailabilityItem('Weekend Recovery', 'SAT-SUN'),
        ],
      ),
    );
  }

  Widget _AvailabilityItem(String title, String time) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFFD44820),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                time,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyFlow extends StatelessWidget {
  const _DailyFlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DAILY FLOW',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1C),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          _FlowItem('06:00 AM', 'NO BOOKINGS – LAB PRIVATE'),
          const SizedBox(height: 12),
          _FlowItem('07:00 AM', 'Strength Testing', subtitle: 'JAMESON HALL (ELITE TIER)', duration: '45 min'),
          const SizedBox(height: 12),
          _FlowItem('08:00 AM', 'AVAILABLE FOR BOOKING', subtitle: 'BLOCK SLOT', isAvailable: true),
        ],
      ),
    );
  }

  Widget _FlowItem(String time, String title, {String? subtitle, String? duration, bool isAvailable = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            time,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isAvailable ? const Color(0xFFD44820) : const Color(0xFF9A7060),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? const Color(0xFFD44820) : const Color(0xFF1C1C1C),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9A7060),
                  ),
                ),
              ],
              if (duration != null) ...[
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF3DB87A),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}