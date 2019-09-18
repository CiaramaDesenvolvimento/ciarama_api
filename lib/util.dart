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

final _dateFmt = DateFormat('yyyyMMdd', 'pt_BR');
final _dateFmtS = DateFormat('dd/MM/yyyy', 'pt_BR');

typedef void FiltrarCallback(String filtro, String valor);
typedef void ValueSetter(String value);
typedef void WidgetBuilder(BuildContext ctx, String value, ValueSetter out);

Widget _itemEquip(String nome, String img) {
  return ListTile(
    title: Text(nome),
    leading: Image.asset('res/${img}.png'),
  );
}

class Filtro {
  String id, titulo;
  WidgetBuilder campo;

  Filtro({
    @required this.id,
    @required this.titulo,
    @required this.campo
  });
}

class FiltrarDialog extends StatefulWidget {
  FiltrarDialog(
    this.callback,
    {
      Key key,
      this.filtros,
      this.title = 'Filtrar',
    }
  ) : super(key: key);

  final String title;
  final FiltrarCallback callback;

  final List<Filtro> filtros;
  final List<Filtro> filtrosDefault = [
    Filtro(id: 'data', titulo: 'Data', campo: (ctx, dt, out) => FlatButton(
      color: Theme.of(ctx).primaryColor,
      child: Text('${_dateFmtS.format(_dateFmt.parse(dt))}'),
      onPressed: () {
        showDatePicker(
          context: ctx,
          initialDate: dt != null && dt.isNotEmpty ? _dateFmtS.parse(dt) : DateTime.now(),
          firstDate: DateTime(2001),
          lastDate: DateTime(2030)
        ).then((dt) {
          if (dt != null) out(_dateFmt.format(dt));
        });
      },
    )),
    Filtro(id: 'equip', titulo: 'Equipamento', campo: (ctx, val, out) => DropdownButton( // EQUIP
        isExpanded: true,
        items: <DropdownMenuItem<String>>[
          DropdownMenuItem<String>(child: _itemEquip('Colheitadeira', 'ca'), value: 'CA'),
          DropdownMenuItem<String>(child: _itemEquip('Colhedora de Cana', 'ch'), value: 'CH'),
          DropdownMenuItem<String>(child: _itemEquip('Plataforma de Corte', 'pc'), value: 'PC'),
          DropdownMenuItem<String>(child: _itemEquip('Plantadeira', 'pl'), value: 'PL'),
          DropdownMenuItem<String>(child: _itemEquip('Plataforma de Milho', 'pm'), value: 'PM'),
          DropdownMenuItem<String>(child: _itemEquip('Pulverizador', 'pv'), value: 'PV'),
          DropdownMenuItem<String>(child: _itemEquip('Trator', 'tr'), value: 'TR'),
          DropdownMenuItem<String>(child: _itemEquip('Mini Trator', 'trjd'), value: 'TRJD')
        ],
        onChanged: (c) {
          out(c);
        },
        value: val
    ))
  ];

  @override
	_FiltrarDialogState createState() => _FiltrarDialogState();

}

class _FiltrarDialogState extends State<FiltrarDialog> {

  String _criterio = 'data';
  String _busca = _dateFmt.format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final ValueSetter _setter = (v) {
      setState(() {
        _busca = v;
      });
    };

    var filtros = widget.filtrosDefault;
    if (widget.filtros != null) {
      filtros.addAll(widget.filtros);
    }

    var filtro = filtros.singleWhere((f) => f.id == _criterio, orElse: () => null);
    var buscaW;
    if (filtro != null) {
      buscaW = filtro.campo;
    }

    return AlertDialog(
      title: Text(widget.title),
      content: Container(
        width: 320,
        height: 120,
        child: Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            0: FixedColumnWidth(80.0),
            1: FlexColumnWidth(1)
          },
          children: <TableRow>[
            TableRow(children: [
              Text('Filtro'),
              DropdownButton(
                isExpanded: true,
                items: filtros.map((f) => DropdownMenuItem<String>(child: Text(f.titulo), value: f.id)).toList(),
                onChanged: (c) {
                  setState(() {
                    _busca = '';
                    if (c == 'equip') {
                      _busca = 'CA';
                    }
                    _criterio = c;
                  });
                },
                value: _criterio,
              )
            ]),
            TableRow(children: [
              Text('Busca'),
              buscaW != null ? buscaW(context, _busca, _setter) : Container()
            ])
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text('OK'),
          onPressed: () {
            if (widget.callback != null) {
              print('CRITERIO: $_criterio; BUSCA: $_busca');
              widget.callback(_criterio, _busca);
            }
            Navigator.pop(context);
          },
        )
      ],
    );
  }
}