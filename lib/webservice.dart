import 'dart:convert';
import 'dart:io';
import 'package:ciarama_api/ciarama_api.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;

/// Ferramentas para auxiliar o acesso e manipulação de dados de WebServices
class HTTPRequest {
  http.Client _client;
  String baseUrl, child, auth;
  Map<String, String> _header = {
    'authorization': '',
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json; charset=utf-8'
  };

  HTTPRequest(
    this.baseUrl,
    { this.child = '', this.auth = '', Map<String, String> header }
  ) {
    _client = http.Client();
    _header['authorization'] = this.auth;
    if (header != null) {
      for (var k in header.keys) {
        if (!_header.containsKey(k))
          _header.putIfAbsent(k, () => '');
        _header[k] = header[k];
      }
    }
  }

  http.Request _request(String method, {String body='', String subchild = ''}) {
    var url = path.join(baseUrl, child);
    if (subchild != null && subchild.isNotEmpty) url = path.join(url, subchild);
    final req = http.Request(method, Uri.parse(url));
    for (var k in _header.keys) {
      req.headers[k] = _header[k];
    }
    req.body = body;
    print('REQUEST: $url');
    return req;
  }

  Future<http.Response> get({String subchild = ''}) async {
    try {
      final req = _request('GET', subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      print('Falha ao se comunicar com o servidor. $e');
      return Future.value(null);
    }
  }

  Future<http.Response> post({String subchild = '', dynamic body}) async {
    try {
      final req = _request('POST', body: body == null ? '' : body, subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      print('Falha ao se comunicar com o servidor. $e');
      return Future.value(null);
    }
  }

  Future<http.Response> put({String subchild = '', dynamic body}) async {
    try {
      final req = _request('PUT', body: body == null ? '' : body, subchild: subchild);
      return http.Response.fromStream(await req.send());
    } catch (e) {
      print('Falha ao se comunicar com o servidor. $e');
      return Future.value(null);
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

Future<bool> enviarEmail(String to, String subject, String body, { List<File> arquivos }) async {
  final req = http.MultipartRequest('POST', Uri.parse('$INTEGRATOR/email'));
  req.fields['assunto'] = subject;
  req.fields['corpo'] = body;
  req.fields['para'] = to;
  if (arquivos != null) {
    final fileDatas = await Future.wait(arquivos.map((fp) {
      return fp.readAsBytes();
    }));
    for (var fp in fileDatas) {
      final i = fileDatas.indexOf(fp);
      req.files.add(http.MultipartFile.fromBytes('file$i', fp, filename: path.basename(arquivos[i].path)));
    }
  }
  final res = await req.send();
  return (res.statusCode == 200);
}
