import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

void userRequests({required Router app, required MySQLConnection sql}) {
  app.get('/users', (Request request) async {
    final result = await sql.execute("select * from cherrycraft.users;");
    final data = result.rows.map((row) => row.assoc()).toList();
    return Response.ok(jsonEncode(data));
  });

  app.get('/users/<name>', (Request request) async {
    final name = request.params['name'];

    final result = await sql
        .execute('select * from cherrycraft.users u where u.name = "$name";');
    final data = result.rows.map((row) => row.assoc()).toList().first;
    return Response.ok(jsonEncode(data));
  });

  // final enums = ['ADMIN', 'PLAYER', 'MOD', 'BUILDER', 'DEV', 'VIP'];

  app.post('/users', (Request request) async {
    final id = Uuid().v4();

    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];
    final password = parameters['password'];
    final permissionEnum = parameters['permission'];

    final date = DateTime.now().toIso8601String();

    await sql.execute(
        'insert into cherrycraft.USERS values ("$id", "$name", "$password" ,"$permissionEnum", "$date");');

    final user = {
      "id": id,
      "name": name,
      "password": password,
      "permission": permissionEnum,
      "joinedAt": date
    };

    return Response.ok(jsonEncode(user));
  });

  app.delete('/users/<id>', (Request request) async {
    final id = request.params['id'];

    await sql.execute('delete from cherrycraft.USERS u where u.id = "$id";');

    return Response.ok({});
  });
}
