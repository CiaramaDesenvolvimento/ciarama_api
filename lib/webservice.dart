import 'dart:convert';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

/// Ferramentas para auxiliar o acesso e manipulação de dados de WebServices
class HTTPRequest {
  http.Client _client;
  String baseUrl, child, auth;
  Map<String, String> _header = {
    'authorization': '',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'pplication/json; charset=utf-8'
  };

  HTTPRequest(
    this.baseUrl,
    { this.child = '', this.auth = '' }
  ) {
    _client = http.Client();
    _header['authorization'] = this.auth;
  }

  http.Request _request(String method, {String body='', String subchild = ''}) {
    var url = join(baseUrl, child);
    if (subchild != null && subchild.isNotEmpty) url = join(url, '$subchild');
    final req = http.Request(method, Uri.parse(url));
    for (var k in _header.keys) {
      req.headers[k] = _header[k];
    }
    req.body = body;
    return req;
  }

  Future<http.Response> get({String subchild = ''}) async {
    try {
      final req = _request('GET', subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      return Future.error('Falha ao se comunicar com o servidor. $e');
    }
  }

  Future<http.Response> post({String subchild = '', dynamic body}) async {
    try {
      final req = _request('POST', body: body == null ? '' : body, subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      return Future.error('Falha ao se comunicar com o servidor. $e');
    }
  }

  Future<http.Response> put({String subchild = '', dynamic body}) async {
    try {
      final req = _request('PUT', body: body == null ? '' : body, subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      return Future.error('Falha ao se comunicar com o servidor. $e');
    }
  }
}

typedef T JsonConverter<T>(Map<String, dynamic> json);
List<T> parseJson<T>(String jsonValue, JsonConverter<T> converter) {
  List<T> ret = List();
  final ob = json.decode(jsonValue);
  if (ob == null) {
    return null;
  }
  if (ob is List) {
    for (var i in ob) {
      ret.add(converter(i));
    }
  } else {
    ret.add(converter(ob));
  }
  return ret;
}

String basicAuth(String user, String pass) {
  return 'Basic ' + base64.encode(utf8.encode('$user:$pass'));
}