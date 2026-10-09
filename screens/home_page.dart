import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import 'activity_detail_page.dart';

class HomePage extends StatefulWidget {
  final List<ActivityItem> activities;

  const HomePage({
    super.key,
    required this.activities,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedCategory = 'ทั้งหมด';
  String _searchText = '';

  final TextEditingController _searchController = TextEditingController();

  Timer? _clockTimer;

  final List<String> categories = [
    'ทั้งหมด',
    'เดินป่า',
    'กีฬา',
    'เรียน',
    'กินข้าว',
    'อื่นๆ',
  ];

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
    _searchController.dispose();
    super.dispose();
  }

  List<ActivityItem> get joinedActivities {
    return widget.activities
        .where(
          (activity) => activity.isJoined,
    )
        .toList();
  }

  void _refreshPage() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildGreeting() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Text(
        'สวัสดี 👋',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        final data = snapshot.data?.data();

        final firestoreName =
            data?['name']?.toString().trim() ?? '';

        final authName =
            user.displayName?.trim() ?? '';

        final name = firestoreName.isNotEmpty
            ? firestoreName
            : authName.isNotEmpty
                ? authName
                : 'ผู้ใช้ FindMate';

        return Text(
          'สวัสดี, $name 👋',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final allActivities = widget.activities;
    final myActivities = joinedActivities;

    final filteredActivities = allActivities.where((item) {
      final matchesCategory =
          _selectedCategory == 'ทั้งหมด' ||
              item.category == _selectedCategory;

      final searchText = _searchText.toLowerCase();

      final matchesSearch =
          item.title.toLowerCase().contains(searchText) ||
              item.location.toLowerCase().contains(searchText) ||
              item.category.toLowerCase().contains(searchText) ||
              item.ownerName.toLowerCase().contains(searchText);

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreeting(),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: 'Find'),
                  TextSpan(
                    text: 'Mate',
                    style: TextStyle(
                      color: Color(0xFF6C4DFF),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.05,
                  ),
                  blurRadius: 10,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.black,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  15,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.03,
                    ),
                    blurRadius: 10,
                    offset: const Offset(
                      0,
                      4,
                    ),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchText = value;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'ค้นหากิจกรรม...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF6C4DFF),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected =
                    _selectedCategory == category;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 10,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C4DFF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(
                        25,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: const Color(0xFF6C4DFF)
                              .withValues(
                            alpha: 0.3,
                          ),
                          blurRadius: 8,
                          offset: const Offset(
                            0,
                            4,
                          ),
                        ),
                      ]
                          : [],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                100,
              ),
              children: [
                const Text(
                  'เข้าร่วมกิจกรรม 🎉',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                if (myActivities.isEmpty)
                  const _EmptyJoinedCard()
                else
                  ...myActivities.map(
                        (activity) => ActivityCard(
                      item: activity,
                      onReturn: _refreshPage,
                    ),
                  ),
                const SizedBox(
                  height: 25,
                ),
                const Text(
                  'กิจกรรมทั้งหมด',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                if (filteredActivities.isEmpty)
                  const _EmptySearchCard()
                else
                  ...filteredActivities.map(
                        (activity) => ActivityCard(
                      item: activity,
                      onReturn: _refreshPage,
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

class ActivityCard extends StatelessWidget {
  final ActivityItem item;
  final VoidCallback? onReturn;

  const ActivityCard({
    super.key,
    required this.item,
    this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final status = _ActivityTimeHelper.status(item);
    final statusText = _ActivityTimeHelper.statusText(status);
    final statusColor = _ActivityTimeHelper.statusColor(status);
    final timeRange = _ActivityTimeHelper.timeRange(item);

    return Container(
      margin: const EdgeInsets.only(
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          25,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
            blurRadius: 15,
            offset: const Offset(
              0,
              8,
            ),
          ),
        ],
      ),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ActivityDetailPage(
                item: item,
              ),
            ),
          );

          onReturn?.call();
        },
        borderRadius: BorderRadius.circular(
          25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(
                      25,
                    ),
                  ),
                  child: Hero(
                    tag: item.id.isNotEmpty
                        ? item.id
                        : item.title,
                    child: _buildImage(),
                  ),
                ),
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C4DFF)
                          .withValues(
                        alpha: 0.9,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: item.isJoined
                          ? Colors.green.withValues(
                        alpha: 0.95,
                      )
                          : statusColor.withValues(
                        alpha: 0.95,
                      ),
                      borderRadius: BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      item.isJoined
                          ? 'เข้าร่วมแล้ว'
                          : statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE8FF),
                          borderRadius: BorderRadius.circular(
                            20,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 14,
                              color: Color(0xFF6C4DFF),
                            ),
                            const SizedBox(
                              width: 4,
                            ),
                            Text(
                              '${item.joined}/${item.total}',
                              style: const TextStyle(
                                color: Color(0xFF6C4DFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Color(0xFF6C4DFF),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          'โดย ${_ownerName(item)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6C4DFF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  _infoRow(
                    Icons.calendar_today_rounded,
                    item.dateText,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _infoRow(
                    Icons.access_time_rounded,
                    timeRange,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  _infoRow(
                    Icons.location_on_rounded,
                    item.location,
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(
                              alpha: 0.10,
                            ),
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _ActivityTimeHelper.statusIcon(
                                  status,
                                ),
                                size: 16,
                                color: statusColor,
                              ),
                              const SizedBox(
                                width: 6,
                              ),
                              Flexible(
                                child: Text(
                                  statusText,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityDetailPage(
                                item: item,
                              ),
                            ),
                          );

                          onReturn?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6C4DFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              12,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'ดูรายละเอียด',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ownerName(ActivityItem activity) {
    final name = activity.ownerName.trim();

    if (name.isNotEmpty) {
      return name;
    }

    return 'ผู้ใช้ FindMate';
  }

  Widget _buildImage() {
    if (item.image.isEmpty) {
      return _imageError();
    }

    if (item.image.startsWith('http')) {
      return Image.network(
        item.image,
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (
            context,
            error,
            stackTrace,
            ) {
          return _imageError();
        },
      );
    }

    return Image.file(
      File(item.image),
      width: double.infinity,
      height: 200,
      fit: BoxFit.cover,
      errorBuilder: (
          context,
          error,
          stackTrace,
          ) {
        return _imageError();
      },
    );
  }

  static Widget _imageError() {
    return Container(
      width: double.infinity,
      height: 200,
      color: const Color(0xFFEDEDED),
      child: const Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 50,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _infoRow(
      IconData icon,
      String text,
      ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[400],
        ),
        const SizedBox(
          width: 8,
        ),
        Expanded(
          child: Text(
            text.isEmpty
                ? '-'
                : text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyJoinedCard extends StatelessWidget {
  const _EmptyJoinedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 50,
            color: Colors.grey[300],
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'ยังไม่มีกิจกรรมที่เข้าร่วม',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          const Text(
            'ลองเลือกกิจกรรมที่สนใจแล้วกดเข้าร่วม',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySearchCard extends StatelessWidget {
  const _EmptySearchCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          20,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 50,
            color: Colors.grey[300],
          ),
          const SizedBox(
            height: 10,
          ),
          const Text(
            'ไม่พบกิจกรรม',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

enum _ActivityTimeStatus {
  upcoming,
  ongoing,
  ended,
  unknown,
}

class _ActivityTimeHelper {
  static DateTime? _parseDate(String text) {
    final value = text.trim();

    if (value.isEmpty) {
      return null;
    }

    try {
      final parts = value.split(
        RegExp(r'\s+'),
      );

      if (parts.length >= 3) {
        final day = int.tryParse(
          parts[0],
        );

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
        final rawYear = int.tryParse(
          parts[2],
        );

        if (day != null &&
            month != null &&
            rawYear != null) {
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

      final normalized = value.replaceAll(
        '-',
        '/',
      );

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

        if (day == null ||
            month == null ||
            year == null) {
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

  static TimeOfDay? _parseTime(String text) {
    final match = RegExp(
      r'(\d{1,2})\s*:\s*(\d{2})',
    ).firstMatch(
      text.trim(),
    );

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

  static DateTime? _combine(
      String dateText,
      String timeText,
      ) {
    final date = _parseDate(
      dateText,
    );

    final time = _parseTime(
      timeText,
    );

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

  static _ActivityTimeStatus status(
      ActivityItem activity,
      ) {
    final startAt = _combine(
      activity.dateText,
      activity.timeText,
    );

    final endAt = _combine(
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

    if (endAt == null || now.isBefore(endAt)) {
      return _ActivityTimeStatus.ongoing;
    }

    return _ActivityTimeStatus.ended;
  }

  static String timeRange(
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

  static String statusText(
      _ActivityTimeStatus status,
      ) {
    switch (status) {
      case _ActivityTimeStatus.upcoming:
        return 'ยังไม่เริ่ม';
      case _ActivityTimeStatus.ongoing:
        return 'กำลังดำเนินกิจกรรม';
      case _ActivityTimeStatus.ended:
        return 'สิ้นสุดแล้ว';
      case _ActivityTimeStatus.unknown:
        return 'ไม่ทราบเวลา';
    }
  }

  static Color statusColor(
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

  static IconData statusIcon(
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
}
