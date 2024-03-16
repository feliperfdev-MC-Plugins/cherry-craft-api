import 'dart:convert';
// ignore: depend_on_referenced_packages
import 'package:crypto/crypto.dart' show Hmac, sha384, sha512;

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

import '../utils/user_permissions.dart';

void userRequests({required Router app, required MySQLConnection sql}) {
  app.get('/users', (Request request) async {
    final result = await sql.execute('''
SELECT
id,
name,
permission,
logged,
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
logged,
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
logged,
joinedAt
from cherrycraft.users u where u.name = "$name";
''');
    final data = result.rows.map((row) => row.assoc()).toList().firstOrNull;
    return Response.ok(jsonEncode(data));
  });

  app.post('/users', (Request request) async {
    final id = Uuid().v4();

    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];

    final password = parameters['password'];

    final key = utf8.encode(password);
    final bytes = utf8.encode('$name');

    final hashMethod384 = Hmac(sha384, key);
    final firstEncryptation = hashMethod384.convert(bytes).toString();
    final hashMethod512 = Hmac(sha512, firstEncryptation.codeUnits);
    final encryptedPassword = hashMethod512.convert(bytes).toString();

    final logged = "NOT_LOGGED";

    final permissionEnum = permissions.singleWhere(
      (e) => e.toUpperCase() == '${parameters['permission']}'.toUpperCase(),
    );

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

    final response = await sql
        .execute('delete from cherrycraft.USERS u where u.id = "$id";');

    return Response.ok(jsonEncode({"deleted": response.firstOrNull != null}));
  });

  app.patch('/login', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];
    final password = parameters['password'];

    final passwordResponse = await sql.execute('''
SELECT permission, password FROM cherrycraft.USERS u where u.name = "$name"; 
''');
    final response = passwordResponse.rows.map((e) => e.assoc()).first;

    final permission = permissions.singleWhere(
      (e) => e.toUpperCase() == '${parameters['permission']}'.toUpperCase(),
    );

    if (permission == 'BANNED') {
      return Response.unauthorized(jsonEncode({
        "logged": false,
        "message":
            "Você está banide do servidor! Entre em contato com o suporte caso isso seja um engano."
      }));
    }

    final key = utf8.encode(password);
    final bytes = utf8.encode('$name');

    final hashMethod384 = Hmac(sha384, key);
    final firstEncryptation = hashMethod384.convert(bytes).toString();
    final hashMethod512 = Hmac(sha512, firstEncryptation.codeUnits);
    final encryptedPassword = hashMethod512.convert(bytes).toString();

    final passwordInDb = response['password'] as String;

    final logged = encryptedPassword == passwordInDb;
    if (logged) {
      await sql.execute('''
  UPDATE cherrycraft.users u
  SET u.logged = "LOGGED"
  WHERE u.name = "$name";
  ''');
    }

    return Response.ok(jsonEncode({"logged": logged}));
  });

  app.patch('/disconnect', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];

    final response = await sql.execute('''
  UPDATE cherrycraft.users u
  SET u.logged = "NOT_LOGGED"
  WHERE u.name = "$name";
  ''');

    final logged =
        response.rows.map((e) => e.assoc()).firstOrNull?['logged'] == 'LOGGED';

    return Response.ok(jsonEncode({"logged": logged}));
  });

  app.patch('/promote', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final name = parameters['name'];
    final permission = permissions.singleWhere(
      (e) => e.toUpperCase() == '${parameters['permission']}'.toUpperCase(),
    );

    await sql.execute('''
  UPDATE cherrycraft.users u
  SET u.permission = "$permission"
  WHERE u.name = "$name";
  ''');

    final userResponse = await sql.execute(
      '''
SELECT * from cherrycraft.users u
  WHERE u.name = "$name";
      ''',
    );

    final persona = userResponse.rows.map((e) => e.assoc()).firstOrNull;

    if (persona != null) {
      return Response.ok(jsonEncode({
        "id": persona['id'],
        "name": name,
        "permission": permission,
      }));
    }
    return Response.badRequest(
        body: jsonEncode({
      "errorMessage":
          "Ocorreu um erro ao tentar atribuir nova permissão ao usuário $name",
    }));
  });
}
