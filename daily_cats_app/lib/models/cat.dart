//models/cat.dart
class Cat {
  final String id;
  final String name;
  final String title;
  final String link;
  final int likeCount;
  final int replyCount;
  final DateTime created;

  Cat({
    required this.id,
    required this.name,
    required this.title,
    required this.link,
    required this.likeCount,
    required this.replyCount,
    required this.created,
  });
}
