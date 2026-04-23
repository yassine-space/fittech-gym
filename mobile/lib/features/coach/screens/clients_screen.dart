import 'package:flutter/material.dart';

class ClientsScreen extends StatelessWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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

              // OVERVIEW Title
              Text(
                'OVERVIEW',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 20),

              // Stats Row
              Row(
                children: [
                  Expanded(child: _TotalClientsCard()),
                  SizedBox(width: 12),
                  Expanded(child: _ActiveProgramsCard()),
                ],
              ),
              SizedBox(height: 12),

              // Revenue Card Full Width
              _RevenueCard(),
              SizedBox(height: 24),

              // CLIENT ACTIVITY Section
              Row(
                children: [
                  Text(
                    'CLIENT\nACTIVITY',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1C),
                      height: 1.1,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'View All\nActivity',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD44820),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Activity Cards
              _ActivityCard(
                initials: 'AJ',
                name: 'Alex Johnson',
                activity: 'Finished LEG DAY (HEAVY INTENSITY)',
                time: '12 mins ago',
                color: Color(0xFF5A3826),
              ),
              SizedBox(height: 8),
              _ActivityCard(
                initials: 'MT',
                name: 'Marcus Thorne',
                activity: 'Completed CORE & STABILITY II',
                time: '45 mins ago',
                color: Color(0xFF7A4A30),
              ),
              SizedBox(height: 8),
              _ActivityCard(
                initials: 'SC',
                name: 'Sarah Chen',
                activity: 'Updated MAX BENCH PRESS (105KG)',
                time: '2 hours ago',
                color: Color(0xFFD4956A),
              ),
              SizedBox(height: 24),

              // REQUESTS Section
              Row(
                children: [
                  Text(
                    'REQUESTS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1C1C1C),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                    color: Color(0xFFD44820),
                    borderRadius: BorderRadius.circular(12),
                      ),
                    child: Text(
                      '3 NEW',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),

              // Request Cards
              _RequestCard(
                initials: 'DB',
                name: 'David Brooks',
                request: 'Requesting: Premium Online Coaching',
                time: 'SENT 1H AGO',
              ),
              SizedBox(height: 12),
              _RequestCard(
                initials: 'LM',
                name: 'Lena Meyer',
                request: 'Requesting: Transformation 12Wk',
                time: 'SENT 4H AGO',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        backgroundColor: Color(0xFFD44820),
        child: Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
    );
  }
}

// Total Clients Card
class _TotalClientsCard extends StatelessWidget {
  const _TotalClientsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFDDD5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL CLIENTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A7060),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '42',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1C1C1C),
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.trending_up, color: Color(0xFF3DB87A), size: 14),
              SizedBox(width: 4),
              Text(
                '+12% vs last month',
                style: TextStyle(
                  color: Color(0xFF3DB87A),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Active Programs Card
class _ActiveProgramsCard extends StatelessWidget {
  const _ActiveProgramsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFD44820),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTIVE PROGRAMS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '18',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.bolt, color: Colors.white, size: 14),
              SizedBox(width: 4),
              Text(
                '5 new this week',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Revenue Card
class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MONTHLY REVENUE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white54,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$8,450',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: const [
              Icon(Icons.verified_rounded, color: Color(0xFFD44820), size: 14),
              SizedBox(width: 4),
              Text(
                'Goal: \$10k',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Activity Card
class _ActivityCard extends StatelessWidget {
  final String initials;
  final String name;
  final String activity;
  final String time;
  final Color color;

  const _ActivityCard({
    required this.initials,
    required this.name,
    required this.activity,
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFDDD5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFF1C1C1C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A5A4A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9A7060),
                  ),
                ),
              ],
            ),
          ),
          // View Stats Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1B8A8), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'View\nStats',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C1C1C),
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Request Card
class _RequestCard extends StatelessWidget {
  final String initials;
  final String name;
  final String request;
  final String time;

  const _RequestCard({
    required this.initials,
    required this.name,
    required this.request,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEBDAD2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF9A7060).withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Color(0xFFD44820),
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF7A5A4A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Buttons
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD44820),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Approve',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFD1B8A8), width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'Decline',
                      style: TextStyle(
                        color: Color(0xFF1C1C1C),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}