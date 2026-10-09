import '../models/activity_item.dart';

class ActivityService {
  static final List<ActivityItem> activities = [
    const ActivityItem(
      title: 'เดินป่าเขาใหญ่',
      category: 'เดินป่า',
      joined: 5,
      total: 6,
      dateText: '18 พ.ค. 2567',
      timeText: '07:00',
      location: 'อุทยานแห่งชาติเขาใหญ่',
      image:
      'https://images.unsplash.com/photo-1551632811-561732d1e306?q=80&w=1200&auto=format&fit=crop',
      description:
      'มาเดินป่าชมธรรมชาติที่เขาใหญ่กันครับ เส้นทางเดินง่าย บรรยากาศดีมาก',
    ),
    const ActivityItem(
      title: 'บาสเกตบอลชิลๆ',
      category: 'กีฬา',
      joined: 3,
      total: 5,
      dateText: '20 พ.ค. 2567',
      timeText: '18:00',
      location: 'สนามบาส ราชเทวี',
      image:
      'https://images.unsplash.com/photo-1546519638-68e109498ffc?q=80&w=1200&auto=format&fit=crop',
      description:
      'หาคนมาเล่นบาสด้วยกัน เน้นสนุกสนาน ออกกำลังกายตอนเย็นครับ',
    ),
  ];

  // กิจกรรมที่ผู้ใช้เข้าร่วม
  static final List<String> joinedActivities = [];

  // รายชื่อผู้เข้าร่วมของแต่ละกิจกรรม
  static final Map<String, List<String>> participants = {
    'เดินป่าเขาใหญ่': ['Mimoo', 'Mind', 'Top', 'Jane', 'Ping'],
    'บาสเกตบอลชิลๆ': ['Mimoo', 'Mind', 'Top'],
  };

  // ชื่อผู้ใช้ปัจจุบัน
  static const String currentUser = 'คุณ';

  static List<ActivityItem> getActivities() {
    return activities;
  }

  // เพิ่มกิจกรรมใหม่
  static void addActivity(ActivityItem activity) {
    activities.insert(0, activity);

    // เจ้าของกิจกรรมถือว่าเข้าร่วมกิจกรรมแล้ว
    participants[activity.title] = [currentUser];

    if (!joinedActivities.contains(activity.title)) {
      joinedActivities.add(activity.title);
    }
  }

  // ตรวจสอบว่าผู้ใช้เข้าร่วมกิจกรรมหรือยัง
  static bool hasJoined(ActivityItem activity) {
    return joinedActivities.contains(activity.title);
  }

  // เข้าร่วมกิจกรรม
  static bool joinActivity(ActivityItem activity) {
    final index = activities.indexWhere(
          (item) => item.title == activity.title,
    );

    if (index == -1) return false;
    if (hasJoined(activity)) return false;

    final currentActivity = activities[index];

    if (currentActivity.joined >= currentActivity.total) {
      return false;
    }

    activities[index] = ActivityItem(
      title: currentActivity.title,
      category: currentActivity.category,
      joined: currentActivity.joined + 1,
      total: currentActivity.total,
      dateText: currentActivity.dateText,
      timeText: currentActivity.timeText,
      location: currentActivity.location,
      image: currentActivity.image,
      description: currentActivity.description,
      images: currentActivity.images,
      isOwner: currentActivity.isOwner,
    );

    joinedActivities.add(activity.title);

    participants.putIfAbsent(
      activity.title,
          () => [],
    );

    if (!participants[activity.title]!.contains(currentUser)) {
      participants[activity.title]!.add(currentUser);
    }

    return true;
  }

  // ออกจากกิจกรรม
  static bool leaveActivity(ActivityItem activity) {
    final index = activities.indexWhere(
          (item) => item.title == activity.title,
    );

    if (index == -1) return false;
    if (!hasJoined(activity)) return false;

    final currentActivity = activities[index];

    if (currentActivity.joined <= 0) {
      return false;
    }

    // เจ้าของกิจกรรมไม่สามารถกดออกจากกิจกรรมของตัวเอง
    if (currentActivity.isOwner) {
      return false;
    }

    activities[index] = ActivityItem(
      title: currentActivity.title,
      category: currentActivity.category,
      joined: currentActivity.joined - 1,
      total: currentActivity.total,
      dateText: currentActivity.dateText,
      timeText: currentActivity.timeText,
      location: currentActivity.location,
      image: currentActivity.image,
      description: currentActivity.description,
      images: currentActivity.images,
      isOwner: currentActivity.isOwner,
    );

    joinedActivities.remove(activity.title);
    participants[activity.title]?.remove(currentUser);

    return true;
  }

  // ดึงรายชื่อผู้เข้าร่วม
  static List<String> getParticipants(ActivityItem activity) {
    return List<String>.from(
      participants[activity.title] ?? [],
    );
  }

  // ตรวจสอบว่าเป็นเจ้าของกิจกรรมหรือไม่
  static bool isOwner(ActivityItem activity) {
    return activity.isOwner;
  }

  // แก้ไขกิจกรรม
  static bool updateActivity({
    required String oldTitle,
    required ActivityItem newActivity,
  }) {
    final index = activities.indexWhere(
          (item) => item.title == oldTitle,
    );

    if (index == -1) {
      return false;
    }

    // ย้ายรายชื่อผู้เข้าร่วมไปใช้ชื่อใหม่
    final oldParticipants =
        participants.remove(oldTitle) ?? [currentUser];

    participants[newActivity.title] = oldParticipants;

    // ถ้าชื่อกิจกรรมเปลี่ยน ต้องเปลี่ยนชื่อใน joinedActivities ด้วย
    final joinedIndex = joinedActivities.indexOf(oldTitle);

    if (joinedIndex != -1) {
      joinedActivities[joinedIndex] = newActivity.title;
    }

    activities[index] = newActivity;

    return true;
  }

  // ลบกิจกรรม
  static bool deleteActivity(ActivityItem activity) {
    final index = activities.indexWhere(
          (item) => item.title == activity.title,
    );

    if (index == -1) {
      return false;
    }

    // ลบข้อมูลผู้เข้าร่วม
    participants.remove(activity.title);

    // ลบจากกิจกรรมที่เข้าร่วม
    joinedActivities.remove(activity.title);

    // ลบกิจกรรม
    activities.removeAt(index);

    return true;
  }
}