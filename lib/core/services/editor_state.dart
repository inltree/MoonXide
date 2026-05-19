import 'package:flutter/foundation.dart';

class EditorState extends ChangeNotifier {
  String currentPath = '';
  String currentContent = '';
  bool modified = false;
  String searchText = '';
  String replaceText = '';

  void openFile(String path, String content) {
    currentPath = path;
    currentContent = content;
    modified = false;
    notifyListeners();
  }

  void updateContent(String value) {
    currentContent = value;
    modified = true;
    notifyListeners();
  }

  void setSearch(String value) {
    searchText = value;
    notifyListeners();
  }

  void setReplace(String value) {
    replaceText = value;
    notifyListeners();
  }
}