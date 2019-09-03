import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:timeago/timeago.dart' as timeago;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:ciarama_api/webservice.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';

import 'globais.dart' as globais;

/// Usuario
class UsuarioTipo {
  String tipo, codMat;

  UsuarioTipo({this.tipo, this.codMat});

  factory UsuarioTipo.fromJson(Map<String, dynamic> json) {
    return UsuarioTipo(
      codMat: json['codMat'],
      tipo: json['tipo']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codMat': codMat,
      'tipo': tipo
    };
  }
}

class Usuario {
  int id;
  String login, nome, email, cpfCnpj, filial,
    dataCriacao, dataAprovacao, cargo, senha, ativo;

  List<UsuarioTipo> tipo;
  Map<String, dynamic> colaborador;

  Usuario({
    this.id,
    this.login,
    this.nome,
    this.email,
    this.cpfCnpj,
    this.filial,
    this.dataCriacao,
    this.dataAprovacao,
    this.tipo,
    this.cargo,
    this.senha,
    this.ativo,
    this.colaborador
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'],
      login: json['login'],
      nome: json['nome'],
      email: json['email'],
      cpfCnpj: json['cpfCnpj'],
      filial: json['filial'],
      dataAprovacao: json['dataAprovacao'],
      dataCriacao: json['dataCriacao'],
      tipo: (json['tipo'] as List).map((t) => UsuarioTipo.fromJson(t)).toList(),
      cargo: json['cargo'],
      senha: json['senha'],
      ativo: json['ativo'],
      colaborador: json.containsKey('colab') ? json['colab'] : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'login': login,
      'nome': nome,
      'email': email,
      'cpfCnpj': cpfCnpj,
      'filial': filial,
      'dataAprovacao': dataAprovacao,
      'dataCriacao': dataCriacao,
      'cargo': cargo,
      'senha': senha,
      'tipo': tipo.map((t) => t.toJson()).toList(),
      'ativo': ativo,
      'colab': colaborador
    };
  }

  UsuarioTipo getTipo(String tipo) {
    for (var tp in this.tipo) {
      if (tp.tipo.toUpperCase() == tipo.toUpperCase()) return tp;
    }
    return null;
  }

  UsuarioTipo usuarioTipo() {
    return isTipo('F') ? getTipo('F') : getTipo('C');
  }

  bool isTipo(String tipo) {
    return getTipo(tipo) != null;
  }

}

class Comentario {
  int id;
  Usuario autor;
  String conteudo, data;
  List<String> fotos;

  Comentario({
    this.id,
    this.autor,
    this.conteudo,
    this.data,
    this.fotos
  });

  factory Comentario.fromJson(Map<String, dynamic> json) {
    return Comentario(
      id: json['id'],
      autor: Usuario.fromJson(json['usuario']),
      conteudo: json['conteudo'],
      data: json['dataHora'],
      fotos: json['fotos'] != null ? (json['fotos'] as List).map((f) => f['dados'] as String).toList() : []
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuario': autor.toJson(),
      'conteudo': conteudo,
      'dataHora': data,
      'fotos': fotos.map((f) => { 'dados': f }).toList()
    };
  }
}

/// Comentários
class Comentarios {
  static Future<Response> uploadFoto(File imagem, int cmid) async {
    final token = base64.encode(latin1.encode('CiaramaRM:C14r4m4'));
    final auth = 'Basic ' + token.trim();
    final length = await imagem.length();
    final req = MultipartRequest('POST', Uri.parse('${globais.INTEGRATOR}/comentario/ft/$cmid'));
    req.files.add(MultipartFile(
      'file',
      imagem.openRead(),
      length
    ));
    req.headers['authorization'] = auth;
    req.headers['content-type'] = 'multipart/form-data';
    return Response.fromStream(await req.send());
  }

  static Future<List<Comentario>> listar(String os, String filial) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario/$os/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.get();
      if (res.statusCode == 200) {
        final obj = json.decode(res.body);
        if (obj is List) {
          return obj.map((v) => Comentario.fromJson(v)).toList();
        }
      } else {
        print(res.body);
      }
    } catch (e) {
      print(e);
    }
    return Future.value(null);
  }

  static Future<Comentario> ultimo(String os, String filial) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario/ult/$os/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.get();
      if (res.statusCode == 200) {
        final obj = json.decode(res.body);
        return Comentario.fromJson(obj);
      }
    } catch (e) {
      print(e);
    }
    return Future.value(null);
  }

  static Future<String> comentar(int usid, String os, String filial, String comentario, List<File> imagens) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.post(
        body: json.encode({
          'usuario': usid,
          'os': os,
          'filial': filial,
          'comentario': comentario
        })
      );
      if (res.statusCode != 200) {
        throw res.body;
      } else {
        final cmid = int.parse(res.body);
        await Future.wait(imagens.map((im) => uploadFoto(im, cmid)));
        return res.body;
      }
    } catch (e) {
      print(e);
    }
    throw 'Falha ao se comunicar com o servidor.';
  }

  // INTERFACE
  static _openImage(Uint8List data) async {
    final img = await decodeImageFromList(data);
    final dat = await img.toByteData(format: ImageByteFormat.png);
    final dir = await getTemporaryDirectory();
    final dest = join(dir.path, 'temp', 'fotoview.png');
    final fl = File(dest);
    final ex = await fl.exists();
    if (!ex) await fl.create(recursive: true);
    await fl.writeAsBytes(dat.buffer.asUint8List());
    print(fl.path);
    final ret = await OpenFile.open(fl.path);
    print(ret);
  }

  static Widget renderComment(String osCliente, Comentario cm) {
    var cargo = cm.autor.cargo;
    if (osCliente == cm.autor.nome) cargo = 'CLIENTE';

    final dtt = cm.data.substring(0, 8) + 'T' + cm.data.substring(8);
    final time = DateTime.parse(dtt);

    final List<Widget> imgs = cm.fotos.map((dt) {
      final dat = base64.decode(dt);
      final img = MemoryImage(dat);
      return Container(
        child: Ink.image(
          image: img,
          fit: BoxFit.cover,
          repeat: ImageRepeat.noRepeat,
          width: 90.0,
          height: 90.0,
          child: InkWell(
            enableFeedback: true,
            onTap: () => _openImage(dat),
          ),
        )
      );
    }).toList();
    return Card(
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.all(10.0),
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.comment, size: 20),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(cm.autor.nome, style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('($cargo)'),
                  ],
                )
              ],
            ),
            Divider(height: 12),
            Text(cm.conteudo),
            Divider(height: 12),
            Wrap(
              children: imgs,
              spacing: 4.0,
              runSpacing: 5.0,
            ),
            Divider(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text(timeago.format(time, locale: 'pt_BR'), style: TextStyle(color: Colors.grey))
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Login...
class Credenciamento {
  static Future<String> fotoCliente(String cod) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'foto_cliente/$cod',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.get();
      if (res.statusCode == 200) {
        return res.body;
      }
    } catch (e) {
      print(e);
    }
    return Future.value(null);
  }

  static Future<String> fotoFuncionario(String cod) async {
    // TODO: Foto Funcionario/Colaborador...
    return Future.value(null);
  }

  static Future<Usuario> login(String nome, String senha, { String filial = '*' }) async {
    final ireq = HTTPRequest(
      globais.INTEGRATOR,
      child: 'login/$nome/$senha/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await ireq.get();
      if (res.statusCode == 200) {
        return Usuario.fromJson(json.decode(res.body));
      }
    } catch (e) {
      print(e);
    }
    return Future.value(null);
  }

  static Future<String> registrarCliente(String email, String cpfCnpj, String login, String senha) async {
		final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'usuarios/cc',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    try {
      final res = await client.post(
        body: json.encode({
          'cpfCnpj': cpfCnpj,
          'login': login,
          'senha': senha
        })
      );
      if (res.statusCode == 200) {
        final note = res.body.trim();
        if (note.isEmpty) {
          return 'Cadastro realizado com sucesso. Um e-mail de confirmação foi enviado para $email. Caso este não seja seu e-mail, solicite uma atualização de cadastro.';
        } else {
          throw note;
        }
      }
    } catch (e) {
      print(e);
    }
		throw 'Falha ao se comunicar com o servidor.';
  }

  static Future<String> registrarFuncionario(String email, String matricula, String filial, String login, String senha) async {
		final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'usuarios/cf',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    try {
      final res = await client.post(
        body: json.encode({
          'matricula': matricula,
          'filial': filial,
          'login': login,
          'senha': senha
        })
      );
      if (res.statusCode == 200) {
        final note = res.body.trim();
        if (note.isEmpty) {
          return 'Cadastro realizado com sucesso. Um e-mail de confirmação foi enviado para $email. Caso este não seja seu e-mail, solicite uma atualização de cadastro.';
        } else {
          throw note;
        }
      }
    } catch (e) {
      print(e);
    }
		throw 'Falha ao se comunicar com o servidor.';
  }

  static Future<String> alteraSenha(Usuario user, String senhaNova) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'alterar/${user.cpfCnpj}/$senhaNova',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    try {
      final res = await client.put();
      if (res.statusCode == 200) {
        return Future.value(null);
      } else {
        throw 'Não foi possível alterar sua senha.';
      }
    } catch (e) {
      print(e);
      throw 'Não foi possível alterar sua senha. Falha ao se comunicar com o servidor.';
    }
  }
}

class Solicitacao {
  String num, filial, status, urgencia, equipamento,
					modelo, chassi, problema, dataSolicitacao,
					horaSolicitacao, dataAtendimento, horaAtendimento,
					tecnicoNome, tecnicoProdutivo, observacaoRetorno,
					numOS;
	int horimetro;
	
	Usuario cliente;
	List<Comentario> comentarios;

  Solicitacao({
    this.num,
    this.filial,
    this.status,
    this.urgencia,
    this.equipamento,
    this.modelo,
    this.chassi,
    this.problema,
    this.dataSolicitacao,
    this.horaSolicitacao,
    this.dataAtendimento,
    this.horaAtendimento,
    this.tecnicoNome,
    this.tecnicoProdutivo,
    this.observacaoRetorno,
    this.numOS,
    this.horimetro,
    this.cliente,
    this.comentarios
  });

  factory Solicitacao.fromJson(Map<String, dynamic> json) {
    return Solicitacao(
      num: json['num'],
      filial: json['filial'],
      status: json['status'],
      urgencia: json['urgencia'],
      equipamento: json['equipamento'],
      modelo: json['modelo'],
      chassi: json['chassi'],
      problema: json['problema'],
      dataSolicitacao: json['dataSolicitacao'],
      horaSolicitacao: json['horaSolicitacao'],
      dataAtendimento: json['dataAtendimento'],
      horaAtendimento: json['horaAtendimento'],
      tecnicoNome: json['tecnicoNome'],
      tecnicoProdutivo: json['tecnicoProdutivo'],
      observacaoRetorno: json['observacaoRetorno'],
      numOS: json['numOS'],
      horimetro: json['horimetro'],
      cliente: Usuario.fromJson(json['cliente']),
      comentarios: json['comentarios'] != null ? (json['comentarios'] as List).map((v) => Comentario.fromJson(v)).toList() : []
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'num': num,
      'filial': filial,
      'status': status,
      'urgencia': urgencia,
      'equipamento': equipamento,
      'modelo': modelo,
      'chassi': chassi,
      'problema': problema,
      'dataSolicitacao': dataSolicitacao,
      'horaSolicitacao': horaSolicitacao,
      'dataAtendimento': dataAtendimento,
      'horaAtendimento': horaAtendimento,
      'tecnicoNome': tecnicoNome,
      'tecnicoProdutivo': tecnicoProdutivo,
      'observacaoRetorno': observacaoRetorno,
      'numOS': numOS,
      'horimetro': horimetro,
      'cliente': cliente.toJson(),
      'comentarios': comentarios.map((c) => c.toJson()).toList()
    };
  }
}

class SolicitacaoBase {
  String filial, urgencia, equipamento,
					modelo, chassi, problema;
	int horimetro, clienteID;

  SolicitacaoBase({
    this.filial,
    this.urgencia,
    this.equipamento,
    this.modelo,
    this.chassi,
    this.problema,
    this.horimetro,
    this.clienteID
  });

  factory SolicitacaoBase.fromJson(Map<String, dynamic> json) {
    return SolicitacaoBase(
      filial: json['filial'],
      urgencia: json['urgencia'],
      equipamento: json['equipamento'],
      modelo: json['modelo'],
      chassi: json['chassi'],
      problema: json['problema'],
      horimetro: json['horimetro'],
      clienteID: json['clienteID']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'filial': filial,
      'urgencia': urgencia,
      'equipamento': equipamento,
      'modelo': modelo,
      'chassi': chassi,
      'problema': problema,
      'horimetro': horimetro,
      'clienteID': clienteID
    };
  }

}

class Agendamento {
  String tecnicoNome, tecnicoProdutivo, observacaoRetorno;

  Agendamento({
    this.tecnicoNome,
    this.tecnicoProdutivo,
    this.observacaoRetorno
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      tecnicoNome: json['tecnicoNome'],
      tecnicoProdutivo: json['tecnicoProdutivo'],
      observacaoRetorno: json['observacaoRetorno']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tecnicoNome': tecnicoNome,
      'tecnicoProdutivo': tecnicoProdutivo,
      'observacaoRetorno': observacaoRetorno
    };
  }

}

class Agendamentos {
  static Future<List<Solicitacao>> listar() async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.get();
      if (res.statusCode == 200) {
        return parseJson(res.body, (v) => Solicitacao.fromJson(v));
      } else {
        throw res.body;
      }
    } catch (e) {
      print(e);
    }
    throw 'Falha ao se comunicar com o servidor: Erro interno.';
  }

  static Future<String> solicitar(SolicitacaoBase sol) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/solicitar',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.post(body: json.encode(sol.toJson()));
      if (res.statusCode == 200) return res.body;
      else                       return Future.value(null);
    } catch (e) {
      print(e);
    }
    throw 'Falha ao se comunicar com o servidor: Erro Interno.';
  }

  static Future<String> agendar(String sol, Agendamento age) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/agendar/$sol',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.put(body: json.encode(age.toJson()));
      if (res.statusCode != 200) throw res.body;
      else return Future.value(null);
    } catch (e) {
      print(e);
    }
    throw 'Falha ao se comunicar com o servidor: Erro Interno.';
  }

  static Future<String> finalizar(String sol, String os) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/finalizar/$sol/$os',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    try {
      final res = await client.put();
      if (res.statusCode != 200) throw res.body;
      else return Future.value(null);
    } catch (e) {
      print(e);
    }
    throw 'Falha ao se comunicar com o servidor: Erro Interno.';
  }

}