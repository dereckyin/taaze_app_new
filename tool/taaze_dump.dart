import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final uri = Uri.https('www.taaze.tw', '/rwd_searchResulttest.html', {
    'keyType[]': '0',
    'keyword[]': '泰勒絲',
  });
  final response = await http.get(uri);
  print('Status: ${response.statusCode}');
  final body = utf8.decode(response.bodyBytes);
  print(body.substring(0, body.length.clamp(0, 2000)));
  await File('build/taaze_search_sample.html').writeAsBytes(response.bodyBytes);
  print('Saved to build/taaze_search_sample.html');
}

