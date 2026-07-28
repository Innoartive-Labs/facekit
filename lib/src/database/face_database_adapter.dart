import '../matcher/person_record.dart';

/// Abstract contract for local face database storage adapters (Memory, JSON, Binary, SQLite).
abstract class FaceDatabaseAdapter {
  /// Initializes database storage resources.
  Future<void> init();

  /// Inserts or updates a [PersonRecord] in database storage.
  Future<void> insert(PersonRecord record);

  /// Retrieves a registered [PersonRecord] by [personId].
  Future<PersonRecord?> get(String personId);

  /// Returns all registered [PersonRecord] entries.
  Future<List<PersonRecord>> getAll();

  /// Removes a person record by [personId].
  Future<bool> delete(String personId);

  /// Clears all stored records from database storage.
  Future<void> clear();
}
