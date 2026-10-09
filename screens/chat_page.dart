import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';
import 'group_chat_page.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String searchText = '';

  List<ActivityItem> _filterActivities(
      List<ActivityItem> activities,
      ) {
    final joinedActivities = activities
        .where(
          (activity) => activity.isJoined,
    )
        .toList();

    if (searchText.trim().isEmpty) {
      return joinedActivities;
    }

    final search =
    searchText.toLowerCase().trim();

    return joinedActivities.where((activity) {
      return activity.title
          .toLowerCase()
          .contains(search) ||
          activity.category
              .toLowerCase()
              .contains(search) ||
          activity.location
              .toLowerCase()
              .contains(search);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFF8F8FC),
      appBar: AppBar(
        backgroundColor:
        Colors.transparent,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,
        title: const Text(
          'แชททั้งหมด',
          style: TextStyle(
            fontSize: 24,
            fontWeight:
            FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding:
            const EdgeInsets
                .fromLTRB(
              20,
              5,
              20,
              15,
            ),
            child: Container(
              decoration:
              BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(
                  15,
                ),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
                decoration:
                const InputDecoration(
                  hintText:
                  'ค้นหาแชท...',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color:
                    Color(
                      0xFF6C4DFF,
                    ),
                  ),
                  border:
                  InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<
                List<ActivityItem>>(
              stream:
              FirestoreActivityService
                  .getActivitiesStream(),
              builder: (
                  context,
                  snapshot,
                  ) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color:
                      Color(
                        0xFF6C4DFF,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        24,
                      ),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons
                                .error_outline_rounded,
                            size: 55,
                            color:
                            Colors.redAccent,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          const Text(
                            'โหลดห้องแชทไม่สำเร็จ',
                            style:
                            TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            '${snapshot.error}',
                            textAlign:
                            TextAlign.center,
                            style:
                            const TextStyle(
                              color:
                              Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final activities =
                    snapshot.data ??
                        <ActivityItem>[];

                final results =
                _filterActivities(
                  activities,
                );

                if (results.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .chat_bubble_outline_rounded,
                          size: 65,
                          color:
                          Colors.grey,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          'ยังไม่มีห้องแชท',
                          style:
                          TextStyle(
                            fontSize: 18,
                            color:
                            Colors.grey,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 6,
                        ),
                        Text(
                          'เข้าร่วมกิจกรรมก่อน แล้วห้องแชทจะปรากฏที่นี่',
                          textAlign:
                          TextAlign.center,
                          style:
                          TextStyle(
                            fontSize: 13,
                            color:
                            Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    0,
                    20,
                    100,
                  ),
                  itemCount:
                  results.length,
                  itemBuilder: (
                      context,
                      index,
                      ) {
                    final activity =
                    results[index];

                    return ChatListItem(
                      activity:
                      activity,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                GroupChatPage(
                                  activityId:
                                  activity.id,
                                  activityTitle:
                                  activity.title,
                                ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ChatListItem
    extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: Container(
        margin:
        const EdgeInsets.only(
          bottom: 12,
        ),
        padding:
        const EdgeInsets.all(
          14,
        ),
        decoration:
        BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(
            18,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
              const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                color:
                const Color(
                  0xFFEDE8FF,
                ),
                borderRadius:
                BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                _getCategoryIcon(
                  activity.category,
                ),
                size: 29,
                color:
                const Color(
                  0xFF6C4DFF,
                ),
              ),
            ),

            const SizedBox(
              width: 14,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow:
                    TextOverflow.ellipsis,
                    style:
                    const TextStyle(
                      fontSize: 16,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  LatestMessageText(
                    activityId:
                    activity.id,
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .people_outline_rounded,
                        size: 14,
                        color:
                        Colors.grey,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        '${activity.joined} คน',
                        style:
                        const TextStyle(
                          fontSize: 12,
                          color:
                          Colors.grey,
                        ),
                      ),

                      if (activity.isOwner) ...[
                        const SizedBox(
                          width: 8,
                        ),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration:
                          BoxDecoration(
                            color:
                            const Color(
                              0xFFEDE8FF,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              8,
                            ),
                          ),
                          child:
                          const Text(
                            'เจ้าของ',
                            style:
                            TextStyle(
                              color:
                              Color(
                                0xFF6C4DFF,
                              ),
                              fontSize: 10,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(
              width: 10,
            ),

            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                UnreadBadge(
                  activityId:
                  activity.id,
                ),

                const SizedBox(
                  height: 8,
                ),

                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color:
                  Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(
      String category,
      ) {
    final value =
    category.toLowerCase();

    if (value.contains('กีฬา') ||
        value.contains('บาส') ||
        value.contains('ฟุตบอล')) {
      return Icons
          .sports_basketball_rounded;
    }

    if (value.contains('เรียน') ||
        value.contains('ภาษา')) {
      return Icons
          .menu_book_rounded;
    }

    if (value.contains('ท่องเที่ยว') ||
        value.contains('เดินป่า')) {
      return Icons.hiking_rounded;
    }

    if (value.contains('อาหาร')) {
      return Icons
          .restaurant_rounded;
    }

    if (value.contains('เกม')) {
      return Icons
          .sports_esports_rounded;
    }

    if (value.contains('ดนตรี')) {
      return Icons
          .music_note_rounded;
    }

    return Icons.groups_rounded;
  }
}

class LatestMessageText
    extends StatelessWidget {
  final String activityId;

  const LatestMessageText({
    super.key,
    required this.activityId,
  });

  String _formatChatTime(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return '';
    }

    final date =
    timestamp.toDate();

    final now =
    DateTime.now();

    final today =
    DateTime(
      now.year,
      now.month,
      now.day,
    );

    final messageDay =
    DateTime(
      date.year,
      date.month,
      date.day,
    );

    final difference =
        today
            .difference(
          messageDay,
        )
            .inDays;

    if (difference == 0) {
      return DateFormat(
        'HH:mm',
      ).format(date);
    }

    if (difference == 1) {
      return 'เมื่อวาน';
    }

    return DateFormat(
      'd MMM',
    ).format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (activityId.isEmpty) {
      return const Text(
        'ยังไม่มีข้อความ',
        maxLines: 1,
        overflow:
        TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.grey,
          fontSize: 13,
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<
            Map<String, dynamic>>>(
      stream: FirebaseFirestore
          .instance
          .collection(
        'activities',
      )
          .doc(activityId)
          .collection(
        'messages',
      )
          .orderBy(
        'sentAt',
        descending: true,
      )
          .limit(1)
          .snapshots(),
      builder: (
          context,
          snapshot,
          ) {
        if (snapshot.hasError) {
          return const Text(
            'ไม่สามารถโหลดข้อความได้',
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          );
        }

        final docs =
            snapshot.data?.docs ??
                [];

        if (docs.isEmpty) {
          return const Text(
            'ยังไม่มีข้อความ',
            maxLines: 1,
            overflow:
            TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          );
        }

        final data =
        docs.first.data();

        final sender =
            data['senderName']
                ?.toString() ??
                'ผู้ใช้';

        final message =
            data['message']
                ?.toString() ??
                '';

        final sentAt =
        data['sentAt'];

        final timeText =
        _formatChatTime(
          sentAt is Timestamp
              ? sentAt
              : null,
        );

        return Row(
          children: [
            Expanded(
              child: Text(
                '$sender: $message',
                maxLines: 1,
                overflow:
                TextOverflow.ellipsis,
                style:
                const TextStyle(
                  color:
                  Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),

            if (timeText
                .isNotEmpty) ...[
              const SizedBox(
                width: 8,
              ),
              Text(
                timeText,
                style:
                const TextStyle(
                  color:
                  Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class UnreadBadge
    extends StatelessWidget {
  final String activityId;

  const UnreadBadge({
    super.key,
    required this.activityId,
  });

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null ||
        activityId.isEmpty) {
      return const SizedBox.shrink();
    }

    final participantRef =
    FirebaseFirestore.instance
        .collection(
      'activities',
    )
        .doc(activityId)
        .collection(
      'participants',
    )
        .doc(user.uid);

    return StreamBuilder<
        DocumentSnapshot<
            Map<String, dynamic>>>(
      stream:
      participantRef.snapshots(),
      builder: (
          context,
          participantSnapshot,
          ) {
        if (!participantSnapshot
            .hasData ||
            !participantSnapshot
                .data!.exists) {
          return const SizedBox
              .shrink();
        }

        final participantData =
        participantSnapshot
            .data!
            .data();

        final lastReadAt =
        participantData?[
        'lastReadAt'];

        Query<
            Map<String, dynamic>>
        messagesQuery =
        FirebaseFirestore.instance
            .collection(
          'activities',
        )
            .doc(activityId)
            .collection(
          'messages',
        );

        if (lastReadAt
        is Timestamp) {
          messagesQuery =
              messagesQuery.where(
                'sentAt',
                isGreaterThan:
                lastReadAt,
              );
        }

        return StreamBuilder<
            QuerySnapshot<
                Map<String, dynamic>>>(
          stream:
          messagesQuery.snapshots(),
          builder: (
              context,
              messageSnapshot,
              ) {
            if (!messageSnapshot
                .hasData) {
              return const SizedBox
                  .shrink();
            }

            final unreadCount =
                messageSnapshot
                    .data!.docs
                    .where(
                      (doc) {
                    final data =
                    doc.data();

                    return data[
                    'senderId'] !=
                        user.uid;
                  },
                )
                    .length;

            if (unreadCount == 0) {
              return const SizedBox
                  .shrink();
            }

            return Container(
              constraints:
              const BoxConstraints(
                minWidth: 30,
                minHeight: 30,
              ),
              padding:
              const EdgeInsets
                  .symmetric(
                horizontal: 8,
                vertical: 5,
              ),
              alignment:
              Alignment.center,
              decoration:
              const BoxDecoration(
                color:
                Color(
                  0xFFE53935,
                ),
                shape:
                BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99
                    ? '99+'
                    : '$unreadCount',
                style:
                const TextStyle(
                  color:
                  Colors.white,
                  fontSize: 13,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }
}