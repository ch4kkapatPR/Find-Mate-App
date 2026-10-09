import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';
import 'activity_detail_page.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  String _userName = '';
  String _email = '';
  String _bio = 'สมาชิก FindMate';
  String _profileImage = '';

  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOAD PROFILE
  // =========================================================

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
      return;
    }

    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final doc = await ref.get();

      if (!doc.exists) {
        final fallbackName =
            user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : 'ผู้ใช้ FindMate';

        await ref.set({
          'uid': user.uid,
          'name': fallbackName,
          'email': user.email ?? '',
          'bio': 'สมาชิก FindMate',
          'profileImageUrl': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) {
          return;
        }

        setState(() {
          _userName = fallbackName;
          _email = user.email ?? '';
          _bio = 'สมาชิก FindMate';
          _isLoadingProfile = false;
        });

        return;
      }

      final data = doc.data() ?? <String, dynamic>{};

      final firestoreName =
          data['name']?.toString().trim() ?? '';

      final firestoreBio =
          data['bio']?.toString().trim() ?? '';

      final profileImageUrl =
          data['profileImageUrl']?.toString().trim() ?? '';

      if (!mounted) {
        return;
      }

      setState(() {
        _userName = firestoreName.isNotEmpty
            ? firestoreName
            : user.displayName ?? 'ผู้ใช้ FindMate';

        _email = data['email']?.toString() ??
            user.email ??
            '';

        _bio = firestoreBio.isNotEmpty
            ? firestoreBio
            : 'สมาชิก FindMate';

        if (_profileImage.isEmpty &&
            profileImageUrl.isNotEmpty) {
          _profileImage = profileImageUrl;
        }

        _isLoadingProfile = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _userName =
            user.displayName ?? 'ผู้ใช้ FindMate';
        _email = user.email ?? '';
        _isLoadingProfile = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'โหลดโปรไฟล์ไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // OPEN ACTIVITY
  // =========================================================

  Future<void> _openActivity(
    ActivityItem activity,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityDetailPage(
          item: activity,
        ),
      ),
    );
  }

  // =========================================================
  // SCROLL TO SECTION
  // =========================================================

  void _scrollToSection(
    String section,
  ) {
    if (!_scrollController.hasClients) {
      return;
    }

    final offset = section == 'created'
        ? 320.0
        : 650.0;

    _scrollController.animateTo(
      offset,
      duration: const Duration(
        milliseconds: 500,
      ),
      curve: Curves.easeInOut,
    );
  }

  // =========================================================
  // PICK PROFILE IMAGE
  // =========================================================

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _profileImage = image.path;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'เปลี่ยนรูปโปรไฟล์แล้ว (รูปเก็บเฉพาะในเครื่อง)',
        ),
      ),
    );
  }

  // =========================================================
  // EDIT PROFILE
  // =========================================================

  Future<void> _editProfile() async {
    final result = await Navigator.push<_ProfileEditResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfilePage(
          initialName: _userName,
          initialBio: _bio,
          initialImage: _profileImage,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _userName = result.name;
      _bio = result.bio;

      if (result.imagePath.isNotEmpty) {
        _profileImage = result.imagePath;
      }
    });

    await _loadProfile();
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'ออกจากระบบ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'คุณต้องการออกจากระบบหรือไม่?',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'ออกจากระบบ',
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
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ออกจากระบบไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // TIME RANGE
  // =========================================================

  String _timeRange(
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityItem>>(
      stream:
          FirestoreActivityService.getActivitiesStream(),
      builder: (
        context,
        snapshot,
      ) {
        final activities =
            snapshot.data ?? <ActivityItem>[];

        final myCreatedActivities = activities
            .where(
              (activity) => activity.isOwner,
            )
            .toList();

        final myJoinedActivities = activities
            .where(
              (activity) =>
                  activity.isJoined &&
                  !activity.isOwner,
            )
            .toList();

        final createdCount =
            myCreatedActivities.length;

        final joinedCount =
            myJoinedActivities.length;

        return Scaffold(
          backgroundColor: const Color(
            0xFFF8F9FE,
          ),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'โปรไฟล์',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _isLoadingProfile
                    ? null
                    : _editProfile,
                icon: const Icon(
                  Icons.edit_rounded,
                  color: Color(
                    0xFF6C4DFF,
                  ),
                ),
                tooltip: 'แก้ไขโปรไฟล์',
              ),
              const SizedBox(
                width: 8,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadProfile,
            child: ListView(
              controller: _scrollController,
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                20,
                10,
                20,
                100,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(
                    22,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(
                          alpha: 0.04,
                        ),
                        blurRadius: 12,
                        offset: const Offset(
                          0,
                          5,
                        ),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickProfileImage,
                        child: Stack(
                          children: [
                            _buildProfileImage(
                              size: 90,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration:
                                    const BoxDecoration(
                                  color: Color(
                                    0xFF6C4DFF,
                                  ),
                                  shape:
                                      BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons
                                      .camera_alt_rounded,
                                  color:
                                      Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 14,
                      ),

                      Text(
                        _isLoadingProfile
                            ? 'กำลังโหลด...'
                            : _userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      if (_email.isNotEmpty)
                        Text(
                          _email,
                          style: TextStyle(
                            color:
                                Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        _bio,
                        textAlign:
                            TextAlign.center,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      OutlinedButton.icon(
                        onPressed:
                            _isLoadingProfile
                                ? null
                                : _editProfile,
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 18,
                        ),
                        label: const Text(
                          'แก้ไขโปรไฟล์',
                        ),
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color(
                            0xFF6C4DFF,
                          ),
                          side:
                              const BorderSide(
                            color: Color(
                              0xFF6C4DFF,
                            ),
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 15,
                      ),

                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                              onTap: () {
                                _scrollToSection(
                                  'created',
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                                child: _buildStat(
                                  icon: Icons
                                      .event_available_rounded,
                                  value:
                                      '$createdCount',
                                  label:
                                      'กิจกรรมที่สร้าง',
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 45,
                            color: Colors
                                .grey.shade200,
                          ),
                          Expanded(
                            child: InkWell(
                              borderRadius:
                                  BorderRadius.circular(
                                15,
                              ),
                              onTap: () {
                                _scrollToSection(
                                  'joined',
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  vertical: 8,
                                ),
                                child: _buildStat(
                                  icon: Icons
                                      .people_alt_rounded,
                                  value:
                                      '$joinedCount',
                                  label: 'เข้าร่วม',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                const Text(
                  'กิจกรรมที่ฉันสร้าง',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData)
                  _loadingCard()
                else if (snapshot.hasError)
                  _emptyCard(
                    icon:
                        Icons.error_outline_rounded,
                    text:
                        'โหลดกิจกรรมไม่สำเร็จ',
                  )
                else if (myCreatedActivities
                    .isEmpty)
                  _emptyCard(
                    icon:
                        Icons.event_note_outlined,
                    text:
                        'ยังไม่มีกิจกรรมที่สร้าง',
                  )
                else
                  ...myCreatedActivities.map(
                    (activity) =>
                        _buildActivityCard(
                      activity,
                      isOwner: true,
                    ),
                  ),

                const SizedBox(
                  height: 25,
                ),

                const Text(
                  'กิจกรรมที่เข้าร่วม',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                if (snapshot.connectionState ==
                        ConnectionState.waiting &&
                    !snapshot.hasData)
                  _loadingCard()
                else if (snapshot.hasError)
                  _emptyCard(
                    icon:
                        Icons.error_outline_rounded,
                    text:
                        'โหลดกิจกรรมไม่สำเร็จ',
                  )
                else if (myJoinedActivities
                    .isEmpty)
                  _emptyCard(
                    icon:
                        Icons.people_outline_rounded,
                    text:
                        'ยังไม่ได้เข้าร่วมกิจกรรม',
                  )
                else
                  ...myJoinedActivities.map(
                    (activity) =>
                        _buildActivityCard(
                      activity,
                      isOwner: false,
                    ),
                  ),

                const SizedBox(
                  height: 30,
                ),

                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(
                    Icons.logout_rounded,
                  ),
                  label: const Text(
                    'ออกจากระบบ',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                    ),
                    minimumSize: const Size(
                      double.infinity,
                      50,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // PROFILE IMAGE
  // =========================================================

  Widget _buildProfileImage({
    required double size,
  }) {
    if (_profileImage.isEmpty) {
      return _profilePlaceholder(
        size,
      );
    }

    if (_profileImage.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          _profileImage,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (
            context,
            error,
            stackTrace,
          ) {
            return _profilePlaceholder(
              size,
            );
          },
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(
          _profileImage,
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return _profilePlaceholder(
            size,
          );
        },
      ),
    );
  }

  Widget _profilePlaceholder(
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(
          0xFFEDE8FF,
        ),
        border: Border.all(
          color: const Color(
            0xFF6C4DFF,
          ),
          width: 3,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.58,
        color: const Color(
          0xFF6C4DFF,
        ),
      ),
    );
  }

  // =========================================================
  // STAT
  // =========================================================

  Widget _buildStat({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(
            0xFF6C4DFF,
          ),
          size: 25,
        ),
        const SizedBox(
          height: 5,
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // =========================================================
  // LOADING CARD
  // =========================================================

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(
        25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(
            0xFF6C4DFF,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY CARD
  // =========================================================

  Widget _emptyCard({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 25,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          18,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.grey.shade400,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ACTIVITY CARD
  // =========================================================

  Widget _buildActivityCard(
    ActivityItem activity, {
    required bool isOwner,
  }) {
    return GestureDetector(
      onTap: () {
        _openActivity(
          activity,
        );
      },
      child: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            18,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset: const Offset(
                0,
                3,
              ),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
              child: _buildActivityImage(
                activity,
              ),
            ),

            const SizedBox(
              width: 12,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    activity.category,
                    style: const TextStyle(
                      color: Color(
                        0xFF6C4DFF,
                      ),
                      fontSize: 12,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .people_outline_rounded,
                        size: 15,
                        color: Colors.grey,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        '${activity.joined}/${activity.total}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      const Icon(
                        Icons
                            .calendar_today_outlined,
                        size: 13,
                        color: Colors.grey,
                      ),

                      const SizedBox(
                        width: 4,
                      ),

                      Expanded(
                        child: Text(
                          activity.dateText,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .access_time_rounded,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Expanded(
                        child: Text(
                          _timeRange(
                            activity,
                          ),
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 7,
                  ),

                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration:
                        BoxDecoration(
                      color: isOwner
                          ? const Color(
                              0xFFEDE8FF,
                            )
                          : const Color(
                              0xFFE8F7EC,
                            ),
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: Text(
                      isOwner
                          ? 'กิจกรรมของฉัน'
                          : 'เข้าร่วมแล้ว',
                      style: TextStyle(
                        color: isOwner
                            ? const Color(
                                0xFF6C4DFF,
                              )
                            : Colors.green,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ACTIVITY IMAGE
  // =========================================================

  Widget _buildActivityImage(
    ActivityItem activity,
  ) {
    if (activity.image.isEmpty) {
      return _imageError();
    }

    if (activity.image.startsWith('http')) {
      return Image.network(
        activity.image,
        width: 85,
        height: 85,
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
      File(
        activity.image,
      ),
      width: 85,
      height: 85,
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

  Widget _imageError() {
    return Container(
      width: 85,
      height: 85,
      color: const Color(
        0xFFEDE8FF,
      ),
      child: const Icon(
        Icons.image_outlined,
        color: Color(
          0xFF6C4DFF,
        ),
      ),
    );
  }
}

class _ProfileEditResult {
  final String name;
  final String bio;
  final String imagePath;

  const _ProfileEditResult({
    required this.name,
    required this.bio,
    required this.imagePath,
  });
}

class _EditProfilePage extends StatefulWidget {
  final String initialName;
  final String initialBio;
  final String initialImage;

  const _EditProfilePage({
    required this.initialName,
    required this.initialBio,
    required this.initialImage,
  });

  @override
  State<_EditProfilePage> createState() =>
      _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  final ImagePicker _picker = ImagePicker();

  bool _isSaving = false;
  late String _imagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialName,
    );
    _bioController = TextEditingController(
      text: widget.initialBio,
    );
    _imagePath = widget.initialImage;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null || !mounted) {
      return;
    }

    setState(() {
      _imagePath = image.path;
    });
  }

  Future<void> _save() async {
    if (_isSaving) {
      return;
    }

    final name = _nameController.text.trim();
    final bioText = _bioController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อ'),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final bio = bioText.isEmpty
          ? 'สมาชิก FindMate'
          : bioText;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'uid': user.uid,
          'name': name,
          'email': user.email ?? '',
          'bio': bio,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await user.updateDisplayName(name);

      if (!mounted) {
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();

      await Future<void>.delayed(
        const Duration(milliseconds: 120),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(
        _ProfileEditResult(
          name: name,
          bio: bio,
          imagePath: _imagePath,
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'บันทึกโปรไฟล์ไม่สำเร็จ: $e',
          ),
        ),
      );
    }
  }

  Widget _buildImage(double size) {
    if (_imagePath.isEmpty) {
      return _placeholder(size);
    }

    if (_imagePath.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          _imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _placeholder(size),
        ),
      );
    }

    return ClipOval(
      child: Image.file(
        File(_imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _placeholder(size),
      ),
    );
  }

  Widget _placeholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFEDE8FF),
        border: Border.all(
          color: const Color(0xFF6C4DFF),
          width: 3,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.58,
        color: const Color(0xFF6C4DFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'แก้ไขโปรไฟล์',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            20,
            24,
            20,
            24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'แก้ไขโปรไฟล์',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: GestureDetector(
                  onTap: _isSaving ? null : _pickImage,
                  child: Stack(
                    children: [
                      _buildImage(90),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C4DFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ชื่อ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _nameController,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'กรอกชื่อ',
                  prefixIcon: const Icon(
                    Icons.person_outline_rounded,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'แนะนำตัว',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _bioController,
                enabled: !_isSaving,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'เขียนแนะนำตัวสั้น ๆ',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.edit_note_rounded,
                    ),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FE),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF6C4DFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        const Color(0xFFB7AAFF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'บันทึกการเปลี่ยนแปลง',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

