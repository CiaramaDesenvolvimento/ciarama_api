import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ciarama_api/ciarama_api.dart';
import 'package:ciarama_api/webservice.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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

class NotifierLocal {
  static FlutterLocalNotificationsPlugin _plugin;
  static ValueListener<String> _stream;

  static Future initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    _stream = ValueListener<String>();
    _plugin = FlutterLocalNotificationsPlugin();

    final android = AndroidInitializationSettings('app_icon');
    final ios = IOSInitializationSettings();
    final settings = InitializationSettings(android, ios);
    await _plugin.initialize(settings, onSelectNotification: (payload) async {
      _stream.send(payload);
    });
  }

  static Future show(String title, {
    int id = 0,
    String body,
    String payload,

    AndroidNotificationDetails androidOverride,
    IOSNotificationDetails iosOverride
  }) async {
    final android = androidOverride == null ? AndroidNotificationDetails(
        'notifier_notification', 'Notifier', 'Notificação do Ciarama Notifier',
        importance: Importance.Max, priority: Priority.Max, ticker: 'ticker',
    ) : androidOverride;
    final ios = iosOverride == null ? IOSNotificationDetails(
      presentAlert: true,
      presentSound: true
    ) : iosOverride;

    final notf = NotificationDetails(android, ios);
    await _plugin.show(id, title, body, notf, payload: payload);
  }

  static Future cancel({ int id = 0 }) async {
    await _plugin.cancel(id);
  }

  static void close() {
    _stream.listen(null);
  }

  static ValueListener<String> get listener => _stream;

}