import 'package:flutter/foundation.dart';

class BuildCenterState extends ChangeNotifier {
  String status = '未开始';
  String? logText;
  String? artifactLocalPath;
  String? artifactDownloadUrl;
  bool busy = false;

  void setStatus(String value) {
    status = value;
    notifyListeners();
  }

  void setLog(String? value) {
    logText = value;
    notifyListeners();
  }

  void setArtifact({String? localPath, String? downloadUrl}) {
    artifactLocalPath = localPath;
    artifactDownloadUrl = downloadUrl;
    notifyListeners();
  }
}