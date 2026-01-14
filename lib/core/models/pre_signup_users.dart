class PreSignupUsers {
  PreSignupUsers({required this.token, required this.email});
  final String token;
  final String email;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {'token': token, 'email': email};
    return data;
  }
}
