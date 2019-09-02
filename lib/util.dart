import 'package:flutter/material.dart';
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