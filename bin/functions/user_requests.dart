import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart' show Hmac, sha512;

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

void userRequests({required Router app, required MySQLConnection sql}) {
  app.get('/users', (Request request) async {
    final result = await sql.execute('''
SELECT
id,
name,
permission,
joinedAt
FROM cherrycraft.users;
''');
    final data = result.rows.map((row) => row.assoc()).toList();
    return Response.ok(jsonEncode(data));
  });

  app.get('/admins', (Request request) async {
    final result = await sql.execute('''
SELECT
id,
name,
permission,
joinedAt
FROM cherrycraft.users u WHERE u.permission = 'ADMIN';
''');
    final data = result.rows.map((row) => row.assoc()).toList();
    return Response.ok(jsonEncode(data));
  });

  app.get('/users/<name>', (Request request) async {
    final name = request.params['name'];

    final result = await sql.execute('''
SELECT
id,
name,
permission,
joinedAt
from cherrycraft.users u where u.name = "$name";
''');
    final data = result.rows.map((row) => row.assoc()).toList().firstOrNull;
    return Response.ok(jsonEncode(data));
  });

  // final enums = ['ADMIN', 'PLAYER', 'MOD', 'BUILDER', 'DEV', 'VIP', 'BANNED'];

  app.post('/users', (Request request) async {
    final id = Uuid().v4();

    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];

    final password = parameters['password'];

    final key = utf8.encode(password);
    final bytes = utf8.encode('$name');
    // TODO: Change encryptation method
    final hashMethod = Hmac(sha512, key);
    final encryptedPassword = hashMethod.convert(bytes).toString();
    final logged = "NOT_LOGGED";

    final permissionEnum = parameters['permission'];

    final date = DateTime.now().toIso8601String();

    await sql.execute(
        'insert into cherrycraft.USERS values ("$id", "$name", "$encryptedPassword", "$permissionEnum", "$logged", "$date");');

    final user = {
      "id": id,
      "name": name,
      "permission": permissionEnum,
      "logged": logged, // ENUM
      "joinedAt": date
    };

    return Response.ok(jsonEncode(user));
  });

  app.delete('/users/<id>', (Request request) async {
    final id = request.params['id'];

    await sql.execute('delete from cherrycraft.USERS u where u.id = "$id";');

    return Response.ok({});
  });

  app.patch('/login', (Request request) async {
    try {
      final query = await request.readAsString();
      final parameters = jsonDecode(query) as Map<String, dynamic>;

      final name = parameters['name'];
      final password = parameters['password'];

      final key = utf8.encode(password);
      final bytes = utf8.encode('$name');
      final hashMethod = Hmac(sha512, key);
      final encryptedPassword = hashMethod.convert(bytes).toString();

      final passwordResponse = await sql.execute('''
SELECT password FROM cherrycraft.USERS u where u.name = "$name"; 
''');

      final passwordInDb = passwordResponse.rows
          .map((e) => e.assoc())
          .first['password'] as String;

      final logged = encryptedPassword == passwordInDb;
      if (logged) {
        await sql.execute('''
  UPDATE cherrycraft.users u
  SET u.logged = "LOGGED"
  WHERE u.name = "$name";
  ''');
      }

      return Response.ok(jsonEncode({"logged": logged}));
    } catch (e, stackTrace) {
      print(stackTrace.toString());
      return Response.ok(jsonEncode({}));
    }
  });
}
