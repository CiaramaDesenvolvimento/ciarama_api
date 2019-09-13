import 'dart:convert';
import 'dart:typed_data';

import 'package:ciarama_api/ciarama_api.dart';
import 'package:ciarama_api/webservice.dart';
import 'package:web_socket_channel/io.dart';

class Mensagem {
  String appID, tipo;
  Uint8List dados;

  Mensagem({
    this.appID,
    this.tipo,
    this.dados
  });

  factory Mensagem.formJson(Map<String, dynamic> json) {
    return Mensagem(
      appID: json['appID'],
      dados: base64.decode(json['dados']),
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
}

typedef void MensagemRecebida(Mensagem m);
class Notifier {
  static IOWebSocketChannel _channel;

  static Future<Result<String, String>> push(Mensagem m) async {
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
      if (mensagemRecebida != null) mensagemRecebida(Mensagem.formJson(json.decode(msg)));
    });
  }

  static void parar() {
    if (_channel == null) return;
    _channel.sink.close();
    _channel = null;
  }

}