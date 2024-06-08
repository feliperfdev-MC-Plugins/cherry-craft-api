import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

void groupsRequests({required Router app, required MySQLConnection sql}) {
  app.post('/group', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final groupId = Uuid().v4();
    final groupName = parameters['groupName'];
    final groupAdmin = parameters['playerName'];

    final response = await sql.execute('''
INSERT INTO
cherrycraft.GROUPS
VALUES ();
''');
  });

  app.post('/group/join', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final requestId = Uuid().v4();
    final groupId = parameters['groupId'];
    final playerRequestingId = parameters['playerRequestingId'];
    final playerAlreadyInAGroup = parameters['playerAlreadyInAGroup'];

    final response = await sql.execute('''
INSERT INTO
cherrycraft.GROUPS_REQUESTS
VALUES ();
''');
  });
}
