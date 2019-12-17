import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:ciarama_api/util.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
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
  String tipo, codMat, foto;

  UsuarioTipo({this.tipo, this.codMat, this.foto});

  factory UsuarioTipo.fromJson(Map<String, dynamic> json) {
    return UsuarioTipo(
      codMat: json['codMat'],
      tipo: json['tipo'],
      foto: json['foto']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codMat': codMat,
      'tipo': tipo,
      'foto': foto
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
      tipo: json['tipo'] != null ? (json['tipo'] as List).map((t) => UsuarioTipo.fromJson(t)).toList() : null,
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

  bool valido() {
    return dataAprovacao != null && dataCriacao != null && tipo != null;
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

  static Future<Result<List<Comentario>, String>> listar(String os, String filial) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario/$os/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }
    
    if (res.statusCode == 200) {
      return Result.ok(parseJson(res.body, (v) => Comentario.fromJson(v)));
    } else {
      return Result.err(res.body);
    }
  }

  static Future<Result<Comentario, String>> ultimo(String os, String filial) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario/ult/$os/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode == 200) {
      final obj = json.decode(res.body);
      return Result.ok(Comentario.fromJson(obj));
    } else {
      return Result.err(res.body);
    }
  }

  static Future<Result<int, String>> comentar(int usid, String os, String filial, String comentario, List<File> imagens) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'comentario',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.post(
      body: json.encode({
        'usuario': usid,
        'os': os,
        'filial': filial,
        'comentario': comentario
      })
    );
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) {
      return Result.err(res.body);
    } else {
      final cmid = int.parse(res.body);
      await Future.wait(imagens.map((im) => uploadFoto(im, cmid)));
      return Result.ok(cmid);
    }
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

  static Widget renderComment(ImageProvider pfp, String clienteCpf, Comentario cm, { bool useTimeAgo = false }) {
    var cargo = cm.autor.cargo;
    if (clienteCpf.trim() == cm.autor.cpfCnpj.trim()) cargo = 'CLIENTE';

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
                profileImage(pfp, size: 42),
                SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(cm.autor.nome, style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('($cargo)'),
                    ],
                  )
                ),
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
                Text(useTimeAgo ? timeago.format(time, locale: 'pt_BR') : formataDataHora(cm.data), style: TextStyle(color: Colors.grey))
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
    final res = await client.get();
    if (res == null) {
      return Future.value(null);
    }

    if (res.statusCode == 200) {
      return res.body;
    }
    return Future.value(null);
  }

  static Future<String> fotoFuncionario(String cod) async {
    // TODO: Foto Funcionario/Colaborador...
    return Future.value(null);
  }

  static Future<Result<Usuario, String>> login(String nome, String senha, { String filial = '*' }) async {
    final ireq = HTTPRequest(
      globais.INTEGRATOR,
      child: 'login/$nome/$senha/$filial',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await ireq.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode == 200) {
      return Result.ok(Usuario.fromJson(json.decode(res.body)));
    } else {
      return Result.err(res.body);
    }
  }

  static Future<Result<String, String>> registrarCliente(String email, String cpfCnpj, String login, String senha) async {
		final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'usuarios/cc',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    final res = await client.post(
      body: json.encode({
        'cpfCnpj': cpfCnpj,
        'login': login,
        'senha': senha
      })
    );
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }
  
    if (res.statusCode != 200) {
      return Result.err(res.body.trim());
    } else {
      return Result.ok(res.body.trim());
    }
  }

  static Future<Result<String, String>> registrarFuncionario(String email, String matricula, String filial, String login, String senha) async {
		final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'usuarios/cf',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    final res = await client.post(
      body: json.encode({
        'matricula': matricula,
        'filial': filial,
        'login': login,
        'senha': senha
      })
    );
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) {
      return Result.err(res.body.trim());
    } else {
      return Result.ok(res.body.trim());
    }
  }

  static Future<Result<String, String>> recuperarSenha(String usuario) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'usuarios/recuperar/$usuario',
      auth: basicAuth('CiaramaRM', 'C14r4m4'),
      header: { 'authorization': '' },
      overrideHeader: true
    );

    final res = await client.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) {
      return Result.err(res.body);
    } else {
      return Result.ok(res.body.trim().replaceAll('"', ''));
    }
  }

  static Future<Result<String, String>> alteraSenha(String user, String senhaNova) async {
    final senhaCod = base64.encode(utf8.encode(senhaNova));
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'alterar/$user/$senhaCod',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );

    final res = await client.put();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) {
      return Result.err('Não foi possível alterar sua senha. ${res.body}');
    } else {
      return Result.ok('Senha alterada com sucesso. Para sua segurança, sua conta foi desativada e um e-mail de confirmação foi enviado para reativação.');
    }
  }
}

class Solicitacao {
  String num, filial, status, urgencia, equipamento,
					modelo, chassi, problema, dataSolicitacao,
					horaSolicitacao, dataAtendimento, horaAtendimento,
					observacaoRetorno, numOS, osFilial;
	int horimetro;
	
	Usuario cliente, tecnico;
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
    this.tecnico,
    this.observacaoRetorno,
    this.numOS,
    this.osFilial,
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
      tecnico: json['tecnico'] != null ? Usuario.fromJson(json['tecnico']) : null,
      observacaoRetorno: json['observacaoRetorno'],
      numOS: json['numOS'],
      osFilial: json['osfilial'],
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
      'tecnico': tecnico != null ? tecnico.toJson() : null,
      'observacaoRetorno': observacaoRetorno,
      'numOS': numOS,
      'osfilial': osFilial,
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
  String tecnicoCPF, observacaoRetorno, dataAtendimento, horaAtendimento;

  Agendamento({
    this.tecnicoCPF,
    this.observacaoRetorno,
    this.dataAtendimento,
    this.horaAtendimento
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      tecnicoCPF: json['tecnicoCPF'],
      observacaoRetorno: json['observacaoRetorno'],
      dataAtendimento: json['dataAtendimento'],
      horaAtendimento: json['horaAtendimento']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tecnicoCPF': tecnicoCPF,
      'observacaoRetorno': observacaoRetorno,
      'dataAtendimento': dataAtendimento,
      'horaAtendimento': horaAtendimento
    };
  }

}

class Agendamentos {
  static Future<Result<List<Solicitacao>, String>> listar() async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode == 200) {
      return Result.ok(parseJson(res.body, (v) => Solicitacao.fromJson(v)));
    } else {
      return Result.err(res.body);
    }
  }

  static Future<Result<String, String>> solicitar(SolicitacaoBase sol) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/solicitar',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.post(body: json.encode(sol.toJson()));
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode == 200) return Result.ok(res.body);
    else                       return Result.err(res.body);
  }

  static Future<Result<String, String>> agendar(String sol, Agendamento age) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/agendar/$sol',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await client.put(body: json.encode(age.toJson()));
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok('');
  }

  static finalizar(String sol, String os) async {
    final client = HTTPRequest(
      globais.INTEGRATOR,
      child: 'agendamento/finalizar/$sol/$os',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    
    final res = await client.put();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok('');
  }

}

class Sistema {
  int id;
  String descricao, obs, plataforma, local, icone;

  Sistema({
    this.id,
    this.descricao,
    this.obs,
    this.plataforma,
    this.local,
    this.icone
  });

  factory Sistema.fromJson(Map<String, dynamic> json) => Sistema(
    id: json['id'],
    descricao: json['descricao'],
    obs: json['obs'],
    plataforma: json['plataforma'],
    local: json['local'],
    icone: json['icone']
  );
}

class Sistemas {
  static Future<Result<List<Sistema>, String>> listar() async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'sistemas',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok(parseJson(res.body, (v) => Sistema.fromJson(v)));
  }
}

class Mensagem {
  int id, usuarioId;
  String tipo, conteudo, os, osFilial, solicitacao, status, dataHora;

  Mensagem({
    this.id,
    this.usuarioId,
    this.tipo,
    this.conteudo,
    this.os,
    this.osFilial,
    this.solicitacao,
    this.status,
    this.dataHora
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) => Mensagem(
    id: json['id'],
    usuarioId: json['usuario'],
    tipo: json['tipo'],
    conteudo: json['conteudo'],
    os: json['os'],
    osFilial: json['osfilial'],
    solicitacao: json['solicitacao'],
    status: json['status'],
    dataHora: json['dataHora']
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'usuario': usuarioId,
    'tipo': tipo,
    'conteudo': conteudo,
    'os': os,
    'osfilial': osFilial,
    'solicitacao': solicitacao,
    'status': status,
    'dataHora': dataHora
  };

}

class Mensageiro {
  static Widget renderMensagem(
    BuildContext context,
    int usid,
    Mensagem msg,
    {
      void Function() onLida,
      void Function(String os, String filial) onBotao
    }
  ) {
    final time = timeago.format(dataHora(msg.dataHora), locale: 'pt_BR');
    final lida = msg.status != null && msg.status.isNotEmpty;
    
    var btnArea;
    if (msg.solicitacao != null && msg.solicitacao.isNotEmpty) {
      btnArea = FlatButton.icon(
        textColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.link),
        label: Text(msg.solicitacao),
        onPressed: () => onBotao(msg.solicitacao, 'SOL'),
      );
    } else if (msg.os != null && msg.os.isNotEmpty) {
      btnArea = FlatButton.icon(
        textColor: Theme.of(context).primaryColor,
        icon: Icon(Icons.link),
        label: Text(msg.os),
        onPressed: () => onBotao(msg.os, msg.osFilial),
      );
    } else btnArea = Container();

    return ListTile(
      leading: lida ? null : Icon(Icons.new_releases, color: Colors.red),
      title: Text(clearMarkdown(msg.conteudo), overflow: TextOverflow.ellipsis),
      trailing: Text(time, style: TextStyle(color: Colors.grey)),
      onTap: () async {
        if (!lida) {
          final res = await Mensageiro.setStatus(msg.id, usid, '*');
          if (onLida != null && res.isOk) onLida();
        }
        await showDialog(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: Text('Mensagem'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                MarkdownBody(
                  data: msg.conteudo,
                  onTapLink: (lnk) => openURL(context, lnk),
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
                ),
                SizedBox(height: 10),
                btnArea,
                Divider(),
                Text(formataDataHora(msg.dataHora), textAlign: TextAlign.right, style: TextStyle(color: Colors.grey))
              ],
            ),
            actions: <Widget>[
              FlatButton(
                child: Text('FECHAR'),
                onPressed: () => Navigator.pop(ctx),
              )
            ],
          )
        );
      },
    );
  }

  static setStatusAll(int usuarioId, String status) async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'msg/$usuarioId/$status',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.put();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok('');
  }

  static Future<Result<int, String>> enviar(Mensagem msg) async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'msg',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.post(body: json.encode(msg.toJson()));
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok(int.parse(res.body));
  }

  static Future<Result<List<Mensagem>, String>> listar(int usid) async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'msg/$usid',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.get();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok(parseJson(res.body, (v) => Mensagem.fromJson(v)));
  }

  static Future<Result<String, String>> setStatus(int mensagemId, int usuarioId, String status) async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'msg/$mensagemId/$usuarioId/$status',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.put();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok('');
  }

}

class Util {
  static Future<Result<String, String>> log(int usuario, int sistema, String funcionalidade) async {
    final req = HTTPRequest(
      globais.INTEGRATOR,
      child: 'log/$usuario/$sistema/$funcionalidade',
      auth: basicAuth('CiaramaRM', 'C14r4m4')
    );
    final res = await req.post();
    if (res == null) {
      return Result.err('Falha ao se comunicar com o servidor.');
    }

    if (res.statusCode != 200) return Result.err(res.body);
    return Result.ok('');
  }
}