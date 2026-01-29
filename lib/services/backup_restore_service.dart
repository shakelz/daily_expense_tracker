import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../services/database_helper.dart';

class BackupRestoreService {
  /// Export/backup the database file
  /// Returns the path of the backed up file, or null on error
  static Future<String?> exportDatabase() async {
    try {
      // Get the current database path
      final dbPath = await getDatabasesPath();
      final currentDbPath = path.join(dbPath, 'expense_tracker.db');
      
      // Check if database file exists
      final dbFile = File(currentDbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found');
      }

      // Create backup filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final backupFileName = 'expense_tracker_backup_$timestamp.db';

      // Get temporary directory for sharing
      final tempDir = await getTemporaryDirectory();
      final backupPath = path.join(tempDir.path, backupFileName);

      // Copy database file to temp location
      await dbFile.copy(backupPath);

      print('✓ Database backed up to: $backupPath');
      return backupPath;
    } catch (e) {
      print('Error exporting database: $e');
      return null;
    }
  }

  /// Share the database backup file
  static Future<bool> shareBackup() async {
    try {
      final backupPath = await exportDatabase();
      
      if (backupPath == null) {
        throw Exception('Failed to create backup file');
      }

      // Share the backup file
      await Share.shareXFiles(
        [XFile(backupPath)],
        subject: 'Expense Tracker Database Backup',
        text: 'My expense tracker database backup - ${DateTime.now().toString().split(' ')[0]}',
      );

      print('✓ Database backup shared successfully');
      return true;
    } catch (e) {
      print('Error sharing backup: $e');
      return false;
    }
  }

  /// Import/restore database from a backup file
  /// Returns true if successful, false otherwise
  static Future<bool> importDatabase() async {
    try {
      // Let user pick a database file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db'],
        dialogTitle: 'Select Database Backup File',
        lockParentWindow: true,
      );

      if (result == null || result.files.isEmpty) {
        print('No file selected for restore');
        return false;
      }

      final pickedFile = result.files.first;
      
      if (pickedFile.path == null) {
        throw Exception('Invalid file path');
      }

      final backupFile = File(pickedFile.path!);

      // Verify the file exists
      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist: ${pickedFile.path}');
      }

      // Verify file size (basic validation)
      final fileSize = await backupFile.length();
      if (fileSize == 0) {
        throw Exception('Backup file is empty');
      }

      print('Selected backup file: ${pickedFile.name} (${fileSize} bytes)');

      // Close any open database connections
      // This is important to prevent "database is locked" errors
      try {
        await DatabaseHelper().database.then((db) => db.close());
      } catch (e) {
        print('Note: Could not close database (may already be closed): $e');
      }

      // Small delay to ensure database is fully closed
      await Future.delayed(const Duration(milliseconds: 500));

      // Get the database path
      final dbPath = await getDatabasesPath();
      final targetDbPath = path.join(dbPath, 'expense_tracker.db');

      // Create backup of current database (just in case)
      final currentDbFile = File(targetDbPath);
      if (await currentDbFile.exists()) {
        final emergencyBackupPath = path.join(dbPath, 'expense_tracker_emergency_backup.db');
        try {
          await currentDbFile.copy(emergencyBackupPath);
          print('Emergency backup created at: $emergencyBackupPath');
        } catch (e) {
          print('Warning: Could not create emergency backup: $e');
        }
      }

      // Delete old database
      if (await currentDbFile.exists()) {
        try {
          await currentDbFile.delete();
          print('Old database file deleted');
        } catch (e) {
          print('Warning: Could not delete old database: $e');
        }
      }

      // Copy the backup file to database location
      try {
        await backupFile.copy(targetDbPath);
        print('Backup file copied to database location');
      } catch (e) {
        throw Exception('Failed to copy backup file: $e');
      }

      // Verify the restored database can be opened
      try {
        final restoredDb = await openDatabase(targetDbPath);
        
        // Quick verification - check if transactions table exists
        final tables = await restoredDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='transactions'"
        );
        
        if (tables.isEmpty) {
          await restoredDb.close();
          throw Exception('Restored database does not contain transactions table');
        }
        
        // Verify data integrity by checking a basic count
        final countResult = await restoredDb.rawQuery('SELECT COUNT(*) as count FROM transactions');
        final count = countResult.isNotEmpty ? countResult[0]['count'] as int : 0;
        print('✓ Database verification successful - Found $count transactions');
        
        await restoredDb.close();
      } catch (e) {
        print('Error verifying restored database: $e');
        
        // Try to restore from emergency backup if verification fails
        final emergencyBackupPath = path.join(dbPath, 'expense_tracker_emergency_backup.db');
        if (await File(emergencyBackupPath).exists()) {
          print('Attempting to restore from emergency backup...');
          try {
            await File(emergencyBackupPath).copy(targetDbPath);
            print('Emergency backup restored successfully');
          } catch (restoreError) {
            print('Failed to restore from emergency backup: $restoreError');
          }
        }
        
        throw Exception('Restored database is corrupted or invalid: ${e.toString()}');
      }

      print('✓ Database restored successfully');
      return true;
    } catch (e) {
      print('Error importing database: $e');
      return false;
    }
  }

  /// Get database file size in human-readable format
  static Future<String> getDatabaseSize() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(path.join(dbPath, 'expense_tracker.db'));
      
      if (!await dbFile.exists()) {
        return '0 KB';
      }

      final bytes = await dbFile.length();
      
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(2)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
      }
    } catch (e) {
      print('Error getting database size: $e');
      return 'Unknown';
    }
  }

  /// Get number of transactions in database
  static Future<int> getTransactionCount() async {
    try {
      final transactions = await DatabaseHelper().getAllTransactions();
      return transactions.length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }
}
