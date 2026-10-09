import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';
import 'activity_detail_page.dart';
import 'participants_page.dart';

class GroupChatPage extends StatefulWidget {
  final String activityId;
  final String activityTitle;

  const GroupChatPage({
    super.key,
    required this.activityId,
    required this.activityTitle,
  });

  @override
  State<GroupChatPage> createState() =>
      _GroupChatPageState();
}

class _GroupChatPageState
    extends State<GroupChatPage> {
  final TextEditingController _messageController =
  TextEditingController();

  final ScrollController _scrollController =
  ScrollController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool _isSending = false;
  int _lastMessageCount = -1;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        _markAsRead();
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================
  // Mark As Read
  // =========================
  Future<void> _markAsRead() async {
    try {
      await FirestoreActivityService.markChatAsRead(
        widget.activityId,
      );
    } catch (_) {
      // ไม่ให้ mark read กระทบหน้า chat
    }
  }

  // =========================
  // Load Activity
  // =========================
  Future<ActivityItem?> _loadActivity() async {
    try {
      return await FirestoreActivityService.getActivity(
        widget.activityId,
      );
    } catch (e) {
      if (!mounted) {
        return null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดข้อมูลกิจกรรมไม่สำเร็จ: $e',
          ),
        ),
      );

      return null;
    }
  }

  // =========================
  // Open Participants
  // =========================
  Future<void> _openParticipants() async {
    final activity = await _loadActivity();

    if (!mounted || activity == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantsPage(
          activity: activity,
        ),
      ),
    );
  }

  // =========================
  // Open Activity Detail
  // =========================
  Future<void> _openActivityDetail() async {
    final activity = await _loadActivity();

    if (!mounted || activity == null) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          item: activity,
        ),
      ),
    );
  }

  // =========================
  // Send Message
  // =========================
  Future<void> _sendMessage() async {
    final message =
    _messageController.text.trim();

    if (message.isEmpty || _isSending) {
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      String senderName =
          user.displayName?.trim() ?? '';

      if (senderName.isEmpty) {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();

        senderName =
            userDoc.data()?['name']
                ?.toString()
                .trim() ??
                '';
      }

      if (senderName.isEmpty) {
        senderName = 'ผู้ใช้ FindMate';
      }

      await _firestore
          .collection('activities')
          .doc(widget.activityId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': senderName,
        'message': message,
        'sentAt': FieldValue.serverTimestamp(),
        'editedAt': null,
      });

      _messageController.clear();

      await _markAsRead();

      await Future<void>.delayed(
        const Duration(milliseconds: 150),
      );

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration:
          const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ส่งข้อความไม่สำเร็จ: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  // =========================
  // Copy Message
  // =========================
  Future<void> _copyMessage(
      String message,
      ) async {
    await Clipboard.setData(
      ClipboardData(
        text: message,
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'คัดลอกข้อความแล้ว',
        ),
        duration: Duration(seconds: 1),
      ),
    );
  }

  // =========================
  // Delete Message
  // =========================
  Future<void> _deleteMessage(
      String messageId,
      ) async {
    final confirm =
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ลบข้อความ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'ต้องการลบข้อความนี้หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'ลบ',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await _firestore
          .collection('activities')
          .doc(widget.activityId)
          .collection('messages')
          .doc(messageId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ลบข้อความแล้ว',
          ),
          duration:
          Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ลบข้อความไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // Edit Message
  // =========================
  Future<void> _editMessage({
    required String messageId,
    required String oldMessage,
  }) async {
    String editedMessage = oldMessage;

    final result =
    await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'แก้ไขข้อความ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextFormField(
            initialValue: oldMessage,
            autofocus: true,
            minLines: 1,
            maxLines: 5,
            onChanged: (value) {
              editedMessage = value;
            },
            decoration:
            const InputDecoration(
              hintText:
              'แก้ไขข้อความ...',
              border:
              OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'ยกเลิก',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final value =
                editedMessage.trim();

                if (value.isEmpty) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  value,
                );
              },
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFF6C4DFF,
                ),
                foregroundColor:
                Colors.white,
              ),
              child: const Text(
                'บันทึก',
              ),
            ),
          ],
        );
      },
    );

    if (result == null) {
      return;
    }

    final newMessage =
    result.trim();

    if (newMessage.isEmpty ||
        newMessage ==
            oldMessage.trim()) {
      return;
    }

    try {
      await _firestore
          .collection('activities')
          .doc(widget.activityId)
          .collection('messages')
          .doc(messageId)
          .update({
        'message': newMessage,
        'editedAt':
        FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'แก้ไขข้อความแล้ว',
          ),
          duration:
          Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'แก้ไขข้อความไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // Message Options
  // =========================
  Future<void> _showMessageOptions({
    required String messageId,
    required String message,
    required bool isMe,
  }) async {
    final action =
    await showModalBottomSheet<String>(
      context: context,
      backgroundColor:
      Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin:
            const EdgeInsets.all(
              12,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(
                22,
              ),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                  const Icon(
                    Icons.copy_rounded,
                  ),
                  title:
                  const Text(
                    'คัดลอกข้อความ',
                  ),
                  onTap: () {
                    Navigator.pop(
                      sheetContext,
                      'copy',
                    );
                  },
                ),

                if (isMe)
                  ListTile(
                    leading:
                    const Icon(
                      Icons.edit_outlined,
                      color:
                      Color(
                        0xFF6C4DFF,
                      ),
                    ),
                    title:
                    const Text(
                      'แก้ไขข้อความ',
                      style:
                      TextStyle(
                        color:
                        Color(
                          0xFF6C4DFF,
                        ),
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        'edit',
                      );
                    },
                  ),

                if (isMe)
                  ListTile(
                    leading:
                    const Icon(
                      Icons
                          .delete_outline_rounded,
                      color:
                      Colors.red,
                    ),
                    title:
                    const Text(
                      'ลบข้อความ',
                      style:
                      TextStyle(
                        color:
                        Colors.red,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(
                        sheetContext,
                        'delete',
                      );
                    },
                  ),

                const SizedBox(
                  height: 5,
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted ||
        action == null) {
      return;
    }

    await Future<void>.delayed(
      const Duration(
        milliseconds: 150,
      ),
    );

    if (!mounted) {
      return;
    }

    switch (action) {
      case 'copy':
        await _copyMessage(
          message,
        );
        break;

      case 'edit':
        await _editMessage(
          messageId: messageId,
          oldMessage: message,
        );
        break;

      case 'delete':
        await _deleteMessage(
          messageId,
        );
        break;
    }
  }

  // =========================
  // Messages Stream
  // =========================
  Stream<QuerySnapshot<Map<String, dynamic>>>
  _messagesStream() {
    return _firestore
        .collection('activities')
        .doc(widget.activityId)
        .collection('messages')
        .orderBy(
      'sentAt',
      descending: false,
    )
        .snapshots();
  }

  // =========================
  // Message Time
  // =========================
  String _formatMessageTime(
      Timestamp? timestamp,
      ) {
    if (timestamp == null) {
      return '';
    }

    final date =
    timestamp.toDate();

    final hour =
    date.hour
        .toString()
        .padLeft(
      2,
      '0',
    );

    final minute =
    date.minute
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '$hour:$minute';
  }

  // =========================
  // Date Separator
  // =========================
  String _formatDateSeparator(
      DateTime date,
      ) {
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
      return 'วันนี้';
    }

    if (difference == 1) {
      return 'เมื่อวาน';
    }

    const months = [
      '',
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} '
        '${months[date.month]} '
        '${date.year}';
  }

  bool _isSameDay(
      DateTime a,
      DateTime b,
      ) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    final currentUid =
        _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor:
      const Color(
        0xFFF8F8FC,
      ),

      // =========================
      // AppBar
      // =========================
      appBar: AppBar(
        backgroundColor:
        Colors.white,
        surfaceTintColor:
        Colors.transparent,
        elevation: 0,

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              widget.activityTitle,
              maxLines: 1,
              overflow:
              TextOverflow.ellipsis,
              style:
              const TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),

            StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream: _firestore
                  .collection('activities')
                  .doc(widget.activityId)
                  .collection('participants')
                  .snapshots(),
              builder: (
                  context,
                  snapshot,
                  ) {
                final count =
                    snapshot.data?.docs.length;

                if (count == null) {
                  return const Text(
                    'แชทกลุ่มกิจกรรม',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                }

                return Text(
                  'สมาชิก $count คน',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        ),

        actions: [
          // =========================
          // Participants shortcut
          // =========================
          IconButton(
            tooltip: 'สมาชิก',
            onPressed:
            _openParticipants,
            icon: const Icon(
              Icons
                  .people_alt_outlined,
              color:
              Color(
                0xFF6C4DFF,
              ),
            ),
          ),

          // =========================
          // More Menu
          // =========================
          PopupMenuButton<String>(
            tooltip: 'เพิ่มเติม',
            onSelected: (value) {
              if (value ==
                  'participants') {
                _openParticipants();
              }

              if (value ==
                  'activity') {
                _openActivityDetail();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value:
                  'participants',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .people_outline_rounded,
                        color:
                        Color(
                          0xFF6C4DFF,
                        ),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        'ดูสมาชิก',
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value:
                  'activity',
                  child: Row(
                    children: [
                      Icon(
                        Icons
                            .info_outline_rounded,
                        color:
                        Color(
                          0xFF6C4DFF,
                        ),
                      ),
                      SizedBox(
                        width: 12,
                      ),
                      Text(
                        'รายละเอียดกิจกรรม',
                      ),
                    ],
                  ),
                ),
              ];
            },
          ),

          const SizedBox(
            width: 4,
          ),
        ],
      ),

      // =========================
      // Body
      // =========================
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<
                QuerySnapshot<
                    Map<String, dynamic>>>(
              stream:
              _messagesStream(),
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
                      child: Text(
                        'โหลดข้อความไม่สำเร็จ\n'
                            '${snapshot.error}',
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs =
                    snapshot.data?.docs ??
                        [];

                // =========================
                // Mark Read
                // =========================
                if (_lastMessageCount !=
                    docs.length) {
                  _lastMessageCount =
                      docs.length;

                  WidgetsBinding.instance
                      .addPostFrameCallback(
                        (_) {
                      if (mounted) {
                        _markAsRead();
                      }
                    },
                  );
                }

                // =========================
                // Empty
                // =========================
                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .chat_bubble_outline_rounded,
                          size: 55,
                          color:
                          Colors.grey,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          'ยังไม่มีข้อความ',
                          style:
                          TextStyle(
                            color:
                            Colors.grey,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                        SizedBox(
                          height: 4,
                        ),
                        Text(
                          'เริ่มคุยกับสมาชิกได้เลย',
                          style:
                          TextStyle(
                            color:
                            Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // =========================
                // Auto Scroll
                // =========================
                WidgetsBinding.instance
                    .addPostFrameCallback(
                      (_) {
                    if (_scrollController
                        .hasClients) {
                      _scrollController
                          .jumpTo(
                        _scrollController
                            .position
                            .maxScrollExtent,
                      );
                    }
                  },
                );

                return ListView.builder(
                  controller:
                  _scrollController,
                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    20,
                    15,
                    20,
                    20,
                  ),
                  itemCount:
                  docs.length,
                  itemBuilder: (
                      context,
                      index,
                      ) {
                    final messageId =
                        docs[index].id;

                    final data =
                    docs[index].data();

                    final senderId =
                        data['senderId']
                            ?.toString() ??
                            '';

                    final senderName =
                        data['senderName']
                            ?.toString() ??
                            'ผู้ใช้ FindMate';

                    final message =
                        data['message']
                            ?.toString() ??
                            '';

                    final sentAt =
                    data['sentAt'];

                    final editedAt =
                    data['editedAt'];

                    final timestamp =
                    sentAt is Timestamp
                        ? sentAt
                        : null;

                    final timeText =
                    _formatMessageTime(
                      timestamp,
                    );

                    final messageDate =
                        timestamp?.toDate() ??
                            DateTime.now();

                    final isMe =
                        senderId ==
                            currentUid;

                    final isEdited =
                    editedAt
                    is Timestamp;

                    bool showDateSeparator =
                    false;

                    if (index == 0) {
                      showDateSeparator =
                      true;
                    } else {
                      final previousData =
                      docs[index - 1]
                          .data();

                      final previousSentAt =
                      previousData[
                      'sentAt'];

                      if (previousSentAt
                      is Timestamp) {
                        showDateSeparator =
                        !_isSameDay(
                          previousSentAt
                              .toDate(),
                          messageDate,
                        );
                      } else {
                        showDateSeparator =
                        true;
                      }
                    }

                    return Column(
                      children: [
                        // =========================
                        // Date Separator
                        // =========================
                        if (showDateSeparator)
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(
                              top: 8,
                              bottom: 16,
                            ),
                            child:
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                12,
                                vertical: 6,
                              ),
                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFE9E9EF,
                                ),
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  20,
                                ),
                              ),
                              child: Text(
                                _formatDateSeparator(
                                  messageDate,
                                ),
                                style:
                                const TextStyle(
                                  fontSize: 11,
                                  color:
                                  Colors.grey,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                        // =========================
                        // Message
                        // =========================
                        Align(
                          alignment: isMe
                              ? Alignment
                              .centerRight
                              : Alignment
                              .centerLeft,
                          child: Column(
                            crossAxisAlignment:
                            isMe
                                ? CrossAxisAlignment
                                .end
                                : CrossAxisAlignment
                                .start,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding:
                                  const EdgeInsets
                                      .only(
                                    left: 5,
                                    bottom: 5,
                                  ),
                                  child: Text(
                                    senderName,
                                    style:
                                    const TextStyle(
                                      fontSize: 12,
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                ),

                              GestureDetector(
                                behavior:
                                HitTestBehavior
                                    .opaque,
                                onLongPress:
                                    () {
                                  _showMessageOptions(
                                    messageId:
                                    messageId,
                                    message:
                                    message,
                                    isMe:
                                    isMe,
                                  );
                                },
                                child: Container(
                                  margin:
                                  const EdgeInsets
                                      .only(
                                    bottom: 15,
                                  ),
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    14,
                                    vertical: 9,
                                  ),
                                  constraints:
                                  BoxConstraints(
                                    maxWidth:
                                    MediaQuery.of(
                                      context,
                                    ).size.width *
                                        0.72,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color: isMe
                                        ? const Color(
                                      0xFF6C4DFF,
                                    )
                                        : Colors
                                        .white,
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      18,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize:
                                    MainAxisSize.min,
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .end,
                                    children: [
                                      Text(
                                        message,
                                        style:
                                        TextStyle(
                                          color: isMe
                                              ? Colors.white
                                              : Colors.black87,
                                          fontSize: 14,
                                        ),
                                      ),

                                      if (timeText
                                          .isNotEmpty ||
                                          isEdited) ...[
                                        const SizedBox(
                                          height: 4,
                                        ),

                                        Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            if (isEdited)
                                              Text(
                                                'แก้ไขแล้ว',
                                                style:
                                                TextStyle(
                                                  color: isMe
                                                      ? Colors.white60
                                                      : Colors.grey,
                                                  fontSize: 9,
                                                  fontStyle:
                                                  FontStyle.italic,
                                                ),
                                              ),

                                            if (isEdited &&
                                                timeText
                                                    .isNotEmpty)
                                              const SizedBox(
                                                width: 6,
                                              ),

                                            if (timeText
                                                .isNotEmpty)
                                              Text(
                                                timeText,
                                                style:
                                                TextStyle(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : Colors.grey,
                                                  fontSize: 9,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // =========================
          // Message Input
          // =========================
          SafeArea(
            top: false,
            child: Container(
              color: Colors.white,
              padding:
              const EdgeInsets.all(
                12,
              ),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller:
                      _messageController,
                      textInputAction:
                      TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) {
                        _sendMessage();
                      },
                      decoration:
                      InputDecoration(
                        hintText:
                        'พิมพ์ข้อความ...',
                        filled: true,
                        fillColor:
                        const Color(
                          0xFFF2F2F5,
                        ),
                        contentPadding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            25,
                          ),
                          borderSide:
                          BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  CircleAvatar(
                    radius: 25,
                    backgroundColor:
                    const Color(
                      0xFF6C4DFF,
                    ),
                    child: IconButton(
                      onPressed:
                      _isSending
                          ? null
                          : _sendMessage,
                      icon: _isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child:
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                          Colors.white,
                        ),
                      )
                          : const Icon(
                        Icons
                            .send_rounded,
                        color:
                        Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}