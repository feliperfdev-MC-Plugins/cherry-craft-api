import 'dart:convert';

import 'package:mysql_client/mysql_client.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

void banRequests({required Router app, required MySQLConnection sql}) {
  app.get('/banned', (Request request) async {
    final result = await sql.execute('''
SELECT * FROM
cherrycraft.BANNED_PLAYERS
''');

    final data = result.rows.map((row) => row.assoc()).toList();
    return Response.ok(jsonEncode(data));
  });

  app.get('/banned/verify', (Request request) async {
    final result = await sql.execute('''
SELECT name, durationInDays, bannedAt FROM
cherrycraft.BANNED_PLAYERS
''');

    final data = result.rows.map((e) => e.assoc()).toList();
    final today = DateTime.now();
    List<({String name, int timeRemeaning})> responseData = [];

    for (final player in data) {
      final playerBannedAt = DateTime.parse(player['bannedAt'] as String);
      final remeaningDays = int.parse((player['durationInDays'] as String)) -
          today.difference(playerBannedAt).inDays;
      responseData.add((name: player['name']!, timeRemeaning: remeaningDays));
      if (remeaningDays <= 0) {
        await sql.execute(
          '''
  delete from cherrycraft.BANNED_PLAYERS bp
  where bp.name = "${player['name']}";

  UPDATE
  cherrycraft.users u
  SET u.permission = "PLAYER"
  WHERE u.name = "${player['name']}";
''',
        );
      }
    }

    return Response.ok(jsonEncode(responseData
        .map(
          (e) => {
            "name": e.name,
            "banTimeRemeaning": e.timeRemeaning,
          },
        )
        .toList()));
  });

  app.post('/ban', (Request request) async {
    final query = await request.readAsString();
    final parameters = jsonDecode(query) as Map<String, dynamic>;

    final banId = Uuid().v4();
    final playerId = parameters['id'];
    final playerName = parameters['name'];
    final reason = parameters['reason'];
    final durationInDays = parameters['durationInDays'];
    final bannedAt = DateTime.now().toIso8601String();

    final response = await sql.execute('''
INSERT INTO
cherrycraft.BANNED_PLAYERS
VALUES ("$banId", "$playerId", "$playerName", "$reason", $durationInDays, "$bannedAt");

UPDATE
cherrycraft.users u
SET u.permission = "BANNED"
WHERE u.name = "$playerName";
''');
    return Response.ok(response.rows.map((e) => e.assoc()).toList());
  });
}
