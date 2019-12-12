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
		await launch(url);
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