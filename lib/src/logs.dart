import 'dart:io';
import 'package:extender/extender.dart';


class Log {
  String folder;
  String archiveFolder;
  String fileName;
  int maxLogFileSize;
  int maxBufferSize;
  var archiveFileTimeLength;
  int timeLength;
  String afterTime;
  int textWidth;
  late int _fileSize;
  var _buffer = '';
  void Function(dynamic error)? onError;
  final File _file;
  late final RandomAccessFile _writer;


  Log({
    this.folder = '\\',
    this.fileName = 'program.log',
    this.archiveFolder = 'log_archive\\',
    this.maxLogFileSize = 8388608,
    this.maxBufferSize = 32768,
    this.archiveFileTimeLength = 21,
    this.timeLength = 23,
    this.afterTime = '  ',
    this.textWidth = 80,
    this.onError
  }): _file = File(folder + fileName) {
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
  ///
  /// [useWidth] включает режим переноса текста на следующую строку, если его
  /// ширина превышает [textWidth]. Перенос будет происходить на местах
  /// [separator]
  ///
  void log(dynamic data, {
    bool showTime = true,
    bool toConsole = true,
    bool toFile = true,
    bool immediatelyToFile = false,
    bool doNotArchive = false,
    bool useWidth = true,
    String separator = ' '
  }) {
    try {
      // Рекурсивная печать с разбиением на строки
      if (useWidth) {
        final stringList = data.toString()
            .toWrappedString(textWidth, separator).toList();
        if (stringList.length > 1) {
          stringList.forEach((item) {
            if (item == stringList.first) {
              log(item,
                  showTime: true,
                  toConsole: toConsole,
                  toFile: toFile,
                  immediatelyToFile: immediatelyToFile,
                  doNotArchive: doNotArchive,
                  useWidth: false);
            } else {
              log(' ' * (timeLength + afterTime.length) + item,
                  showTime: false,
                  toConsole: toConsole,
                  toFile: toFile,
                  immediatelyToFile: immediatelyToFile,
                  doNotArchive: doNotArchive,
                  useWidth: false);
            }
          });
          return;
        }
        data = stringList[0];
      }

      final string = showTime
          ? _timeString(timeLength) + afterTime + data.toString()
          : data.toString();

      if (toConsole) print(string);
      if (toFile) {
        _buffer += (string + '\n');
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


  /// Сохраняет буфер в файл и/или архив, если они уже заполнены
  ///
  /// Функция может быть использована при записи данных при помощи функции
  /// [log()] блоками. Позволяет не записывая новых данных, просто проверить
  /// размеры буфера и фала, и при необходимости скинуть буфер в файл, а файл
  /// в архив
  void saveToFileAndArchiveIfNeed() {
    if (_buffer.length >= maxBufferSize) {
      saveBufferToFile();
    }
    _logToArchive();
  }


  void saveBufferToFile() {
    _writer.writeStringSync(_buffer);
    _fileSize += _buffer.length;
    _buffer = '';
  }


  void _logToArchive() {
    if (_fileSize >= maxLogFileSize) {
      var time = _timeString(archiveFileTimeLength);
      _file.copySync(archiveFolder + time + ' - ' + fileName);
      _writer.setPositionSync(0);
      _writer.truncateSync(0);
      _fileSize = 0;
    }
  }


  String _timeString(int length) =>
    DateTime.now().toString().substring(0, length).replaceAll(':', '.');
}