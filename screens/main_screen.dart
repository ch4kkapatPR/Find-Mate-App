import 'package:flutter/material.dart';

import '../models/activity_item.dart';
import '../services/firestore_activity_service.dart';

import 'chat_page.dart';
import 'create_post_page.dart';
import 'explore_page.dart';
import 'home_page.dart';
import 'profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // =========================================================
  // OPEN CREATE POST
  // =========================================================

  Future<void> _openCreatePost() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreatePostPage(),
      ),
    );

    // Firestore Stream จะอัปเดตข้อมูลเอง
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityItem>>(
      stream: FirestoreActivityService.getActivitiesStream(),
      builder: (
          context,
          snapshot,
          ) {
        // =====================================================
        // ERROR
        // =====================================================

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(
              0xFFF8F9FE,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  30,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 60,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    const Text(
                      'ไม่สามารถโหลดกิจกรรมได้',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // =====================================================
        // LOADING
        // =====================================================

        if (snapshot.connectionState ==
            ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(
              0xFFF8F9FE,
            ),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(
                  0xFF6C4DFF,
                ),
              ),
            ),
          );
        }

        // =====================================================
        // ACTIVITIES
        // =====================================================

        final List<ActivityItem> activities =
            snapshot.data ?? <ActivityItem>[];

        // ระบุ List<Widget> ชัดเจน
        final List<Widget> pages = <Widget>[
          HomePage(
            activities: activities,
          ),
          ExplorePage(
            activities: activities,
          ),
          const ChatPage(),
          const ProfilePage(),
        ];

        return Scaffold(
          backgroundColor: const Color(
            0xFFF8F9FE,
          ),

          // ===================================================
          // PAGE
          // ===================================================

          body: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),

          // ===================================================
          // CREATE ACTIVITY BUTTON
          // ===================================================

          floatingActionButton: FloatingActionButton(
            elevation: 10,
            backgroundColor: const Color(
              0xFF6C4DFF,
            ),
            shape: const CircleBorder(),
            onPressed: _openCreatePost,
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 30,
            ),
          ),

          floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,

          // ===================================================
          // BOTTOM NAVIGATION
          // ===================================================

          bottomNavigationBar: BottomAppBar(
            color: Colors.white,
            padding: EdgeInsets.zero,
            notchMargin: 8,
            shape: const CircularNotchedRectangle(),
            child: SizedBox(
              height: 70,
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceAround,
                children: [
                  _navItem(
                    icon: Icons.home_rounded,
                    label: 'หน้าแรก',
                    index: 0,
                  ),

                  _navItem(
                    icon: Icons.explore_outlined,
                    label: 'สำรวจ',
                    index: 1,
                  ),

                  const SizedBox(
                    width: 40,
                  ),

                  _navItem(
                    icon:
                    Icons.chat_bubble_outline_rounded,
                    label: 'แชท',
                    index: 2,
                  ),

                  _navItem(
                    icon: Icons.person_rounded,
                    label: 'โปรไฟล์',
                    index: 3,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // NAV ITEM
  // =========================================================

  Widget _navItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final bool selected =
        _selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(
        15,
      ),
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 27,
              color: selected
                  ? const Color(
                0xFF6C4DFF,
              )
                  : Colors.grey[400],
            ),

            const SizedBox(
              height: 3,
            ),

            Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(
                  0xFF6C4DFF,
                )
                    : Colors.grey[400],
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}