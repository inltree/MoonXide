import 'package:url_launcher/url_launcher.dart';

class AndroidInstaller {
  Future<void> openApk(String localPath) async {
    final uri = Uri.file(localPath);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('无法打开安装器：$localPath');
    }
  }
}