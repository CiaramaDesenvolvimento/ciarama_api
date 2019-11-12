import 'dart:convert';
import 'dart:typed_data';

import 'package:ciarama_api/ciarama_api.dart';
import 'package:ciarama_api/webservice.dart';
import 'package:web_socket_channel/io.dart';

class MensagemNotifier {
  String appID, tipo;
  Uint8List dados;

  MensagemNotifier({
    this.appID,
    this.tipo,
    this.dados
  });

  factory MensagemNotifier.formJson(Map<String, dynamic> json) {
    final dados = json.containsKey('dados') ? json['dados'] : null;
    return MensagemNotifier(
      appID: json.containsKey('appID') ? json['appID'] : null,
      dados: dados != null ? base64.decode(dados) : null,
      tipo: json['tipo']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appID': appID,
      'tipo': tipo,
      'dados': base64.encode(dados)
    };
  }

  Mensagem get innerMessage => Mensagem.fromJson(json.decode(utf8.decode(dados)));

}

typedef void MensagemRecebida(MensagemNotifier m);
class Notifier {
  static IOWebSocketChannel _channel;

  static Future<Result<String, String>> push(MensagemNotifier m) async {
    final client = HTTPRequest(NOTIFIER, child: "push", auth: basicAuth('CiaramaRM', 'C14r4m4'));
    try {
      final res = await client.post(body: json.encode(m.toJson()));
      if (res.statusCode == 200) {
        return Result.ok('');
      }
    } catch (e) {
      print(e);
    }
    return Result.err('Falha ao enviar notificação.');
  }

  static void inicializar(MensagemRecebida mensagemRecebida) {
    _channel = IOWebSocketChannel.connect('ws://$IP_NOTIFIER/notifier/ws');
    _channel.stream.listen((msg) {
      if (mensagemRecebida != null) mensagemRecebida(MensagemNotifier.formJson(json.decode(msg)));
    });
  }

  static void parar() {
    if (_channel == null) return;
    _channel.sink.close();
    _channel = null;
  }

}