import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'chat_message_record.dart';

class ChatMemoryFileStore {
  Future<File> fileFor(String conversationId) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/moonxide_chat_memory');
    if (!await folder.exists()) await folder.create(recursive: true);
    return File('${folder.path}/$conversationId.txt');
  }

  Future<String> read(String conversationId) async {
    final file = await fileFor(conversationId);
    if (!await file.exists()) return '';
    return file.readAsString();
  }

  Future<void> writeAll(String conversationId, List<ChatMessageRecord> messages, {String summary = ''}) async {
    final file = await fileFor(conversationId);
    final buffer = StringBuffer();
    if (summary.trim().isNotEmpty) {
      buffer.writeln('# 压缩摘要');
      buffer.writeln(summary.trim());
      buffer.writeln('---');
    }
    for (final m in messages) {
      buffer.writeln(m.toTxtBlock());
    }
    await file.writeAsString(buffer.toString(), flush: true);
  }

  Future<void> append(String conversationId, ChatMessageRecord message) async {
    final file = await fileFor(conversationId);
    await file.writeAsString('${message.toTxtBlock()}\n', mode: FileMode.append, flush: true);
  }
}