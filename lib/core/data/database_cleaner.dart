import '../db/app_database.dart';

/// Borra el contenido de toda la base.
///
/// Es una operación destructiva y sin vuelta atrás: para quitar rifas de la
/// vista usa la papelera, que sí se puede deshacer.
class DatabaseCleaner {
  DatabaseCleaner._();

  static Future<void> clearAllDatabases() => AppDatabase.instance.clear();
}
