import 'package:cherry_craft_api/env/env.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'functions/ban_requests.dart';
import 'functions/user_requests.dart';

Future<void> main() async {
  final conn = await MySQLConnection.createConnection(
    host: 'localhost',
    port: int.parse(Env.port),
    userName: Env.name,
    password: Env.password,
  );
  await conn.connect();
  print('Connected to MySQL!\n');
  var app = Router();

  userRequests(app: app, sql: conn);
  banRequests(app: app, sql: conn);

  var server = await shelf_io.serve(app, 'localhost', 8080);

  print('Server running in ${server.address.host}:${server.port}');

  server.autoCompress = true;
}
