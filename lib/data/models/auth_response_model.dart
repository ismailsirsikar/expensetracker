class AuthResponseModel {
  final String accessToken;
  final String refreshToken;
  final DateTime? expiresAt;

  AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expiresIn'];
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: expiresIn != null
          ? DateTime.now().add(Duration(seconds: (expiresIn as num).toInt()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      if (expiresAt != null) 'expiresAt': expiresAt!.toIso8601String(),
    };
  }
}
