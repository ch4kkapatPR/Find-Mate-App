import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';
import 'create_post_page.dart';
import 'group_chat_page.dart';
import 'participants_page.dart';

class ActivityDetailPage extends StatefulWidget {
  final ActivityItem item;

  const ActivityDetailPage({
    super.key,
    required this.item,
  });

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  bool _isProcessing = false;
  Timer? _clockTimer;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  // EDIT ACTIVITY
  // =========================================================

  Future<void> _editActivity(ActivityItem activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreatePostPage(
          activity: activity,
        ),
      ),
    );
  }

  // =========================================================
  // DELETE ACTIVITY
  // =========================================================

  Future<void> _deleteActivity(ActivityItem activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ลบกิจกรรม',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'ต้องการลบกิจกรรมนี้หรือไม่?\n'
                'รายชื่อผู้เข้าร่วมและข้อความแชทจะถูกลบด้วย',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบกิจกรรม'),
            ),
          ],
        );
      },
    );

    if (confirm != true || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirestoreActivityService.deleteActivity(activity);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ลบกิจกรรมเรียบร้อยแล้ว'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ลบกิจกรรมไม่สำเร็จ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =========================================================
  // JOIN ACTIVITY
  // =========================================================

  Future<void> _joinActivity(ActivityItem activity) async {
    if (_isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirestoreActivityService.joinActivity(activity);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เข้าร่วมกิจกรรมแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เข้าร่วมกิจกรรมไม่สำเร็จ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =========================================================
  // LEAVE ACTIVITY
  // =========================================================

  Future<void> _leaveActivity(ActivityItem activity) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ออกจากกิจกรรม',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'ต้องการออกจากกิจกรรมนี้หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ออกจากกิจกรรม'),
            ),
          ],
        );
      },
    );

    if (confirm != true || _isProcessing) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      await FirestoreActivityService.leaveActivity(activity);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ออกจากกิจกรรมแล้ว'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ออกจากกิจกรรมไม่สำเร็จ: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // =========================================================
  // OPEN PARTICIPANTS
  // =========================================================

  Future<void> _openParticipants(ActivityItem activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantsPage(
          activity: activity,
        ),
      ),
    );
  }

  // =========================================================
  // OPEN GROUP CHAT
  // =========================================================

  Future<void> _openGroupChat(ActivityItem activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupChatPage(
          activityId: activity.id,
          activityTitle: activity.title,
        ),
      ),
    );
  }

  // =========================================================
  // SHARE ACTIVITY
  // =========================================================

  Future<void> _shareActivity(ActivityItem activity) async {
    final remaining = activity.total - activity.joined;

    final memberStatus = remaining <= 0
        ? 'เต็มแล้ว'
        : 'เหลืออีก $remaining ที่';

    final timeRange = _formatTimeRange(activity);

    final text = '''
ชวนเข้าร่วมกิจกรรมบน FindMate 🎉

${activity.title}

หมวดหมู่: ${activity.category}
วันที่: ${activity.dateText}
เวลา: $timeRange
สถานที่: ${activity.location}
สมาชิก: ${activity.joined}/${activity.total} คน
สถานะ: $memberStatus

${activity.description}
''';

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: activity.title,
          subject: 'กิจกรรม FindMate: ${activity.title}',
          text: text.trim(),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('แชร์กิจกรรมไม่สำเร็จ: $e'),
        ),
      );
    }
  }

  // =========================================================
  // DATE / TIME PARSING
  // =========================================================

  DateTime? _parseDateText(String text) {
    final value = text.trim();

    if (value.isEmpty) {
      return null;
    }

    try {
      final parts = value.split(RegExp(r'\s+'));

      if (parts.length >= 3) {
        final day = int.tryParse(parts[0]);

        const months = {
          'ม.ค.': 1,
          'ก.พ.': 2,
          'มี.ค.': 3,
          'เม.ย.': 4,
          'พ.ค.': 5,
          'มิ.ย.': 6,
          'ก.ค.': 7,
          'ส.ค.': 8,
          'ก.ย.': 9,
          'ต.ค.': 10,
          'พ.ย.': 11,
          'ธ.ค.': 12,
        };

        final month = months[parts[1]];
        final rawYear = int.tryParse(parts[2]);

        if (day != null && month != null && rawYear != null) {
          final year = rawYear > 2400
              ? rawYear - 543
              : rawYear;

          return DateTime(
            year,
            month,
            day,
          );
        }
      }

      final normalized = value.replaceAll('-', '/');
      final slashParts = normalized.split('/');

      if (slashParts.length == 3) {
        final day = int.tryParse(
          slashParts[0].trim(),
        );

        final month = int.tryParse(
          slashParts[1].trim(),
        );

        var year = int.tryParse(
          slashParts[2].trim(),
        );

        if (day == null || month == null || year == null) {
          return null;
        }

        if (year > 2400) {
          year -= 543;
        }

        return DateTime(
          year,
          month,
          day,
        );
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  TimeOfDay? _parseTimeText(String text) {
    final value = text.trim();

    if (value.isEmpty) {
      return null;
    }

    final match = RegExp(
      r'(\d{1,2})\s*:\s*(\d{2})',
    ).firstMatch(value);

    if (match == null) {
      return null;
    }

    final hour = int.tryParse(
      match.group(1) ?? '',
    );

    final minute = int.tryParse(
      match.group(2) ?? '',
    );

    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  DateTime? _combineDateAndTime(
      String dateText,
      String timeText,
      ) {
    final date = _parseDateText(dateText);
    final time = _parseTimeText(timeText);

    if (date == null || time == null) {
      return null;
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  // =========================================================
  // ACTIVITY STATUS
  // =========================================================

  _ActivityTimeStatus _getTimeStatus(
      ActivityItem activity,
      ) {
    final startAt = _combineDateAndTime(
      activity.dateText,
      activity.timeText,
    );

    final endAt = _combineDateAndTime(
      activity.dateText,
      activity.endTimeText,
    );

    final now = DateTime.now();

    if (startAt == null) {
      return _ActivityTimeStatus.unknown;
    }

    if (now.isBefore(startAt)) {
      return _ActivityTimeStatus.upcoming;
    }

    if (endAt == null) {
      return _ActivityTimeStatus.ongoing;
    }

    if (now.isBefore(endAt)) {
      return _ActivityTimeStatus.ongoing;
    }

    return _ActivityTimeStatus.ended;
  }

  String _formatTimeRange(
      ActivityItem activity,
      ) {
    final start = activity.timeText.trim();
    final end = activity.endTimeText.trim();

    if (start.isEmpty && end.isEmpty) {
      return '-';
    }

    if (end.isEmpty) {
      return start;
    }

    if (start.isEmpty) {
      return end;
    }

    return '$start - $end';
  }

  String _statusText(
      _ActivityTimeStatus status,
      ) {
    switch (status) {
      case _ActivityTimeStatus.upcoming:
        return 'ยังไม่เริ่ม';
      case _ActivityTimeStatus.ongoing:
        return 'กำลังดำเนินกิจกรรม';
      case _ActivityTimeStatus.ended:
        return 'สิ้นสุดกิจกรรมแล้ว';
      case _ActivityTimeStatus.unknown:
        return 'ไม่ทราบสถานะเวลา';
    }
  }

  IconData _statusIcon(
      _ActivityTimeStatus status,
      ) {
    switch (status) {
      case _ActivityTimeStatus.upcoming:
        return Icons.schedule_rounded;
      case _ActivityTimeStatus.ongoing:
        return Icons.play_circle_outline_rounded;
      case _ActivityTimeStatus.ended:
        return Icons.check_circle_outline_rounded;
      case _ActivityTimeStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }

  Color _statusColor(
      _ActivityTimeStatus status,
      ) {
    switch (status) {
      case _ActivityTimeStatus.upcoming:
        return const Color(0xFF6C4DFF);
      case _ActivityTimeStatus.ongoing:
        return Colors.orange;
      case _ActivityTimeStatus.ended:
        return Colors.grey;
      case _ActivityTimeStatus.unknown:
        return Colors.grey;
    }
  }

  Color _statusBackgroundColor(
      _ActivityTimeStatus status,
      ) {
    switch (status) {
      case _ActivityTimeStatus.upcoming:
        return const Color(0xFFEDE8FF);
      case _ActivityTimeStatus.ongoing:
        return const Color(0xFFFFF3E0);
      case _ActivityTimeStatus.ended:
        return const Color(0xFFEEEEEE);
      case _ActivityTimeStatus.unknown:
        return const Color(0xFFEEEEEE);
    }
  }

  // =========================================================
  // IMAGES
  // =========================================================

  Widget _buildMainImage(ActivityItem activity) {
    if (activity.image.isEmpty) {
      return _imagePlaceholder(
        height: 240,
      );
    }

    if (activity.image.startsWith('http')) {
      return Image.network(
        activity.image,
        width: double.infinity,
        height: 240,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _imagePlaceholder(
            height: 240,
          );
        },
      );
    }

    return Image.file(
      File(activity.image),
      width: double.infinity,
      height: 240,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return _imagePlaceholder(
          height: 240,
        );
      },
    );
  }

  Widget _buildAdditionalImage(String image) {
    if (image.isEmpty) {
      return _imagePlaceholder(
        height: 120,
        width: 160,
      );
    }

    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: 160,
        height: 120,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _imagePlaceholder(
            height: 120,
            width: 160,
          );
        },
      );
    }

    return Image.file(
      File(image),
      width: 160,
      height: 120,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return _imagePlaceholder(
          height: 120,
          width: 160,
        );
      },
    );
  }

  Widget _imagePlaceholder({
    required double height,
    double? width,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: const Color(0xFFEDE8FF),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 55,
        color: Color(0xFF6C4DFF),
      ),
    );
  }

  // =========================================================
  // ORGANIZER
  // =========================================================

  Widget _buildOrganizerCard({
    required ActivityItem activity,
    required bool isOwner,
  }) {
    final ownerId = activity.ownerId.trim();

    if (ownerId.isEmpty) {
      return _organizerCardContent(
        name: 'ผู้ใช้ FindMate',
        bio: isOwner
            ? 'คุณเป็นเจ้าของกิจกรรมนี้'
            : 'ผู้จัดกิจกรรม',
        imageUrl: '',
        isOwner: isOwner,
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        final data = snapshot.data?.data();

        final name =
            data?['name']?.toString().trim() ?? '';

        final bio =
            data?['bio']?.toString().trim() ?? '';

        final profileImageUrl =
            data?['profileImageUrl']?.toString().trim() ?? '';

        return _organizerCardContent(
          name: name.isNotEmpty
              ? name
              : 'ผู้ใช้ FindMate',
          bio: isOwner
              ? 'คุณเป็นเจ้าของกิจกรรมนี้'
              : bio.isNotEmpty
                  ? bio
                  : 'ผู้จัดกิจกรรม',
          imageUrl: profileImageUrl,
          isOwner: isOwner,
        );
      },
    );
  }

  Widget _organizerCardContent({
    required String name,
    required String bio,
    required String imageUrl,
    required bool isOwner,
  }) {
    return Container(
      padding: const EdgeInsets.all(
        15,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Row(
        children: [
          _buildOrganizerAvatar(
            imageUrl,
          ),

          const SizedBox(
            width: 13,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  bio,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (isOwner)
            const Padding(
              padding: EdgeInsets.only(
                left: 8,
              ),
              child: Icon(
                Icons.verified_rounded,
                color: Color(
                  0xFF6C4DFF,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrganizerAvatar(
    String imageUrl,
  ) {
    if (imageUrl.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _organizerAvatarPlaceholder();
          },
        ),
      );
    }

    // รูปโปรไฟล์แบบ local path ของอีกเครื่องไม่สามารถเปิดได้
    // จึงใช้ placeholder จนกว่าจะมีระบบอัปโหลดรูปขึ้น cloud.
    return _organizerAvatarPlaceholder();
  }

  Widget _organizerAvatarPlaceholder() {
    return Container(
      width: 50,
      height: 50,
      decoration: const BoxDecoration(
        color: Color(
          0xFFEDE8FF,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Color(
          0xFF6C4DFF,
        ),
        size: 29,
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE8FF),
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6C4DFF),
              size: 21,
            ),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  value.isEmpty
                      ? '-'
                      : value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    if (widget.item.id.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text(
            'ไม่พบ Activity ID',
          ),
        ),
      );
    }

    return StreamBuilder<ActivityItem?>(
      stream: FirestoreActivityService.getActivityStream(
        widget.item.id,
      ),
      builder: (
          context,
          snapshot,
          ) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6C4DFF),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: Text(
                  'โหลดกิจกรรมไม่สำเร็จ\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final currentActivity = snapshot.data;

        if (currentActivity == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text(
                'ไม่พบกิจกรรมนี้\nกิจกรรมอาจถูกลบไปแล้ว',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final remaining = currentActivity.total - currentActivity.joined;
        final isFull = remaining <= 0;
        final isJoined = currentActivity.isJoined;
        final isOwner = currentActivity.isOwner;

        final timeStatus = _getTimeStatus(
          currentActivity,
        );

        final hasStarted =
            timeStatus == _ActivityTimeStatus.ongoing ||
                timeStatus == _ActivityTimeStatus.ended;

        final hasEnded =
            timeStatus == _ActivityTimeStatus.ended;

        final canJoin =
            !isJoined &&
                !isFull &&
                !hasStarted &&
                !_isProcessing;

        return Scaffold(
          backgroundColor: const Color(
            0xFFF8F9FE,
          ),
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'รายละเอียดกิจกรรม',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'แชร์กิจกรรม',
                onPressed: () {
                  _shareActivity(
                    currentActivity,
                  );
                },
                icon: const Icon(
                  Icons.share_rounded,
                  color: Color(0xFF6C4DFF),
                ),
              ),
              const SizedBox(
                width: 6,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(
              bottom: 130,
            ),
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(
                    28,
                  ),
                ),
                child: _buildMainImage(
                  currentActivity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDE8FF),
                        borderRadius: BorderRadius.circular(
                          20,
                        ),
                      ),
                      child: Text(
                        currentActivity.category,
                        style: const TextStyle(
                          color: Color(0xFF6C4DFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      currentActivity.title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_alt_outlined,
                          color: Color(0xFF6C4DFF),
                          size: 21,
                        ),
                        const SizedBox(
                          width: 7,
                        ),
                        Text(
                          '${currentActivity.joined}/${currentActivity.total} คน',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isOwner) ...[
                          const SizedBox(
                            width: 10,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEDE8FF),
                              borderRadius: BorderRadius.circular(
                                10,
                              ),
                            ),
                            child: const Text(
                              'เจ้าของกิจกรรม',
                              style: TextStyle(
                                color: Color(0xFF6C4DFF),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(
                      height: 15,
                    ),

                    // เวลา / สถานะกิจกรรม
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBackgroundColor(
                          timeStatus,
                        ),
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _statusIcon(
                              timeStatus,
                            ),
                            color: _statusColor(
                              timeStatus,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              _statusText(
                                timeStatus,
                              ),
                              style: TextStyle(
                                color: _statusColor(
                                  timeStatus,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    // ที่ว่าง
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: isFull
                            ? const Color(0xFFFFEBEE)
                            : const Color(0xFFE8F7EC),
                        borderRadius: BorderRadius.circular(
                          15,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isFull
                                ? Icons.block_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isFull
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: Text(
                              isFull
                                  ? 'กิจกรรมเต็มแล้ว'
                                  : 'ยังเหลืออีก $remaining ที่',
                              style: TextStyle(
                                color: isFull
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      title: 'วันที่',
                      value: currentActivity.dateText,
                    ),

                    _buildInfoRow(
                      icon: Icons.access_time_rounded,
                      title: 'เวลา',
                      value: _formatTimeRange(
                        currentActivity,
                      ),
                    ),

                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      title: 'สถานที่',
                      value: currentActivity.location,
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Text(
                      'รายละเอียด',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          18,
                        ),
                      ),
                      child: Text(
                        currentActivity.description.trim().isEmpty
                            ? 'ไม่มีรายละเอียดเพิ่มเติม'
                            : currentActivity.description,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                        ),
                      ),
                    ),

                    if (currentActivity.images.isNotEmpty) ...[
                      const SizedBox(
                        height: 25,
                      ),
                      const Text(
                        'รูปเพิ่มเติม',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      SizedBox(
                        height: 120,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: currentActivity.images.length,
                          separatorBuilder: (
                              context,
                              index,
                              ) {
                            return const SizedBox(
                              width: 10,
                            );
                          },
                          itemBuilder: (
                              context,
                              index,
                              ) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(
                                15,
                              ),
                              child: _buildAdditionalImage(
                                currentActivity.images[index],
                              ),
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(
                      height: 25,
                    ),

                    const Text(
                      'ผู้จัดกิจกรรม',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    _buildOrganizerCard(
                      activity: currentActivity,
                      isOwner: isOwner,
                    ),

                    if (isJoined) ...[
                      const SizedBox(
                        height: 25,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _openParticipants(
                                  currentActivity,
                                );
                              },
                              icon: const Icon(
                                Icons.people_outline_rounded,
                              ),
                              label: const Text(
                                'สมาชิก',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6C4DFF),
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF6C4DFF),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _openGroupChat(
                                  currentActivity,
                                );
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                              ),
                              label: const Text(
                                'แชทกลุ่ม',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6C4DFF),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isOwner) ...[
                      const SizedBox(
                        height: 25,
                      ),
                      const Text(
                        'จัดการกิจกรรม',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                _editActivity(
                                  currentActivity,
                                );
                              },
                              icon: const Icon(
                                Icons.edit_outlined,
                              ),
                              label: const Text(
                                'แก้ไข',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6C4DFF),
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                                side: const BorderSide(
                                  color: Color(0xFF6C4DFF),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                _deleteActivity(
                                  currentActivity,
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                              ),
                              label: const Text(
                                'ลบ',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                minimumSize: const Size(
                                  double.infinity,
                                  50,
                                ),
                                side: const BorderSide(
                                  color: Colors.red,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // =====================================================
          // BOTTOM ACTION
          // =====================================================

          bottomNavigationBar: isOwner
              ? SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                14,
              ),
              color: Colors.white,
              child: Container(
                padding: const EdgeInsets.all(
                  14,
                ),
                decoration: BoxDecoration(
                  color: hasEnded
                      ? const Color(0xFFEEEEEE)
                      : const Color(0xFFEDE8FF),
                  borderRadius: BorderRadius.circular(
                    15,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasEnded
                          ? Icons.check_circle_outline_rounded
                          : Icons.verified_user_outlined,
                      color: hasEnded
                          ? Colors.grey
                          : const Color(0xFF6C4DFF),
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Flexible(
                      child: Text(
                        hasEnded
                            ? 'กิจกรรมนี้สิ้นสุดแล้ว'
                            : 'คุณเป็นผู้จัดกิจกรรมและเข้าร่วมโดยอัตโนมัติ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: hasEnded
                              ? Colors.grey
                              : const Color(0xFF6C4DFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              : SafeArea(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                14,
              ),
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _isProcessing
                      ? null
                      : isJoined
                      ? () {
                    _leaveActivity(
                      currentActivity,
                    );
                  }
                      : canJoin
                      ? () {
                    _joinActivity(
                      currentActivity,
                    );
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isJoined
                        ? Colors.red
                        : const Color(0xFF6C4DFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Text(
                    isJoined
                        ? 'ออกจากกิจกรรม'
                        : hasEnded
                        ? 'กิจกรรมสิ้นสุดแล้ว'
                        : hasStarted
                        ? 'กิจกรรมเริ่มแล้ว'
                        : isFull
                        ? 'กิจกรรมเต็มแล้ว'
                        : 'เข้าร่วมกิจกรรม',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

enum _ActivityTimeStatus {
  upcoming,
  ongoing,
  ended,
  unknown,
}
