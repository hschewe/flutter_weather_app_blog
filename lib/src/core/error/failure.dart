import 'package:equatable/equatable.dart';

/// Repräsentiert einen Fehlerfall, der dem Benutzer angezeigt werden kann
/// oder die Logik beeinflusst (abstrahiert von Exceptions).
sealed class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
  @override
  List<Object?> get props => [message];
}

/// Fehler von einem Server oder einer API.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Fehler beim Caching (kommt evtl. später).
// class CacheFailure extends Failure { ... }

/// Fehler wegen fehlender Netzwerkverbindung.
class NetworkFailure extends Failure {
  const NetworkFailure() : super("Keine Internetverbindung.");
}

/// Fehler bei Standortdiensten (nicht Berechtigung).
class LocationFailure extends Failure {
  const LocationFailure(super.message);
}

/// Fehler wegen fehlender Berechtigungen.
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Fehler beim Geocoding.
class GeocodingFailure extends Failure { 
  const GeocodingFailure(super.message);
}

/// Allgemeiner, unerwarteter Fehler.
class UnknownFailure extends Failure {
  const UnknownFailure(String details) : super("Ein unerwarteter Fehler ist aufgetreten: $details");
}

/// Fehler bei der GTS-Berechnung.
class GtsFailure extends Failure {
  const GtsFailure(super.message);
}