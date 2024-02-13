import 'package:cherry_craft_api/env/env.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'functions/user_requests.dart';

Future<void> main() async {
  final conn = await MySQLConnection.createConnection(
    host: "localhost",
    port: int.parse(Env.port),
    userName: Env.name,
    password: Env.password,
  );
  await conn.connect();
  var app = Router();

  userRequests(app: app, sql: conn);

  var server = await shelf_io.serve(app, 'localhost', 8080);
  print("Servidor rodando em: http://localhost:8080");
  server.autoCompress = true;
}
