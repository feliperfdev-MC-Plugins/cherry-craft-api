import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env.dev')
abstract class Env {
  @EnviedField(varName: 'PORT')
  static const String port = _Env.port;

  @EnviedField(varName: 'NAME')
  static const String name = _Env.name;

  @EnviedField(varName: 'PASSWORD', obfuscate: true)
  static String password = _Env.password;
}
