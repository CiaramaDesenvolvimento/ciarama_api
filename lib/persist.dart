import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

/// Persistencia de dados
/// Os dados salvos usando este método
/// não serão apagados ao atualizar ou limpar
/// os dados do aplicativo.
class Persist {
  Persist._();
  static final Persist _instance = Persist._();

  static Future<Persist> instance(String name) async {
    final dir = await getExternalStorageDirectory();
    final path = join(dir.path, '$name.json');

    final fp = File(path);
    if (fp.existsSync()) {
      final String dat = await fp.readAsString();
      if (dat.trim().isNotEmpty) {
        final codec = JsonCodec();
        try {
          _instance._data = codec.decode(dat);
        } catch (e) {
          print(e);
        }
      }
    } else {
      await fp.create(recursive: true);
    }
    _instance._dataFile = fp;

    print(path);

    return _instance;
  }

  File _dataFile;
  Map<String, dynamic> _data = {};

  Future commit() async {
    await _dataFile.writeAsString(json.encode(_data));
  }

  delete(String key) {
    _data.remove(key);
  }

  add(String key, dynamic value) {
    _data.update(key, (v) => value, ifAbsent: () => value);
  }

  Map<String, dynamic> get data => _data;

}