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
  final yy = data.substring(0, 4);
  final mm = data.substring(4, 6);
  final dd = data.substring(6, 8);
  return '$dd/$mm/$yy';
}

String formataHora(String hr) {
  String h = hr.substring(0, 2);
  String m = hr.substring(2, 4);
  return '$h:$m';
}

String formataDataHora(String dataProt) {
  String yy = dataProt.substring(0, 4);
  String mm = dataProt.substring(4, 6);
  String dd = dataProt.substring(6, 8);
  String h = dataProt.substring(8, 10);
  String m = dataProt.substring(10, 12);
  return '$dd/$mm/$yy - $h:$m';
}

String dataISO(DateTime dt) {
  return dt.year.toString() + dt.month.toString().padLeft(2, '0') + dt.day.toString().padLeft(2, '0');
}

DateTime dataISOtoDateTime(String data) {
  final yy = data.substring(0, 4);
  final mm = data.substring(4, 6);
  final dd = data.substring(6, 8);
  return DateTime(int.parse(yy), int.parse(mm), int.parse(dd));
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
