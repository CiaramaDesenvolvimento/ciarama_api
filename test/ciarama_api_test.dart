import 'package:ciarama_api/persist.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ciarama_api/ciarama_api.dart';

void main() {
  test('Listagem de Solicitacoes', () async {
    configurar();

    final sols = await Agendamentos.listar();
    expect(sols != null, true);
  });

  test('Foto Cliente', () async {
    configurar();

    final ret = await Credenciamento.fotoCliente('000224');
    expect(ret != null, true);
  });

  test('Data Format', () {
    final dat = '201902041734';
    final dtt = dat.substring(0, 8) + 'T' + dat.substring(8);
    final dt = DateTime.parse(dtt);

    expect(dt.year, 2019);
    expect(dt.month, 2);
    expect(dt.day, 4);
    expect(dt.hour, 17);
    expect(dt.minute, 34);
  });

  test('Persist', () {
    Persist.instance('test').then((p) {
      p.add('Teste', 42);
      p.commit();
    });

    Persist.instance('test').then((p) {
      expect(p.data['Teste'], 42);
    });
  });
}
