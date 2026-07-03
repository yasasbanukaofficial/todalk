class MockUser {
  final String name;
  final String email;
  final String avatarUrl;

  MockUser({
    required this.name,
    required this.email,
    this.avatarUrl = '',
  });
}
