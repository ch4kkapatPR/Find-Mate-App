import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import 'activity_detail_page.dart';

class ExplorePage extends StatefulWidget {
  final List<ActivityItem> activities;

  const ExplorePage({
    super.key,
    required this.activities,
  });

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController =
  TextEditingController();

  Timer? _clockTimer;

  String _searchText = '';
  String _selectedCategory = 'ทั้งหมด';

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
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openActivity(ActivityItem activity) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          item: activity,
        ),
      ),
    );

    // รีเฟรชข้อมูลหลังกลับจากหน้า Detail
    if (mounted) {
      setState(() {});
    }
  }

  List<ActivityItem> _getFilteredActivities() {
    final activities = widget.activities;

    return activities.where((activity) {
      final matchesCategory =
          _selectedCategory == 'ทั้งหมด' ||
              activity.category == _selectedCategory;

      final search = _searchText.toLowerCase();

      final matchesSearch =
          activity.title.toLowerCase().contains(search) ||
              activity.location.toLowerCase().contains(search) ||
              activity.category.toLowerCase().contains(search) ||
              activity.ownerName.toLowerCase().contains(search);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final activities = _getFilteredActivities();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ค้นหากิจกรรม',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // =========================
          // Search
          // =========================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              5,
              20,
              10,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                    Icons.search_rounded,
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

          // =========================
          // Category
          // =========================
          SizedBox(
            height: 58,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final selected =
                    category == _selectedCategory;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 7,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF6C4DFF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: selected
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

          // =========================
          // Activity count
          // =========================
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              5,
            ),
            child: Row(
              children: [
                const Text(
                  'กิจกรรมทั้งหมด',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${activities.length} กิจกรรม',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // =========================
          // Activity List
          // =========================
          Expanded(
            child: activities.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 60,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'ไม่พบกิจกรรม',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                100,
              ),
              itemCount: activities.length,
              itemBuilder: (context, index) {
                final activity = activities[index];

                return _ExploreActivityCard(
                  activity: activity,
                  onTap: () {
                    _openActivity(activity);
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

class _ExploreActivityCard extends StatelessWidget {
  final ActivityItem activity;
  final VoidCallback onTap;

  const _ExploreActivityCard({
    required this.activity,
    required this.onTap,
  });

  Widget _detailsRow(IconData icon, String value, {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 17, color: const Color(0xFF6C4DFF)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlight ? const Color(0xFF6C4DFF) : Colors.grey,
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (activity.image.isEmpty) {
      return Container(
        color: const Color(0xFFEDE8FF),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            color: Color(0xFF6C4DFF),
            size: 40,
          ),
        ),
      );
    }

    if (activity.image.startsWith('http')) {
      return Image.network(
        activity.image,
        width: double.infinity,
        height: 180,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            color: const Color(0xFFEDE8FF),
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 40,
                color: Color(0xFF6C4DFF),
              ),
            ),
          );
        },
      );
    }

    return Image.file(
      File(activity.image),
      width: double.infinity,
      height: 180,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFEDE8FF),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Color(0xFF6C4DFF),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final joined = activity.isJoined;
    final isFull =
        activity.joined >= activity.total;
    final timeStatus = _ExploreTimeHelper.status(activity);
    final isStarted = timeStatus == _ExploreTimeStatus.ongoing ||
        timeStatus == _ExploreTimeStatus.ended;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================
            // Image
            // =========================
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: _buildImage(),
                ),

                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      activity.category,
                      style: const TextStyle(
                        color: Color(0xFF6C4DFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                if (joined)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'เข้าร่วมแล้ว',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // =========================
            // Content
            // =========================
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),
                  _detailsRow(
                    Icons.person_outline_rounded,
                    'โดย ${activity.ownerName.trim().isEmpty ? 'ผู้ใช้ FindMate' : activity.ownerName.trim()}',
                    highlight: true,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline_rounded,
                        size: 18,
                        color: Color(0xFF6C4DFF),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${activity.joined}/${activity.total} คน',
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: Color(0xFF6C4DFF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.dateText,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  _detailsRow(
                    Icons.access_time_rounded,
                    _ExploreTimeHelper.timeRange(activity),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: Color(0xFF6C4DFF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          activity.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isStarted
                              ? _ExploreTimeHelper.statusText(timeStatus)
                              : isFull
                              ? 'เต็มแล้ว'
                              : joined
                              ? 'เข้าร่วมกิจกรรมแล้ว'
                              : 'ยังมีที่ว่าง',
                          style: TextStyle(
                            color: isStarted
                                ? _ExploreTimeHelper.statusColor(timeStatus)
                                : isFull
                                ? Colors.red
                                : joined
                                ? Colors.green
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF6C4DFF),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'ดูรายละเอียด',
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
}

enum _ExploreTimeStatus {
  upcoming,
  ongoing,
  ended,
  unknown,
}

class _ExploreTimeHelper {
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

  static _ExploreTimeStatus status(
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
      return _ExploreTimeStatus.unknown;
    }

    if (now.isBefore(startAt)) {
      return _ExploreTimeStatus.upcoming;
    }

    if (endAt == null || now.isBefore(endAt)) {
      return _ExploreTimeStatus.ongoing;
    }

    return _ExploreTimeStatus.ended;
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
      _ExploreTimeStatus status,
      ) {
    switch (status) {
      case _ExploreTimeStatus.upcoming:
        return 'ยังไม่เริ่ม';
      case _ExploreTimeStatus.ongoing:
        return 'กำลังดำเนินกิจกรรม';
      case _ExploreTimeStatus.ended:
        return 'สิ้นสุดแล้ว';
      case _ExploreTimeStatus.unknown:
        return 'ไม่ทราบเวลา';
    }
  }

  static Color statusColor(
      _ExploreTimeStatus status,
      ) {
    switch (status) {
      case _ExploreTimeStatus.upcoming:
        return const Color(0xFF6C4DFF);
      case _ExploreTimeStatus.ongoing:
        return Colors.orange;
      case _ExploreTimeStatus.ended:
        return Colors.grey;
      case _ExploreTimeStatus.unknown:
        return Colors.grey;
    }
  }

  static IconData statusIcon(
      _ExploreTimeStatus status,
      ) {
    switch (status) {
      case _ExploreTimeStatus.upcoming:
        return Icons.schedule_rounded;
      case _ExploreTimeStatus.ongoing:
        return Icons.play_circle_outline_rounded;
      case _ExploreTimeStatus.ended:
        return Icons.check_circle_outline_rounded;
      case _ExploreTimeStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}

