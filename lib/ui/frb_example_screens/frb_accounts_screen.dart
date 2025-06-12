import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whitenoise/src/rust/api.dart';

class FrbAccountsScreen extends StatefulWidget {
  const FrbAccountsScreen({super.key});

  @override
  State<FrbAccountsScreen> createState() => _FrbAccountsScreenState();
}

class _FrbAccountsScreenState extends State<FrbAccountsScreen> {
  late Whitenoise _whitenoise;
  WhitenoiseData? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final dataDir = '${dir.path}/whitenoise/data';
      final logsDir = '${dir.path}/whitenoise/logs';

      // ignore: avoid_slow_async_io
      if (!await Directory(dataDir).exists()) {
        // ignore: avoid_slow_async_io
        await Directory(dataDir).create(recursive: true);
      }
      // ignore: avoid_slow_async_io
      if (!await Directory(logsDir).exists()) {
        // ignore: avoid_slow_async_io
        await Directory(logsDir).create(recursive: true);
      }

      final config = await createWhitenoiseConfig(
        dataDir: dataDir,
        logsDir: logsDir,
      );
      _whitenoise = await initializeWhitenoise(config: config);

      await _loadData();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      final data = await getWhitenoiseData(whitenoise: _whitenoise);
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final account = await createIdentity(whitenoise: _whitenoise);
      await updateActiveAccount(whitenoise: _whitenoise, account: account);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Account creation failed: $e')),
      );
    } finally {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    final data = _data!;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListView(
            children: [
              const Text(
                'Whitenoise Accounts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text(
                'Active Account:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                data.activeAccount ?? 'None',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'Accounts:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              for (var entry in data.accounts.entries)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(entry.value.pubkey),
                    subtitle: Text('Synced: ${entry.value.lastSynced}'),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createAccount,
        tooltip: 'Create New Account',
        child: const Icon(Icons.add),
      ),
    );
  }
}
