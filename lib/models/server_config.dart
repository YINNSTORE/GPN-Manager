class ServerConfig {
  final String id;
  final String name;
  final String host;
  final String apiKey;
  final bool isActive;

  const ServerConfig({
    required this.id,
    required this.name,
    required this.host,
    required this.apiKey,
    required this.isActive,
  });

  String get baseUrl {
    final h = host.trim();
    if (h.startsWith('http://') || h.startsWith('https://')) {
      return '$h:8080';
    }
    return 'http://$h:8080';
  }

  ServerConfig copyWith({
    String? id,
    String? name,
    String? host,
    String? apiKey,
    bool? isActive,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      apiKey: apiKey ?? this.apiKey,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'apiKey': apiKey,
        'isActive': isActive,
      };

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      host: json['host'] ?? '',
      apiKey: json['apiKey'] ?? '',
      isActive: json['isActive'] ?? false,
    );
  }
}