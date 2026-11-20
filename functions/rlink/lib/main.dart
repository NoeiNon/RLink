import 'dart:async';

Future<dynamic> main(final context) async {
  context.log('RLink function called');
  return context.res.json({'ok': true});
}