class ProjectIdentityConfig {
  final String appName;
  final String packageName;
  final String versionName;
  final int versionCode;
  final String? iconPath;

  const ProjectIdentityConfig({
    required this.appName,
    required this.packageName,
    required this.versionName,
    required this.versionCode,
    this.iconPath,
  });

  factory ProjectIdentityConfig.defaults() {
    return const ProjectIdentityConfig(
      appName: 'MoonXide App',
      packageName: 'com.example.moonxide_app',
      versionName: '1.0.0',
      versionCode: 1,
    );
  }

  ProjectIdentityConfig copyWith({
    String? appName,
    String? packageName,
    String? versionName,
    int? versionCode,
    String? iconPath,
  }) {
    return ProjectIdentityConfig(
      appName: appName ?? this.appName,
      packageName: packageName ?? this.packageName,
      versionName: versionName ?? this.versionName,
      versionCode: versionCode ?? this.versionCode,
      iconPath: iconPath ?? this.iconPath,
    );
  }

  Map<String, dynamic> toJson() => {
        'appName': appName,
        'packageName': packageName,
        'versionName': versionName,
        'versionCode': versionCode,
        'iconPath': iconPath,
      };

  factory ProjectIdentityConfig.fromJson(Map<String, dynamic> json) {
    return ProjectIdentityConfig(
      appName: (json['appName'] as String?)?.trim().isNotEmpty == true ? json['appName'] as String : 'MoonXide App',
      packageName: (json['packageName'] as String?)?.trim().isNotEmpty == true ? json['packageName'] as String : 'com.example.moonxide_app',
      versionName: (json['versionName'] as String?)?.trim().isNotEmpty == true ? json['versionName'] as String : '1.0.0',
      versionCode: json['versionCode'] is int ? json['versionCode'] as int : int.tryParse('${json['versionCode']}') ?? 1,
      iconPath: (json['iconPath'] as String?)?.trim().isNotEmpty == true ? json['iconPath'] as String : null,
    );
  }
}
