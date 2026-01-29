import 'package:flutter/material.dart';

import '../services/backup_restore_service.dart';
import '../services/preferences_service.dart';
import '../services/security_service.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback onDatabaseRestored;

  const SettingsTab({super.key, required this.onDatabaseRestored});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _dbSize = 'Calculating...';
  int _transactionCount = 0;
  late PreferencesService _prefs;
  late SecurityService _securityService;
  
  bool _isBiometricEnabled = true;
  int _retryLimit = 5;
  bool _requireAuthForExport = false;
  bool _requireAuthForRestore = true;
  String _lastAuthTime = 'Never';

  @override
  void initState() {
    super.initState();
    _prefs = PreferencesService();
    _securityService = SecurityService();
    _loadDatabaseInfo();
    _loadSecuritySettings();
  }

  Future<void> _loadDatabaseInfo() async {
    final size = await BackupRestoreService.getDatabaseSize();
    final count = await BackupRestoreService.getTransactionCount();
    
    if (mounted) {
      setState(() {
        _dbSize = size;
        _transactionCount = count;
      });
    }
  }

  Future<void> _loadSecuritySettings() async {
    final isBioEnabled = await _prefs.isBiometricEnabled();
    final retryLimit = await _prefs.getAuthRetryLimit();
    final requireExport = await _prefs.requireAuthForExport();
    final requireRestore = await _prefs.requireAuthForRestore();
    final lastAuth = await _prefs.getFormattedLastAuthTime();
    
    if (mounted) {
      setState(() {
        _isBiometricEnabled = isBioEnabled;
        _retryLimit = retryLimit;
        _requireAuthForExport = requireExport;
        _requireAuthForRestore = requireRestore;
        _lastAuthTime = lastAuth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your data and preferences',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            
            // Security Settings Section
            _buildSecuritySettingsSection(),
            
            const SizedBox(height: 24),
            
            // Database Info Card
            _buildInfoCard(),
            
            const SizedBox(height: 24),
            
            // Backup & Restore Section
            _buildBackupRestoreSection(),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildAboutSection(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A1E3E),
            Color(0xFF1E2A3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 8),
              const Text(
                'Security Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Biometric Lock Toggle
          _buildToggleSetting(
            title: 'Enable Biometric Lock',
            subtitle: _isBiometricEnabled ? 'Fingerprint required on app launch' : 'Lock disabled',
            value: _isBiometricEnabled,
            onChanged: _toggleBiometricLock,
            icon: Icons.fingerprint,
          ),
          
          const SizedBox(height: 20),
          
          // Last Authentication Time
          _buildInfoRow(
            label: 'Last Authenticated',
            value: _lastAuthTime,
            icon: Icons.access_time,
          ),
          
          const SizedBox(height: 20),
          
          // Retry Limit Slider
          _buildRetryLimitSlider(),
          
          const SizedBox(height: 20),
          
          // Auth for Export Toggle
          _buildToggleSetting(
            title: 'Require Auth for Export',
            subtitle: 'Ask for fingerprint before exporting data',
            value: _requireAuthForExport,
            onChanged: _toggleRequireAuthForExport,
            icon: Icons.download,
          ),
          
          const SizedBox(height: 20),
          
          // Auth for Restore Toggle
          _buildToggleSetting(
            title: 'Require Auth for Restore',
            subtitle: 'Ask for fingerprint before restoring data',
            value: _requireAuthForRestore,
            onChanged: _toggleRequireAuthForRestore,
            icon: Icons.upload,
          ),
          
          const SizedBox(height: 20),
          
          // Test Authentication Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _testAuthentication,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Test Authentication'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSetting({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    required IconData icon,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Color(0xFF7C4DFF), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 28),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF7C4DFF),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Color(0xFF7C4DFF), size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRetryLimitSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.repeat, color: Color(0xFF7C4DFF), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Retry Limit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(0xFF7C4DFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_retryLimit attempts',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C4DFF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Slider(
          value: _retryLimit.toDouble(),
          min: 3,
          max: 10,
          divisions: 7,
          label: '$_retryLimit',
          activeColor: const Color(0xFF7C4DFF),
          onChanged: _setRetryLimit,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text('10', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleBiometricLock(bool value) async {
    await _prefs.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _isBiometricEnabled = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Biometric lock enabled' : 'Biometric lock disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _setRetryLimit(double value) async {
    final newLimit = value.toInt();
    await _prefs.setAuthRetryLimit(newLimit);
    if (mounted) {
      setState(() => _retryLimit = newLimit);
    }
  }

  Future<void> _toggleRequireAuthForExport(bool value) async {
    await _prefs.setRequireAuthForExport(value);
    if (mounted) {
      setState(() => _requireAuthForExport = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Export auth enabled' : 'Export auth disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleRequireAuthForRestore(bool value) async {
    await _prefs.setRequireAuthForRestore(value);
    if (mounted) {
      setState(() => _requireAuthForRestore = value);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value ? 'Restore auth enabled' : 'Restore auth disabled'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testAuthentication() async {
    try {
      final result = await _securityService.authenticateUser(forceAuthentication: true);
      
      if (mounted) {
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Authentication successful'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          // Refresh last auth time
          await _loadSecuritySettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Authentication failed or cancelled'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A2A3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 8),
              const Text(
                'Database Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_transactionCount',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Database Size',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dbSize,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C4DFF),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestoreSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A2A3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.backup, color: Color(0xFF4ECDC4)),
              const SizedBox(width: 8),
              const Text(
                'Data Management',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Backup your expense data to keep it safe, or restore from a previous backup file.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          
          // Backup Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleBackup,
              icon: const Icon(Icons.cloud_upload),
              label: const Text('Backup Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Restore Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleRestore,
              icon: const Icon(Icons.cloud_download),
              label: const Text('Restore Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE74C3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Info message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Backups are saved as .db files. Keep them safe in cloud storage or external drives.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[300],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF2A2A3E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Color(0xFF7C4DFF)),
              const SizedBox(width: 8),
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'My Expense Tracker',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your income and expenses with ease. All amounts in Euro (€).',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBackup() async {
    try {
      // Check if auth is required for export
      if (_requireAuthForExport) {
        final authenticated = await _securityService.authenticateUser(forceAuthentication: true);
        if (!authenticated) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentication required to backup data'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        }
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Perform backup
      final success = await BackupRestoreService.shareBackup();

      // Close loading
      if (mounted) {
        Navigator.pop(context);
      }

      // Show result
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '✓ Database backup created and shared!'
                  : '✗ Failed to create backup',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading if still open
      if (mounted) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    // Check if auth is required for restore
    if (_requireAuthForRestore) {
      final authenticated = await _securityService.authenticateUser(forceAuthentication: true);
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required to restore data'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    }

    // Show confirmation dialog
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B23),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Restore Database', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will replace all current data with the backup file.\n\nThis action cannot be undone.\n\nAre you sure you want to restore?',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Restore'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      // Show loading with detailed message
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              backgroundColor: const Color(0xFF1A1B23),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Restoring database...',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a moment. Please wait...',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Perform restore
      final success = await BackupRestoreService.importDatabase();

      // Close loading dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (success) {
        // Reload database info
        await _loadDatabaseInfo();
        
        // Notify parent to refresh
        widget.onDatabaseRestored();
        
        // Show success message with longer duration
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Database restored successfully!\nPlease restart the app to apply changes.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✗ Failed to restore database. Please check if the file is valid.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
