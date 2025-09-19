enum Sender { user, bot }

enum ChatType { normal, solution }

class Chat {
  final String id;
  final String userId;
  final String content;
  final Sender sender;
  final ChatType type;
  final DateTime createdAt;

  Chat({
    required this.id,
    required this.userId,
    required this.content,
    required this.sender,
    required this.type,
    required this.createdAt,
  });
}
