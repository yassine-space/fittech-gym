import 'package:flutter/material.dart';

class ProgramsScreen extends StatelessWidget {
  const ProgramsScreen({super.key});

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
                'TRAINING PROGRAMS',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Design, monitor, and scale your athlete blueprints. Your current portfolio is generating €12.4k this month.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9A7060),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(child: _StatCard('ACTIVE PROGRAMS', '08', Color(0xFFD44820))),
                  SizedBox(width: 12),
                  Expanded(child: _StatCard('TOTAL ENROLLEES', '412', Color(0xFF1C1C1C))),
                  SizedBox(width: 12),
                  Expanded(child: _StatCard('RETENTION RATE', '94.2%', Color(0xFF3DB87A))),
                ],
              ),
              SizedBox(height: 28),

              // LIVE Section
              Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3DB87A),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 12),
              _LiveProgramCard(
                title: '12-Week Hypertrophy',
                enrollees: '184',
                revenue: '€5,420',
                change: '+182',
              ),
              SizedBox(height: 24),

              // DRAFT Section
              Text(
                'DRAFT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF9A7060),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 12),
              _DraftProgramCard(
                title: 'Fat Loss Foundation',
                potentialRevenue: '€2,900',
                lastEdited: 'Last edited 2h ago',
              ),
              SizedBox(height: 24),

              // CLIENT'S PROGRAMS Section
              Text(
                "CLIENT'S PROGRAMS",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                  letterSpacing: 0.8,
                ),
              ),
              SizedBox(height: 12),
              _ClientProgramCard(
                title: 'Elite Performance V2',
                previousEnrollees: '228',
                totalYield: '€6,840',
                retiredDate: 'Retired Dec 2023',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Color(0xFF9A7060),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: color,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveProgramCard extends StatelessWidget {
  final String title;
  final String enrollees;
  final String revenue;
  final String change;

  const _LiveProgramCard({
    required this.title,
    required this.enrollees,
    required this.revenue,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3DB87A), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DB87A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3DB87A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENROLLEES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      enrollees,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'REVENUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      revenue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3DB87A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3DB87A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0E0D8), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'MANAGE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD44820),
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFD44820)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftProgramCard extends StatelessWidget {
  final String title;
  final String potentialRevenue;
  final String lastEdited;

  const _DraftProgramCard({
    required this.title,
    required this.potentialRevenue,
    required this.lastEdited,
  });

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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C1C1C),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF9A7060).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'DRAFT',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A7060),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ENROLLEES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '--',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'POTENTIAL REVENUE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      potentialRevenue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            lastEdited,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9A7060),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0E0D8), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CONTINUE EDITING',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD44820),
                  ),
                ),
                const Icon(Icons.edit, size: 16, color: Color(0xFFD44820)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientProgramCard extends StatelessWidget {
  final String title;
  final String previousEnrollees;
  final String totalYield;
  final String retiredDate;

  const _ClientProgramCard({
    required this.title,
    required this.previousEnrollees,
    required this.totalYield,
    required this.retiredDate,
  });

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
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1C1C1C),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PREVIOUS ENROLLEES',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previousEnrollees,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL YIELD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      totalYield,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            retiredDate,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9A7060),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF0E0D8), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLONE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFD44820),
                  ),
                ),
                const Icon(Icons.content_copy, size: 16, color: Color(0xFFD44820)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}