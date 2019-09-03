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
    _instance._dataFile = path;

    final fp = File(path);
    if (fp.existsSync()) {
      final dat = await fp.readAsString();
      try {
        _instance._data = json.decode(dat);
      } catch (e) {
        print(e);
      }
    } else {
      await fp.create(recursive: true);
    }

    print(path);

    return _instance;
  }

  String _dataFile;
  Map<String, dynamic> _data = {};

  Future commit() async {
    final fp = File(_dataFile);
    await fp.writeAsString(json.encode(_data));
  }

  delete(String key) {
    _data.remove(key);
  }

  add(String key, dynamic value) {
    _data.update(key, (v) => value, ifAbsent: () => value);
  }

  Map<String, dynamic> get data => _data;

}