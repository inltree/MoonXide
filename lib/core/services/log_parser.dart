class LogParser {
  String summarize(String log) {
    final lines = log.split('\n');
    final important = lines.where((l) {
      final lower = l.toLowerCase();
      return lower.contains('error') || lower.contains('exception') || lower.contains('failed') || lower.contains('what went wrong') || lower.contains('compilation failed');
    }).take(80).join('\n');
    return important.isEmpty ? '未提取到明确错误，请查看完整日志。' : important;
  }
}