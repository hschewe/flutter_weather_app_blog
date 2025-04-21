/// Basisklasse für alle benutzerdefinierten Exceptions in der App.
sealed class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  AppException(this.message, [this.stackTrace]);

  @override
  String toString() => '$runtimeType: $message';
}

/// Exception für Netzwerkfehler (z.B. keine Verbindung).
class NetworkException extends AppException {
  NetworkException(super.message, [super.stackTrace]);
}

/// Exception für Fehler von der Wetter-API (z.B. ungültige Anfrage, Serverfehler).
class ApiException extends AppException {
  final int? statusCode;
  ApiException(String message, {this.statusCode, StackTrace? stackTrace}) : super(message, stackTrace);

  @override
  String toString() => '$runtimeType: $message (Status Code: $statusCode)';
}

/// Exception für Fehler bei der Standortbestimmung oder Berechtigungen.
class LocationException extends AppException {
  LocationException(super.message, [super.stackTrace]);
}

/// Spezifische Exception, wenn Standortdienste deaktiviert sind.
class LocationServiceDisabledException extends LocationException {
  LocationServiceDisabledException() : super("Standortdienste sind deaktiviert.");
}

/// Spezifische Exception, wenn Berechtigungen verweigert wurden.
class LocationPermissionDeniedException extends LocationException {
  final bool permanentlyDenied;
  LocationPermissionDeniedException({required this.permanentlyDenied})
      : super(permanentlyDenied
              ? "Standortberechtigung permanent verweigert. Bitte in den App-Einstellungen aktivieren."
              : "Standortberechtigung verweigert.");
}

/// Exception für Fehler beim Geocoding (kommt in Teil 4)
class GeocodingException extends AppException { 
  GeocodingException(super.message, [super.stackTrace]);
}

/// Exception für Fehler beim Parsen von Daten (z.B. JSON).
class DataParsingException extends AppException {
  DataParsingException(super.message, [super.stackTrace]);
}

// GtsCalculationException kommt in Teil 6