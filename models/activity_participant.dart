class ActivityParticipant {
  final String uid;
  final String name;
  final bool isOwner;

  const ActivityParticipant({
    required this.uid,
    required this.name,
    required this.isOwner,
  });

  factory ActivityParticipant.fromMap(
      String uid,
      Map<String, dynamic> data,
      ) {
    return ActivityParticipant(
      uid: uid,
      name: data['name']?.toString().trim().isNotEmpty == true
          ? data['name'].toString()
          : 'ผู้ใช้ FindMate',
      isOwner: data['isOwner'] == true,
    );
  }
}