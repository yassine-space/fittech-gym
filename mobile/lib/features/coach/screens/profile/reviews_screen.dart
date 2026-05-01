import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/providers/coach_provider.dart';
import 'package:mobile/core/models/review_model.dart';
import 'package:mobile/core/models/membre_model.dart'; // Added to type 'members' properly

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoachProvider>().loadReviews();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CoachProvider>(
      builder: (context, provider, _) {
        final reviews = provider.reviews;
        final avg = provider.averageRating;

        return Scaffold(
          backgroundColor: const Color(0xFFF5EDE8),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1C1C)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'MEMBER REVIEWS',
              style: TextStyle(
                color: Color(0xFF1C1C1C),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          body: provider.reviewsLoading && reviews.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD44820)))
              : RefreshIndicator(
                  color: const Color(0xFFD44820),
                  onRefresh: () => provider.loadReviews(),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Summary card
                      if (reviews.isNotEmpty) ...[
                        _SummaryCard(
                          provider: provider, // Passed the provider here
                          avg: avg,
                          total: reviews.length,
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (reviews.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 80),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.reviews_outlined,
                                  size: 56,
                                  color: const Color(0xFFD44820).withOpacity(0.3),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'No reviews yet',
                                  style: TextStyle(
                                    color: Color(0xFF9A7060),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Reviews appear after members attend your courses.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF9A7060),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...reviews.map((r) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ReviewCard(review: r, members: provider.members),
                            )),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final CoachProvider provider; // Add provider to access reviewCountForStar
  final double avg;
  final int total;
  
  const _SummaryCard({
    required this.provider, 
    required this.avg, 
    required this.total
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1C1C1C),
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: List.generate(5, (i) {
                  final filled = i < avg.round();
                  return Icon(
                    filled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 20,
                    color: const Color(0xFFD44820),
                  );
                }),
              ),
              const SizedBox(height: 4),
              Text(
                '$total review${total == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Color(0xFF9A7060),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Build the Star Distribution Bars (5, 4, 3, 2, 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(5, (i) {
              final star = 5 - i;
              final count = provider.reviewCountForStar(star);
              final percent = total > 0 ? (count / total) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$star',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF9A7060)),
                    ),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD44820)),
                    const SizedBox(width: 8),
                    Container(
                      width: 100, // Fixed width for the progress bar
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5EDE8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: percent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFD44820),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final CoachReview review;
  final List<Membre> members; // Strongly typed the List
  const _ReviewCard({required this.review, required this.members});

  @override
  Widget build(BuildContext context) {
    // Correctly search for the member without casting to dynamic
    final member = members.where((m) => m.id == review.membreId).firstOrNull;
    
    final name = member?.user.fullName ?? 'Member';
    final initials = member?.user.initials ?? 'M';
    final dateStr = DateFormat('d MMM yyyy').format(review.createdAt);

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
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD44820),
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF1C1C1C),
                      ),
                    ),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9A7060),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: const Color(0xFFD44820),
                    )),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF5A4A40),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}