class Profile {
  final String id;
  final String name;
  final String? email;

  // 1️⃣ 생성자 위치 매개변수
  // Profile(this.id, this.name, this.email);

  // 2️⃣ 생성자 이름 매개변수
  Profile({
    required this.id,
    required this.name,
    this.email,
  });
  
}