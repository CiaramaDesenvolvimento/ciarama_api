import 'dart:typed_data';

import 'package:ciarama_api/ciarama_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

final Filiais = {
  '010101': 'Ponta Porã',
  '010102': 'Amambaí',
  '010103': 'Eldorado',
  '010104': 'Naviraí',
  '010105': 'Nova Andradina',
  '010106': 'Bela Vista',
  '010107': 'Laguna Carapã'
};

final Equipamentos = {
  'TR': 'Trator',
  'PL': 'Plantadeira',
  'PV': 'Pulverizador',
  'PC': 'Plataforma de Corte',
  'PM': 'Plataforma de Milho',
  'CA': 'Colheitadeira',
  'CH': 'Colhedeira de Cana',
  'TRJD': 'Trator de Jardim',
};

openURL(BuildContext context, String url, {String alt}) async {
	if (await canLaunch(url)) {
		await launch(url, forceSafariVC: false, forceWebView: false);
	} else {
		if (alt != null && alt.isNotEmpty)
      await launch(alt);
	}
}

String formataData(String data) {
  if (data == null) return '';
  if (data.length < 8) return data;
  final yy = data.substring(0, 4);
  final mm = data.substring(4, 6);
  final dd = data.substring(6, 8);
  return '$dd/$mm/$yy';
}

String formataHora(String hr) {
  if (hr == null) return '';
  if (hr.length < 4) return hr;
  String h = hr.substring(0, 2);
  String m = hr.substring(2, 4);
  return '$h:$m';
}

String formataDataHora(String dataProt) {
  if (dataProt == null) return '';
  if (dataProt.length < 12) return dataProt;
  String yy = dataProt.substring(0, 4);
  String mm = dataProt.substring(4, 6);
  String dd = dataProt.substring(6, 8);
  String h = dataProt.substring(8, 10);
  String m = dataProt.substring(10, 12);
  String s;
  if (dataProt.length > 12) {
    s = dataProt.substring(12, 14);
  }
  return s != null && s.isNotEmpty ? '$dd/$mm/$yy - $h:$m:$s' : '$dd/$mm/$yy - $h:$m';
}

String dataISO(DateTime dt) {
  return dt.year.toString() + dt.month.toString().padLeft(2, '0') + dt.day.toString().padLeft(2, '0');
}

DateTime dataISOtoDateTime(String data) {
  if (data.length < 8) return null;
  final yy = data.substring(0, 4);
  final mm = data.substring(4, 6);
  final dd = data.substring(6, 8);
  return DateTime(int.parse(yy), int.parse(mm), int.parse(dd));
}

DateTime dataHora(String dh) {
  if (dh == null) return null;
  if (dh.length < 12) return null;
  String yy = dh.substring(0, 4);
  String mm = dh.substring(4, 6);
  String dd = dh.substring(6, 8);
  String h = dh.substring(8, 10);
  String m = dh.substring(10, 12);
  String s;
  if (dh.length > 12) {
    s = dh.substring(12, 14);
  }
  return DateTime(
    int.parse(yy), int.parse(mm), int.parse(dd),
    int.parse(h), int.parse(m), s != null ? int.parse(s) : 0
  );
}

Widget profileImage(ImageProvider image, {double size = 100.0}) {
  return Container(
    width: size, height: size,
    decoration: BoxDecoration(
      image: DecorationImage(
        image: image,
        fit: BoxFit.cover
      ),
      borderRadius: BorderRadius.circular(size / 4),
      boxShadow: <BoxShadow>[
        BoxShadow(
          blurRadius: 4.0,
          offset: Offset(0.0, 2.0),
          color: Colors.black26
        )
      ]
    ),
  );
}

class Logo extends StatelessWidget {
  const Logo(this.asset, {
    Key key,
    this.size = 200.0,
  }) : super(key: key);

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: size / 10.0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size / 6)
      ),
      child: Image.asset(asset, width: size,),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({
    Key key,
    this.foto,
    this.size = 150.0,
  }) : super(key: key);

  final Uint8List foto;
  final double size;

  @override
  Widget build(BuildContext context) {
    var vfoto;
    if (foto != null) {
      vfoto = Image.memory(foto);
    }
    return AnimatedContainer(
      duration: Duration(milliseconds: 500),
      curve: Curves.fastLinearToSlowEaseIn,
      width: size,
      height: size,
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(size / 2.0),
      ),
      child: ClipRRect(
        clipBehavior: Clip.antiAlias,
        child: vfoto == null ? Icon(Icons.person, size: size / 2.0, color: Colors.grey) : vfoto,
        borderRadius: BorderRadius.circular(size / 2.0),
      )
    );
  }
}

class Result<V, E> {
  E _error;
  V _value;

  Result._({ E error, V value }) {
    _error = error;
    _value = value;
  }

  factory Result.err(E error) {
    return Result._(error: error);
  }

  factory Result.ok(V value) {
    return Result._(value: value);
  }

  bool get isError => (_error != null);
  bool get isOk => (_value != null);

  V get value => _value;
  E get error => _error;

}

class ValueListener<V> {
  void Function(V value) _listener;

  listen(void Function(V value) listener) => _listener = listener;
  
  send(V value) {
    if (_listener != null) _listener(value);
  }

}

HTTPRequest integratorRequest({
  String child = '',
  Map<String, String> header,
  bool overrideHeader = false
}) => HTTPRequest(INTEGRATOR, child: child, auth: basicAuth('CiaramaRM', 'C14r4m4'), header: header, overrideHeader: overrideHeader);

HTTPRequest webserviceRequest({
  String child = '',
  String auth = '',
  Map<String, String> header,
  bool overrideHeader = false
}) => HTTPRequest(WEBSERVICE, child: child, auth: auth, header: header, overrideHeader: overrideHeader);

String clearMarkdown(String md) {
  var res = md;
  
  // Remove horizontal rule
  res = res.replaceAll(RegExp(r'^(-\s*?|\*\s*?|_\s*?){3,}\s*$', multiLine: true), '');

  res = res
    .replaceAll(RegExp(r'\n={2,}'), '')
    .replaceAll(RegExp(r'~{3}.*\n'), '')
    .replaceAll(RegExp(r'~~'), '')
    .replaceAll(RegExp(r'`{3}.*\n'), '')
    .replaceAll(RegExp(r'^[=\-]{2,}\s*$'), '')
    .replaceAll(RegExp(r'\[\^.+?\](\: .*?$)?'), '')
    .replaceAll(RegExp(r'\s{0,2}\[.*?\]: .*?$'), '')
    .replaceAll(RegExp(r'\!\[(.*?)\][\[\(].*?[\]\)]'), '')
    .replaceAllMapped(RegExp(r'\[(.*?)\][\[\(].*?[\]\)]'), (m) => m.group(1))
    .replaceAll(RegExp(r'^\s{0,3}>\s?', multiLine: true), '')
    .replaceAllMapped(RegExp(r'([\*_]{1,3})(\S.*?\S{0,1})\1'), (m) => m.group(2))
    .replaceAllMapped(RegExp(r'([\*_]{1,3})(\S.*?\S{0,1})\1'), (m) => m.group(2))
    .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m.group(1))
    .replaceAllMapped(RegExp(r'(#+)(.*)'), (m) => m.group(2).trim());

  return res;
}

class DadosQRCode {
  String chassi, modelo, grupo, ano;
  DadosQRCode({ this.chassi, this.modelo, this.grupo, this.ano });

  factory DadosQRCode.fromCode(String code) {
    // Tokenizar
    var spl = code.split('').toList();
    var tokens = <Map<String, String>>[];
    final idregex = RegExp(r'[a-zA-Z0-9_\/\\\.,]');
    while (spl.isNotEmpty) {
      final c = spl.first;
      if (c.contains(idregex)) {
        var str = '';
        while (spl.isNotEmpty && spl.first.contains(idregex)) {
          str += spl.removeAt(0);
        }
        tokens.add({ 'type': 'VAL', 'value': str.trim() });
      } else if ([';', ':', '='].contains(c)) {
        final sym = spl.removeAt(0);
        tokens.add({ 'type': 'SYM', 'value': sym });
      } else {
        spl.removeAt(0);
      }
    }

    // Tradutor
    final p = _SDFParser(tokens: tokens);
    final entries = p.parse();

    return DadosQRCode(
      chassi: entries['CHASSI'],
      modelo: entries['MODELO'],
      grupo: entries['GRUPO'],
      ano: entries['ANO'],
    );
  }

}

class _SDFParser {
  List<Map<String, String>> tokens;
  _SDFParser({ this.tokens });

  _val() {
    if (tokens.first['type'] != 'VAL') {
      return null;
    }
    return tokens.removeAt(0)['value'];
  }

  _sym({ String expect }) {
    if (tokens.first['type'] != 'SYM') {
      throw Exception('Esperava um símbolo.');
    }
    if (expect != null && tokens.first['value'] != expect) {
      throw Exception('Esperava um "$expect". "${tokens.first['value']}" é inválido.');
    }
    tokens.removeAt(0);
  }

  MapEntry<String, String> _entry() {
    final name = _val();
    if (name != null) {
      try {
        _sym(expect: ':');
        final value = _val();
        if (value != null) {
          try {
            _sym(expect: ';');
            return MapEntry(name, value);
          } catch (e) { throw e; }
        } else {
          throw Exception('Valor inválido.');
        }
      } catch (e) { throw e; }
    } else {
      throw Exception('Nome inválido.');
    }
  }

  Map<String, String> parse() {
    final ret = <String, String>{};
    while (tokens.isNotEmpty) {
      try {
        final e = _entry();
        ret.addEntries([e]);
      } catch (e) { throw e; }
    }
    return ret;
  }
}