import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final DateTime startAt;
  final DateTime endAt;
  final Duration duration;
  final int xpAwarded;
  final DateTime createdAt;
  final String? topicId;
  final String? topicName;
  final String sessionType; // 'focus', 'short_break', 'long_break'

  const SessionModel({
    required this.id,
    required this.userId,
    required this.startAt,
    required this.endAt,
    required this.duration,
    required this.xpAwarded,
    required this.createdAt,
    this.topicId,
    this.topicName,
    this.sessionType = 'focus',
  });

  factory SessionModel.fromMap(Map<String, dynamic> map, String id) {
    return SessionModel(
      id: map['id'] as String? ?? id,
      userId: map['userId'] as String? ?? '',
      startAt: map['startAt'] != null
          ? (map['startAt'] as Timestamp).toDate()
          : DateTime.now(),
      endAt: map['endAt'] != null
          ? (map['endAt'] as Timestamp).toDate()
          : DateTime.now(),
      duration: Duration(seconds: map['duration'] as int? ?? 0),
      xpAwarded: map['xpAwarded'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      topicId: map['topicId'] as String?,
      topicName: map['topicName'] as String?,
      sessionType: map['sessionType'] as String? ?? 'focus',
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'startAt': Timestamp.fromDate(startAt),
      'endAt': Timestamp.fromDate(endAt),
      'duration': duration.inSeconds,
      'xpAwarded': xpAwarded,
      'createdAt': Timestamp.fromDate(createdAt),
      'topicId': topicId,
      'topicName': topicName,
      'sessionType': sessionType,
    };
  }

  @override
  String toString() {
    return 'SessionModel(id: $id, userId: $userId, startAt: $startAt, endAt: $endAt, duration: $duration, xpAwarded: $xpAwarded, createdAt: $createdAt, topicId: $topicId, topicName: $topicName, sessionType: $sessionType)';
  }
}
