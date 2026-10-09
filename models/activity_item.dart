class ActivityItem {
  final String id;
  final String ownerId;
  final String ownerName;

  final String title;
  final String category;

  final int joined;
  final int total;

  final String dateText;
  final String timeText;
  final String endTimeText;

  final String location;
  final String image;
  final String description;

  final List<String> images;

  final bool isOwner;
  final bool isJoined;

  const ActivityItem({
    this.id = '',
    this.ownerId = '',
    this.ownerName = '',
    required this.title,
    required this.category,
    required this.joined,
    required this.total,
    required this.dateText,
    required this.timeText,
    this.endTimeText = '',
    required this.location,
    required this.image,
    required this.description,
    this.images = const [],
    this.isOwner = false,
    this.isJoined = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'category': category,
      'joined': joined,
      'total': total,
      'dateText': dateText,
      'timeText': timeText,
      'endTimeText': endTimeText,
      'location': location,
      'image': image,
      'description': description,
      'images': images,
    };
  }

  factory ActivityItem.fromMap(
    String id,
    Map<String, dynamic> data, {
    bool isOwner = false,
    bool isJoined = false,
  }) {
    return ActivityItem(
      id: id,
      ownerId:
          data['ownerId']?.toString() ?? '',
      ownerName:
          data['ownerName']?.toString() ?? '',
      title:
          data['title']?.toString() ?? '',
      category:
          data['category']?.toString() ?? '',
      joined: data['joined'] is int
          ? data['joined'] as int
          : int.tryParse(
                '${data['joined']}',
              ) ??
              0,
      total: data['total'] is int
          ? data['total'] as int
          : int.tryParse(
                '${data['total']}',
              ) ??
              0,
      dateText:
          data['dateText']?.toString() ?? '',
      timeText:
          data['timeText']?.toString() ?? '',
      endTimeText:
          data['endTimeText']?.toString() ?? '',
      location:
          data['location']?.toString() ?? '',
      image:
          data['image']?.toString() ?? '',
      description:
          data['description']?.toString() ?? '',
      images: List<String>.from(
        data['images'] ?? const [],
      ),
      isOwner: isOwner,
      isJoined: isJoined,
    );
  }

  ActivityItem copyWith({
    String? id,
    String? ownerId,
    String? ownerName,
    String? title,
    String? category,
    int? joined,
    int? total,
    String? dateText,
    String? timeText,
    String? endTimeText,
    String? location,
    String? image,
    String? description,
    List<String>? images,
    bool? isOwner,
    bool? isJoined,
  }) {
    return ActivityItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      title: title ?? this.title,
      category:
          category ?? this.category,
      joined: joined ?? this.joined,
      total: total ?? this.total,
      dateText:
          dateText ?? this.dateText,
      timeText:
          timeText ?? this.timeText,
      endTimeText:
          endTimeText ?? this.endTimeText,
      location:
          location ?? this.location,
      image: image ?? this.image,
      description:
          description ?? this.description,
      images: images ?? this.images,
      isOwner:
          isOwner ?? this.isOwner,
      isJoined:
          isJoined ?? this.isJoined,
    );
  }
}
