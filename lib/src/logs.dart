

import 'dart:io';


class Log {
  var archiveFolder;
  var fileName;
  var maxLogFileSize;
  var archiveFileTimeLength;
  void Function(dynamic error)? onError;
  final File _file;
  late final RandomAccessFile _writer;


  Log({
    this.fileName = 'log.txt',
    this.archiveFolder = 'log_archive\\',
    this.maxLogFileSize = 8388608,
    this.archiveFileTimeLength = 21,
    this.onError
  }): _file = File(fileName) {
    try {
      _writer = _file.openSync(mode: FileMode.writeOnlyAppend);
    } catch(error) {
      if (onError == null) {
        Exception(error);
      } else {
        onError?.call(error);
      }
    }
  }


  void log(dynamic data, {
    bool showTime = true,
    int timeLength = 23,
    String afterTime = '  ',
    bool toConsole = true,
    bool toFile = true
  }) {
    try {
      var s = '';
      if (showTime) {
        s = timeString(timeLength) + afterTime;
      }
      s += data.toString();
      if (toConsole) print(s);
      if (toFile) _writer.writeStringSync(s + '\n');
      _logToArchive();
    } catch(error) {
      if (onError == null) {
        throw Exception(error);
      } else {
        onError?.call(error);
      }
    }
  }


  void _logToArchive() {
    if (_file.lengthSync() >= maxLogFileSize) {
      var time = timeString(archiveFileTimeLength);
      _file.copySync(archiveFolder + time + ' - ' + fileName);
      _writer.setPositionSync(0);
      _writer.truncateSync(0);
    }
  }


  String timeString(int length) =>
    DateTime.now().toString().substring(0, length).replaceAll(':', '.');
}