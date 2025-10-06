/// 메시지 발신자 타입
/// 
/// 채팅 메시지의 발신자를 구분하기 위한 enum
enum Sender {
  user("user"),
  bot("bot");

  final String dbValue;
  const Sender(this.dbValue);
}

