abstract class BackupRestoreService {
  /// Exports the entire V2 vault as a JSON string.
  Future<String> exportVault();

  /// Restores the entire V2 vault from a JSON string.
  /// Throws FormatException on invalid backup, and rolls back on failure.
  Future<void> restoreVault(String jsonContent);
}
