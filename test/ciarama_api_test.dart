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
}
