enum BuildProfile {
  debug,
  release,
  workflowDefault,
}

extension BuildProfileLabel on BuildProfile {
  String get zhName {
    switch (this) {
      case BuildProfile.debug:
        return 'Debug 调试包';
      case BuildProfile.release:
        return 'Release 正式包';
      case BuildProfile.workflowDefault:
        return '跟随工作流默认配置';
    }
  }
}
