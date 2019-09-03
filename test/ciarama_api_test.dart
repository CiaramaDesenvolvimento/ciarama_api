import 'package:flutter_test/flutter_test.dart';

import 'package:ciarama_api/ciarama_api.dart';
import 'package:intl/intl.dart';

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

    expect(dt.year == 2019, true);
    expect(dt.month == 2, true);
    expect(dt.day == 4, true);
    expect(dt.hour == 17, true);
    expect(dt.minute == 34, true);
  });
}
