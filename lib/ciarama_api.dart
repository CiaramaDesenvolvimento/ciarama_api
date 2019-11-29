library ciarama_api;
export 'webservice.dart';
export 'globais.dart';
export 'integrator.dart';
export 'util.dart';
export 'persist.dart';
export 'notifier.dart';
export 'recuperacao.dart';

import 'globais.dart' as globais;
import 'package:timeago/timeago.dart' as timeago;

configurar({
  String ipIntegrator = '187.6.87.118:2626',
  String ipWebservice = '187.6.87.118:2626',
  String ipNotifier = '187.6.87.118:2626',
  String nomeWebService = ''
}) {
  globais.IP_INTEGRATOR = ipIntegrator;
  globais.IP_WEBSERVICE = ipWebservice;
  globais.IP_NOTIFIER = ipNotifier;
  globais.INTEGRATOR = 'http://${globais.IP_INTEGRATOR}/Integrator';
  globais.WEBSERVICE = 'http://${globais.IP_WEBSERVICE}/$nomeWebService';
  globais.NOTIFIER = 'http://${globais.IP_NOTIFIER}/notifier';
  
  timeago.setLocaleMessages('pt_BR', timeago.PtBrMessages());
}