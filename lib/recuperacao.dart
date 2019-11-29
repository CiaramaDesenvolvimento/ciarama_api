
import 'package:ciarama_api/integrator.dart';
import 'package:flutter/material.dart';
import 'package:pinput/pin_put/pin_put.dart';

class _Action {
  String name;
  IconData icon;
  Future<String> Function() action;

  _Action({
    this.icon,
    this.name,
    this.action
  });
}

class RecoverDialog extends StatefulWidget {
  RecoverDialog({Key key, this.onError}) : super(key: key);

  final void Function(String) onError;

  @override
  _RecoverDialogState createState() => _RecoverDialogState();
}

class _RecoverDialogState extends State<RecoverDialog> {

  final GlobalKey<FormState> _userForm = GlobalKey<FormState>();
  final GlobalKey<FormState> _passForm = GlobalKey<FormState>();

  String _code = '', _realCode = '', _user = '';
  String _novaSenha = '', _novaSenhaRep = '';
  bool _loading = false, _showSenha = false, _showSenhaRep = false;
  int _page =  0;

  String _validaUsuario(String inp) {
    if (inp == null) return 'Especifique um nome de usuário válido.';
    if (inp.trim().isEmpty) return 'Especifique um nome de usuário válido.';
    if (inp.trim().length < 3) return 'Especifique um nome de usuário válido.';
    return null;
  }

  String _validaSenha(String inp) {
    if (inp == null) return 'A senha não pode estar vazia';
    if (inp.trim().isEmpty) return 'A senha não pode estar vazia';
    if (inp.trim().length < 6) return 'A senha precisa ter pelo menos 6 caracteres.';
    return null;
  }

  String _validaSenhaRep(String inp) {
    if (inp == null) return 'Este campo não pode estar vazio.';
    if (inp.trim().isEmpty) return 'Este campo não pode estar vazio.';
    if (inp != _novaSenha) return 'As senhas não correspondem.';
    return null;
  }

  _advance() {
    setState(() { _page++; });
  }

  _nextButton(_Action action) async {
    final res = await action.action();
    if (res != null) {
      final err = res as String;
      if (err.isNotEmpty && widget.onError != null) {
        widget.onError(err);
      }
    }
  }

  Future<String> _page1() async {
    if (_userForm.currentState.validate()) {
      _userForm.currentState.save();

      setState(() {
        _loading = true;
      });

      final res = await Credenciamento.recuperarSenha(_user);
      if (res.isError) {
        setState(() {
          _loading = false;
        });
        return res.error;
      }
      setState(() {
        _realCode = res.value;
        _loading = false;
      });
      _advance();
      return Future.value(null);
    }
    return '';
  }

  Future<String> _page2() async {
    if (_code.toUpperCase() != _realCode.toUpperCase()) {
      return 'Código Inválido.';
    }
    _advance();
    return Future.value(null);
  }

  Future<String> _page3() async {
    if (_passForm.currentState.validate()) {
      _passForm.currentState.save();
      setState(() {
        _loading = true;
      });

      final res = await Credenciamento.alteraSenha(_user, _novaSenha);
      if (res.isError) {
        setState(() {
          _loading = false;
        });
        return res.error;
      }
    }

    setState(() {
      _loading = false;
    });
    Navigator.pop(context, 'OK!');
    return Future.value(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final txt = TextStyle(fontSize: 22.0);
    final txtPass = TextStyle(fontSize: 18.0);

    final pg1 = Form(
      key: _userForm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text('Informe seu nome de usuário para iniciar a recuperação de senha.', textAlign: TextAlign.center,),
          SizedBox(height: 16.0),
          TextFormField(
            style: txt,
            textAlign: TextAlign.center,
            autocorrect: false,
            validator: _validaUsuario,
            autofocus: true,
            onSaved: (s) => setState(() { _user = s; }),
          ),
        ],
      ),
    );

    final pg2 = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text('Um código de verificação foi enviado para seu e-mail. Por favor insira-o abaixo para continuar.', textAlign: TextAlign.center,),
        SizedBox(height: 16.0),
        PinPut(
          onSubmit: (s) => setState(() { _code = s; }),
          fieldsCount: 6,
          containerHeight: 45.0,
          keyboardType: TextInputType.visiblePassword,
          autoFocus: true,
          actionButtonsEnabled: false,
          textStyle: txt,
          textCapitalization: TextCapitalization.characters,
          spaceBetween: 3,
        )
      ],
    );

    final pg3 = Form(
      key: _passForm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Nova Senha',
              suffixIcon: IconButton(
                icon: Icon(_showSenha ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() { _showSenha = !_showSenha; }),
              )
            ),
            style: txtPass,
            textAlign: TextAlign.center,
            autocorrect: false,
            validator: _validaSenha,
            autofocus: true,
            obscureText: !_showSenha,
            keyboardType: TextInputType.visiblePassword,
            onSaved: (s) => setState(() { _novaSenha = s; }),
            onChanged: (s) => setState(() { _novaSenha = s; }),
          ),
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Repita a Senha',
              suffixIcon: IconButton(
                icon: Icon(_showSenhaRep ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() { _showSenhaRep = !_showSenhaRep; }),
              )
            ),
            style: txtPass,
            textAlign: TextAlign.center,
            autocorrect: false,
            validator: _validaSenhaRep,
            autofocus: true,
            obscureText: !_showSenhaRep,
            keyboardType: TextInputType.visiblePassword,
            onSaved: (s) => setState(() { _novaSenhaRep = s; }),
            onChanged: (s) => setState(() { _novaSenhaRep = s; }),
          ),
        ],
      ),
    );
    final pgs = <Widget>[ pg1, pg2, pg3 ];

    final pageActions = [
      _Action(icon: Icons.arrow_forward, name: 'Próximo', action: _page1),
      _Action(icon: Icons.arrow_forward, name: 'Próximo', action: _page2),
      _Action(icon: Icons.done_all, name: 'Concluido', action: _page3),
    ];
    final action = pageActions[_page];

    return AlertDialog(
      title: Text('Recuperar Senha'),
      content: Container(
        width: double.maxFinite,
        height: 150.0,
        child: !_loading ? pgs[_page] : Center(child: CircularProgressIndicator(
          valueColor:AlwaysStoppedAnimation<Color>(theme.primaryColor)
        )),
      ),
      actions: <Widget>[
        !_loading ? FlatButton(
          textColor: theme.primaryColor,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(action.name),
              SizedBox(width: 5),
              Icon(action.icon)
            ],
          ),
          onPressed: () => _nextButton(action)
        ) : SizedBox()
      ],
    );
  }

}