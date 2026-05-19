enum BuildProfile {
  debug,
  release,
}

extension BuildProfileLabel on BuildProfile {
  String get zhName {
    switch (this) {
      case BuildProfile.debug:
        return 'Debug 调试包';
      case BuildProfile.release:
        return 'Release 正式包';
    }
  }
}
