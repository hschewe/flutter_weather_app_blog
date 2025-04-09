import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'http_client.g.dart'; // Wird generiert

// Stellt eine globale Instanz von http.Client bereit.
// Vorteil: Kann in Tests einfach durch einen Mock ersetzt werden.
@riverpod
http.Client httpClient(HttpClientRef ref) {
  return http.Client();
}