

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


  /// Печатает данные в виде текста в консоль и/или лог-файл.
  ///
  /// Данные [data] сначала преобразуются в текст. Потом печатаются в
  /// консоль (если [toConsole] равен true) и в файл (если [toFile] равен true).
  /// Параметр [showTime] позволяет выводить в начале строки время. Его точность
  /// задаётся длинной текста [timeLength]. Самое точное время будет выведено,
  /// если [timeLength] будет равен 23. Параметр [afterTime] позволяет
  /// задать разделитель между временем и основным текстом.
  ///
  /// Печать данных сначала кэшируется в буфер и консоль. Как только достигнут
  /// максимальный размер буфера, данные записываются в файл. Когда размер
  /// файла достигает максимального, то он переносится в папку архивов логов.
  /// Максимальные размеры буфера и файла можно задать в конструкторе [Log()].
  ///
  /// Параметры [immediatelyToFile] и [doNotArchive] позволяют печатать данные
  /// в файл блоками. Это позволяет не разрывать данные, и при этом не
  /// перегружать диск работой. Параметр [immediatelyToFile] позволяет
  /// принудительно записать вест буфер в файл сразу после печати.
  /// А [doNotArchive] позволяет временно избежать переноса фала в архив. Это
  /// позволит не разрывать данные, которые разрывать нежелательно.
  void log(dynamic data, {
    bool showTime = true,
    int timeLength = 23,
    String afterTime = '  ',
    bool toConsole = true,
    bool toFile = true,
    bool immediatelyToFile = false,
    bool doNotArchive = false
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
          saveBufferToFile();
        }
        if (!doNotArchive) {
          _logToArchive();
        }
      }
    } catch(error) {
      if (onError == null) {
        throw Exception(error);
      } else {
        onError?.call(error);
      }
    }
  }


  void saveBufferToFile() {
    _writer.writeStringSync(_buffer);
    _fileSize += _buffer.length;
    _buffer = '';
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