class UserItem {
  final String username;
  final String? expireAt;
  final String? status;
  final int? daysLeft;

  const UserItem({
    required this.username,
    this.expireAt,
    this.status,
    this.daysLeft,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      username: (json['username'] ??
              json['user'] ??
              json['password'] ??
              json['name'] ??
              '')
          .toString(),
      expireAt: json['expire_at']?.toString() ??
          json['expired_at']?.toString() ??
          json['expires_at']?.toString(),
      status: json['status']?.toString(),
      daysLeft: json['days_left'] is int
          ? json['days_left'] as int
          : int.tryParse('${json['days_left']}'),
    );
  }
}