import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import '../models/activity_participant.dart';
import '../services/firestore_activity_service.dart';

class ParticipantsPage extends StatelessWidget {
  final ActivityItem activity;

  const ParticipantsPage({
    super.key,
    required this.activity,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid =
        FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),

      // =========================
      // AppBar
      // =========================
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'ผู้เข้าร่วม',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =========================
      // Body
      // =========================
      body: StreamBuilder<
          List<ActivityParticipant>>(
        stream: FirestoreActivityService
            .getParticipantsStream(
          activity.id,
        ),
        builder: (context, snapshot) {
          // =========================
          // Loading
          // =========================
          if (snapshot.connectionState ==
              ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C4DFF),
              ),
            );
          }

          // =========================
          // Error
          // =========================
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 55,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'ไม่สามารถโหลดรายชื่อผู้เข้าร่วมได้',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign:
                      TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final participants =
              snapshot.data ??
                  <ActivityParticipant>[];

          return ListView(
            padding:
            const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              40,
            ),
            children: [
              // =========================
              // Activity Header
              // =========================
              Container(
                padding:
                const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(
                    20,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.04,
                      ),
                      blurRadius: 10,
                      offset:
                      const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration:
                      const BoxDecoration(
                        color:
                        Color(0xFFEDE8FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .people_alt_rounded,
                        color:
                        Color(0xFF6C4DFF),
                        size: 28,
                      ),
                    ),

                    const SizedBox(
                      width: 14,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            activity.title,
                            maxLines: 1,
                            overflow:
                            TextOverflow
                                .ellipsis,
                            style:
                            const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            '${participants.length}/${activity.total} คน',
                            style:
                            const TextStyle(
                              color: Color(
                                0xFF6C4DFF,
                              ),
                              fontWeight:
                              FontWeight
                                  .bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // =========================
              // Title
              // =========================
              Row(
                children: [
                  const Text(
                    'สมาชิก',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${participants.length} คน',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // =========================
              // Empty
              // =========================
              if (participants.isEmpty)
                Container(
                  padding:
                  const EdgeInsets.all(
                    30,
                  ),
                  decoration:
                  BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons
                            .person_search_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'ยังไม่มีผู้เข้าร่วม',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...participants.map(
                      (participant) {
                    final isMe =
                        participant.uid ==
                            currentUid;

                    return _participantCard(
                      participant:
                      participant,
                      isMe: isMe,
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  // =========================
  // Participant Card
  // =========================
  Widget _participantCard({
    required ActivityParticipant participant,
    required bool isMe,
  }) {
    return Container(
      margin:
      const EdgeInsets.only(bottom: 10),
      padding:
      const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
        BorderRadius.circular(18),
        border: isMe
            ? Border.all(
          color:
          const Color(0xFF6C4DFF)
              .withValues(
            alpha: 0.35,
          ),
        )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.025,
            ),
            blurRadius: 8,
            offset:
            const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration:
            const BoxDecoration(
              color: Color(0xFFEDE8FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFF6C4DFF),
              size: 27,
            ),
          ),

          const SizedBox(width: 13),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        participant.name,
                        maxLines: 1,
                        overflow:
                        TextOverflow
                            .ellipsis,
                        style:
                        const TextStyle(
                          fontSize: 15,
                          fontWeight:
                          FontWeight
                              .bold,
                        ),
                      ),
                    ),

                    if (isMe) ...[
                      const SizedBox(
                        width: 7,
                      ),
                      Container(
                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration:
                        BoxDecoration(
                          color: const Color(
                            0xFFEDE8FF,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            8,
                          ),
                        ),
                        child: const Text(
                          'คุณ',
                          style:
                          TextStyle(
                            color: Color(
                              0xFF6C4DFF,
                            ),
                            fontSize: 10,
                            fontWeight:
                            FontWeight
                                .bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                if (participant.isOwner) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'ผู้จัดกิจกรรม',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Owner Badge
          if (participant.isOwner)
            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration:
              BoxDecoration(
                color:
                Colors.amber.withValues(
                  alpha: 0.13,
                ),
                borderRadius:
                BorderRadius.circular(
                  10,
                ),
              ),
              child: const Row(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 15,
                    color: Colors.amber,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'เจ้าของ',
                    style: TextStyle(
                      fontSize: 10,
                      color:
                      Colors.orange,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}