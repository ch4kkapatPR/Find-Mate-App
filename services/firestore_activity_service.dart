import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/activity_item.dart';
import '../models/activity_participant.dart';

class FirestoreActivityService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get uid => _auth.currentUser?.uid;

  // =========================================================
  // Parse date/time
  // =========================================================

  static DateTime? _parseActivityDate(String dateText) {
    final value = dateText.trim();
    if (value.isEmpty) return null;

    try {
      final thaiParts = value.split(RegExp(r'\s+'));
      if (thaiParts.length >= 3) {
        const months = <String, int>{
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

        final day = int.tryParse(thaiParts[0]);
        final month = months[thaiParts[1]];
        var year = int.tryParse(thaiParts[2]);

        if (day != null && month != null && year != null) {
          if (year > 2400) year -= 543;
          return DateTime(year, month, day);
        }
      }

      final normalized = value.replaceAll('-', '/');
      final parts = normalized.split('/');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0].trim());
      final month = int.tryParse(parts[1].trim());
      var year = int.tryParse(parts[2].trim());

      if (day == null || month == null || year == null) return null;
      if (year > 2400) year -= 543;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  static ({int hour, int minute})? _parseActivityTime(String timeText) {
    final value = timeText.trim();
    if (value.isEmpty) return null;

    final match = RegExp(r'(\d{1,2})\s*:\s*(\d{2})').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');

    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    return (hour: hour, minute: minute);
  }

  static DateTime? _combineDateAndTime(String dateText, String timeText) {
    final date = _parseActivityDate(dateText);
    final time = _parseActivityTime(timeText);
    if (date == null || time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static DateTime? _eventStartFromData(Map<String, dynamic> data) {
    final eventStartAt = data['eventStartAt'];
    if (eventStartAt is Timestamp) {
      return eventStartAt.toDate().toLocal();
    }

    return _combineDateAndTime(
      data['dateText']?.toString() ?? '',
      data['timeText']?.toString() ?? '',
    );
  }

  static DateTime? _eventEndFromData(Map<String, dynamic> data) {
    final eventEndAt = data['eventEndAt'];
    if (eventEndAt is Timestamp) {
      return eventEndAt.toDate().toLocal();
    }

    return _combineDateAndTime(
      data['dateText']?.toString() ?? '',
      data['endTimeText']?.toString() ?? '',
    );
  }

  static DateTime? _eventDateFromData(Map<String, dynamic> data) {
    final eventDate = data['eventDate'];
    if (eventDate is Timestamp) {
      return eventDate.toDate().toLocal();
    }

    return _parseActivityDate(data['dateText']?.toString() ?? '');
  }

  static bool _hasStarted(Map<String, dynamic> data) {
    final start = _eventStartFromData(data);
    if (start == null) return false;
    return !DateTime.now().isBefore(start);
  }

  static bool _isExpired(Map<String, dynamic> data) {
    final end = _eventEndFromData(data);
    if (end != null) {
      return !DateTime.now().isBefore(end);
    }

    final activityDate = _eventDateFromData(data);
    if (activityDate == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      activityDate.year,
      activityDate.month,
      activityDate.day,
    );

    return eventDay.isBefore(today);
  }

  // =========================================================
  // Create Activity
  // =========================================================

  static Future<String> createActivity(ActivityItem activity) async {
    final currentUid = uid;
    if (currentUid == null) {
      throw Exception('กรุณาเข้าสู่ระบบ');
    }

    final currentUser = _auth.currentUser;
    final userName = currentUser?.displayName?.trim().isNotEmpty == true
        ? currentUser!.displayName!.trim()
        : 'ผู้ใช้ FindMate';

    final startAt = _combineDateAndTime(activity.dateText, activity.timeText);
    final endAt = _combineDateAndTime(activity.dateText, activity.endTimeText);

    if (startAt == null) {
      throw Exception('ไม่สามารถอ่านวันที่หรือเวลาเริ่มกิจกรรมได้');
    }

    if (endAt == null) {
      throw Exception('ไม่สามารถอ่านเวลาสิ้นสุดกิจกรรมได้');
    }

    if (!endAt.isAfter(startAt)) {
      throw Exception('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม');
    }

    final activityRef = _firestore.collection('activities').doc();
    final participantRef = activityRef.collection('participants').doc(currentUid);
    final batch = _firestore.batch();

    batch.set(activityRef, {
      ...activity.toMap(),
      'ownerId': currentUid,
      'ownerName': userName,
      'joined': 1,
      'eventDate': Timestamp.fromDate(
        DateTime(startAt.year, startAt.month, startAt.day),
      ),
      'eventStartAt': Timestamp.fromDate(startAt),
      'eventEndAt': Timestamp.fromDate(endAt),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    batch.set(participantRef, {
      'uid': currentUid,
      'name': userName,
      'isOwner': true,
      'joinedAt': FieldValue.serverTimestamp(),
      'lastReadAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
    return activityRef.id;
  }

  // =========================================================
  // Activities Stream
  // =========================================================

  static Stream<List<ActivityItem>> getActivitiesStream({
    bool includeExpired = false,
  }) {
    final currentUid = uid;

    return _firestore.collection('activities').snapshots().asyncMap((snapshot) async {
      final activities = <ActivityItem>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (!includeExpired && _isExpired(data)) {
          continue;
        }

        var isJoined = false;
        if (currentUid != null) {
          try {
            final participantDoc = await doc.reference
                .collection('participants')
                .doc(currentUid)
                .get();
            isJoined = participantDoc.exists;
          } catch (_) {
            isJoined = false;
          }
        }

        activities.add(
          ActivityItem.fromMap(
            doc.id,
            data,
            isOwner: currentUid != null && data['ownerId'] == currentUid,
            isJoined: isJoined,
          ),
        );
      }

      activities.sort((a, b) {
        final startA = _combineDateAndTime(a.dateText, a.timeText) ??
            _parseActivityDate(a.dateText);
        final startB = _combineDateAndTime(b.dateText, b.timeText) ??
            _parseActivityDate(b.dateText);

        if (startA == null && startB == null) return 0;
        if (startA == null) return 1;
        if (startB == null) return -1;
        return startA.compareTo(startB);
      });

      return activities;
    });
  }

  // =========================================================
  // Get Activity Once
  // =========================================================

  static Future<ActivityItem?> getActivity(String activityId) async {
    if (activityId.isEmpty) return null;

    final currentUid = uid;
    final ref = _firestore.collection('activities').doc(activityId);
    final snapshot = await ref.get();

    if (!snapshot.exists) return null;
    final data = snapshot.data();
    if (data == null) return null;

    var isJoined = false;
    if (currentUid != null) {
      final participant = await ref.collection('participants').doc(currentUid).get();
      isJoined = participant.exists;
    }

    return ActivityItem.fromMap(
      snapshot.id,
      data,
      isOwner: currentUid != null && data['ownerId'] == currentUid,
      isJoined: isJoined,
    );
  }

  // =========================================================
  // Activity Stream
  // =========================================================

  static Stream<ActivityItem?> getActivityStream(String activityId) {
    if (activityId.isEmpty) return Stream.value(null);

    final currentUid = uid;
    final activityRef = _firestore.collection('activities').doc(activityId);

    return activityRef.snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;

      var isJoined = false;
      if (currentUid != null) {
        try {
          final participant = await activityRef
              .collection('participants')
              .doc(currentUid)
              .get();
          isJoined = participant.exists;
        } catch (_) {
          isJoined = false;
        }
      }

      return ActivityItem.fromMap(
        snapshot.id,
        data,
        isOwner: currentUid != null && data['ownerId'] == currentUid,
        isJoined: isJoined,
      );
    });
  }

  // =========================================================
  // Update Activity
  // =========================================================

  static Future<void> updateActivity(ActivityItem activity) async {
    final currentUid = uid;
    if (currentUid == null) {
      throw Exception('กรุณาเข้าสู่ระบบ');
    }

    if (activity.id.isEmpty) {
      throw Exception('ไม่พบ Activity ID');
    }

    final activityRef = _firestore.collection('activities').doc(activity.id);
    final snapshot = await activityRef.get();

    if (!snapshot.exists) {
      throw Exception('ไม่พบกิจกรรมนี้');
    }

    final data = snapshot.data();
    if (data == null) {
      throw Exception('ไม่พบข้อมูลกิจกรรม');
    }

    if (data['ownerId'] != currentUid) {
      throw Exception('เฉพาะเจ้าของกิจกรรมเท่านั้นที่แก้ไขได้');
    }

    final currentJoined = data['joined'] is int
        ? data['joined'] as int
        : int.tryParse('${data['joined']}') ?? 1;

    if (activity.total < currentJoined) {
      throw Exception('จำนวนรับทั้งหมดต้องไม่น้อยกว่า $currentJoined คน');
    }

    final startAt = _combineDateAndTime(activity.dateText, activity.timeText);
    final endAt = _combineDateAndTime(activity.dateText, activity.endTimeText);

    if (startAt == null || endAt == null) {
      throw Exception('วันที่หรือเวลาของกิจกรรมไม่ถูกต้อง');
    }

    if (!endAt.isAfter(startAt)) {
      throw Exception('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม');
    }

    await activityRef.update({
      'title': activity.title,
      'category': activity.category,
      'total': activity.total,
      'dateText': activity.dateText,
      'timeText': activity.timeText,
      'endTimeText': activity.endTimeText,
      'location': activity.location,
      'image': activity.image,
      'description': activity.description,
      'images': activity.images,
      'eventDate': Timestamp.fromDate(
        DateTime(startAt.year, startAt.month, startAt.day),
      ),
      'eventStartAt': Timestamp.fromDate(startAt),
      'eventEndAt': Timestamp.fromDate(endAt),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // =========================================================
  // Delete Activity
  // =========================================================

  static Future<void> deleteActivity(ActivityItem activity) async {
    final currentUid = uid;
    if (currentUid == null) {
      throw Exception('กรุณาเข้าสู่ระบบ');
    }

    if (activity.id.isEmpty) {
      throw Exception('ไม่พบ Activity ID');
    }

    final activityRef = _firestore.collection('activities').doc(activity.id);
    final activitySnapshot = await activityRef.get();

    if (!activitySnapshot.exists) {
      throw Exception('ไม่พบกิจกรรมนี้');
    }

    final data = activitySnapshot.data();
    if (data == null) {
      throw Exception('ไม่พบข้อมูลกิจกรรม');
    }

    final ownerId = data['ownerId']?.toString() ?? '';
    if (ownerId != currentUid) {
      throw Exception('เฉพาะเจ้าของกิจกรรมเท่านั้นที่ลบได้');
    }

    await _deleteSubCollection(activityRef.collection('participants'));
    await _deleteSubCollection(activityRef.collection('messages'));
    await activityRef.delete();
  }

  static Future<void> _deleteSubCollection(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    const batchSize = 400;

    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      if (snapshot.docs.length < batchSize) break;
    }
  }

  // =========================================================
  // Join Activity
  // =========================================================

  static Future<void> joinActivity(ActivityItem activity) async {
    final currentUid = uid;
    if (currentUid == null) {
      throw Exception('กรุณาเข้าสู่ระบบ');
    }

    if (activity.id.isEmpty) {
      throw Exception('ไม่พบ Activity ID');
    }

    final user = _auth.currentUser;
    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : 'ผู้ใช้ FindMate';

    final activityRef = _firestore.collection('activities').doc(activity.id);
    final participantRef = activityRef.collection('participants').doc(currentUid);

    await _firestore.runTransaction((transaction) async {
      final activitySnapshot = await transaction.get(activityRef);
      if (!activitySnapshot.exists) {
        throw Exception('ไม่พบกิจกรรมนี้');
      }

      final data = activitySnapshot.data();
      if (data == null) {
        throw Exception('ไม่พบข้อมูลกิจกรรม');
      }

      if (_isExpired(data)) {
        throw Exception('กิจกรรมนี้สิ้นสุดแล้ว');
      }

      if (_hasStarted(data)) {
        throw Exception('กิจกรรมนี้เริ่มแล้ว ไม่สามารถเข้าร่วมเพิ่มได้');
      }

      final participantSnapshot = await transaction.get(participantRef);
      if (participantSnapshot.exists) {
        throw Exception('คุณเข้าร่วมกิจกรรมนี้แล้ว');
      }

      final joined = data['joined'] is int
          ? data['joined'] as int
          : int.tryParse('${data['joined']}') ?? 0;

      final total = data['total'] is int
          ? data['total'] as int
          : int.tryParse('${data['total']}') ?? 0;

      if (joined >= total) {
        throw Exception('กิจกรรมเต็มแล้ว');
      }

      transaction.set(participantRef, {
        'uid': currentUid,
        'name': userName,
        'isOwner': false,
        'joinedAt': FieldValue.serverTimestamp(),
        'lastReadAt': FieldValue.serverTimestamp(),
      });

      transaction.update(activityRef, {
        'joined': joined + 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================
  // Leave Activity
  // =========================================================

  static Future<void> leaveActivity(ActivityItem activity) async {
    final currentUid = uid;
    if (currentUid == null) {
      throw Exception('กรุณาเข้าสู่ระบบ');
    }

    if (activity.id.isEmpty) {
      throw Exception('ไม่พบ Activity ID');
    }

    final activityRef = _firestore.collection('activities').doc(activity.id);
    final participantRef = activityRef.collection('participants').doc(currentUid);

    await _firestore.runTransaction((transaction) async {
      final activitySnapshot = await transaction.get(activityRef);
      if (!activitySnapshot.exists) {
        throw Exception('ไม่พบกิจกรรมนี้');
      }

      final data = activitySnapshot.data();
      if (data == null) {
        throw Exception('ไม่พบข้อมูลกิจกรรม');
      }

      if (data['ownerId'] == currentUid) {
        throw Exception('เจ้าของกิจกรรมไม่สามารถออกจากกิจกรรมของตัวเองได้');
      }

      final participantSnapshot = await transaction.get(participantRef);
      if (!participantSnapshot.exists) {
        throw Exception('คุณยังไม่ได้เข้าร่วมกิจกรรมนี้');
      }

      final joined = data['joined'] is int
          ? data['joined'] as int
          : int.tryParse('${data['joined']}') ?? 1;

      transaction.delete(participantRef);
      transaction.update(activityRef, {
        'joined': joined > 1 ? joined - 1 : 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // =========================================================
  // Participants Stream
  // =========================================================

  static Stream<List<ActivityParticipant>> getParticipantsStream(
      String activityId,
      ) {
    if (activityId.isEmpty) {
      return Stream.value(<ActivityParticipant>[]);
    }

    return _firestore
        .collection('activities')
        .doc(activityId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      final participants = snapshot.docs
          .map((doc) => ActivityParticipant.fromMap(doc.id, doc.data()))
          .toList();

      participants.sort((a, b) {
        if (a.isOwner && !b.isOwner) return -1;
        if (!a.isOwner && b.isOwner) return 1;
        return 0;
      });

      return participants;
    });
  }

  // =========================================================
  // Mark Chat As Read
  // =========================================================

  static Future<void> markChatAsRead(String activityId) async {
    final currentUid = uid;
    if (currentUid == null || activityId.isEmpty) return;

    final participantRef = _firestore
        .collection('activities')
        .doc(activityId)
        .collection('participants')
        .doc(currentUid);

    final snapshot = await participantRef.get();
    if (!snapshot.exists) return;

    await participantRef.update({
      'lastReadAt': FieldValue.serverTimestamp(),
    });
  }
}
