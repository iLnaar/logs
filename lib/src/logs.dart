

import 'dart:io';


class Log {
  String archiveFolder;
  String fileName;
  int maxLogFileSize;
  int maxBufferSize;
  var archiveFileTimeLength;
  late int _fileSize;
  var _buffer = '';
  void Function(dynamic error)? onError;
  final File _file;
  late final RandomAccessFile _writer;


  Log({
    this.fileName = 'program.log',
    this.archiveFolder = 'log_archive\\',
    this.maxLogFileSize = 8388608,
    this.maxBufferSize = 32768,
    this.archiveFileTimeLength = 21,
    this.onError
  }): _file = File(fileName) {
    try {
      _writer = _file.openSync(mode: FileMode.writeOnlyAppend);
      _fileSize = _file.lengthSync();
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
    bool toFile = true,
    bool immediatelyToFile = false
  }) {
    try {
      var s = '';
      if (showTime) {
        s = timeString(timeLength) + afterTime;
      }
      s += data.toString();
      if (toConsole) print(s);
      if (toFile) {
        _buffer += (s + '\n');
        if (immediatelyToFile || _buffer.length >= maxBufferSize) {
          _writer.writeStringSync(_buffer);
          _fileSize += _buffer.length;
          _buffer = '';
        }
        _logToArchive();
      }
    } catch(error) {
      if (onError == null) {
        throw Exception(error);
      } else {
        onError?.call(error);
      }
    }
  }


  void _logToArchive() {
    if (_fileSize >= maxLogFileSize) {
      var time = timeString(archiveFileTimeLength);
      _file.copySync(archiveFolder + time + ' - ' + fileName);
      _writer.setPositionSync(0);
      _writer.truncateSync(0);
      _fileSize = 0;
    }
  }


  String timeString(int length) =>
    DateTime.now().toString().substring(0, length).replaceAll(':', '.');
}