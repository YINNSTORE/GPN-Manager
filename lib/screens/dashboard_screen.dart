import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/server_config.dart';
import '../models/user_item.dart';
import '../providers/app_providers.dart';
import 'users_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const DashboardHomeTab(),
      const UsersScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: pages[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (v) => setState(() => currentIndex = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.people_alt_rounded), label: 'Users'),
          NavigationDestination(icon: Icon(Icons.settings_rounded), label: 'Settings'),
        ],
      ),
    );
  }
}

class DashboardHomeTab extends ConsumerStatefulWidget {
  const DashboardHomeTab({super.key});

  @override
  ConsumerState<DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends ConsumerState<DashboardHomeTab> {
  Map<String, dynamic>? info;
  List<UserItem> users = [];
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final server = ref.read(activeServerProvider);
    if (server == null) {
      setState(() {
        info = null;
        users = [];
        error = null;
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final api = ref.read(apiServiceProvider);
      final i = await api.getInfo(server);
      final u = await api.getUsers(server);
      setState(() {
        info = i;
        users = u;
      });
    } catch (e) {
      setState(() {
        error = 'Gagal ambil data: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _showServerDialog({ServerConfig? server}) async {
    final nameC = TextEditingController(text: server?.name ?? '');
    final hostC = TextEditingController(text: server?.host ?? '');
    final keyC = TextEditingController(text: server?.apiKey ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Consumer(
            builder: (context, ref, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    server == null ? 'Tambah Server' : 'Edit Server',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(labelText: 'Nama Server'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hostC,
                    decoration: const InputDecoration(labelText: 'Domain / IP VPS'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyC,
                    decoration: const InputDecoration(labelText: 'API Key'),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final temp = ServerConfig(
                              id: 'tmp',
                              name: nameC.text.trim().isEmpty ? 'Server' : nameC.text.trim(),
                              host: hostC.text.trim(),
                              apiKey: keyC.text.trim(),
                              isActive: true,
                            );
                            try {
                              await ref.read(apiServiceProvider).getInfo(temp);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Koneksi sukses')),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Koneksi gagal: $e')),
                              );
                            }
                          },
                          child: const Text('Test'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final host = hostC.text.trim();
                            final apiKey = keyC.text.trim();
                            if (host.isEmpty || apiKey.isEmpty) return;

                            final item = ServerConfig(
                              id: server?.id ?? _randomId(),
                              name: nameC.text.trim().isEmpty
                                  ? 'Server ${Random().nextInt(999)}'
                                  : nameC.text.trim(),
                              host: host,
                              apiKey: apiKey,
                              isActive: server?.isActive ?? false,
                            );

                            if (server == null) {
                              await ref.read(serversProvider.notifier).addServer(item);
                            } else {
                              await ref.read(serversProvider.notifier).updateServer(item);
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            await _load();
                          },
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _switchServerDialog() async {
    final servers = ref.read(serversProvider);
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Server',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...servers.map(
                (s) => Card(
                  child: ListTile(
                    title: Text(s.name),
                    subtitle: Text(s.host),
                    trailing: s.isActive
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    onTap: () async {
                      await ref.read(serversProvider.notifier).setActive(s.id);
                      if (!mounted) return;
                      Navigator.pop(context);
                      await _load();
                    },
                    onLongPress: () => _showServerDialog(server: s),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _triggerExpire() async {
    final server = ref.read(activeServerProvider);
    if (server == null) return;
    try {
      await ref.read(apiServiceProvider).triggerExpire(server);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trigger expire berhasil')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal trigger expire: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(activeServerProvider);
    final servers = ref.watch(serversProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'GPTN Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServerDialog(),
        label: const Text('Add Server'),
        icon: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            if (servers.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 48, color: cs.primary),
                      const SizedBox(height: 10),
                      const Text(
                        'Belum ada server',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tambahin domain/IP VPS dan API Key dulu biar dashboard bisa jalan.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _showServerDialog(),
                        child: const Text('Tambah Server'),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.dns_rounded, color: cs.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server?.name ?? '-',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(server?.host ?? '-'),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: _switchServerDialog,
                        child: const Text('Switch'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (loading) const LinearProgressIndicator(),
              if (error != null) ...[
                Text(error!, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _statCard(
                      context,
                      'Total Users',
                      '${users.length}',
                      Icons.people_alt_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _statCard(
                      context,
                      'Status',
                      error == null ? 'Online' : 'Error',
                      Icons.wifi_tethering_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _infoCard(context),
              const SizedBox(height: 16),
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _actionButton(
                    context,
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Create User',
                    onTap: () => _showCreateDialog(isTrial: false),
                  ),
                  _actionButton(
                    context,
                    icon: Icons.bolt_rounded,
                    label: 'Create Trial',
                    onTap: () => _showCreateDialog(isTrial: true),
                  ),
                  _actionButton(
                    context,
                    icon: Icons.timer_outlined,
                    label: 'Expire Check',
                    onTap: _triggerExpire,
                  ),
                  _actionButton(
                    context,
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    onTap: _load,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String title, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(BuildContext context) {
    final entries = info?.entries.toList() ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: entries.isEmpty
            ? const Text('Belum ada system info')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...entries.take(8).map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(e.key)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${e.value}',
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 44) / 2,
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Future<void> _showCreateDialog({required bool isTrial}) async {
    final server = ref.read(activeServerProvider);
    if (server == null) return;

    final userC = TextEditingController();
    final durationC = TextEditingController(text: isTrial ? '60' : '30');

    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(isTrial ? 'Create Trial User' : 'Create User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userC,
                decoration: const InputDecoration(labelText: 'Password / Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationC,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isTrial ? 'Minutes' : 'Days',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  final api = ref.read(apiServiceProvider);
                  if (isTrial) {
                    await api.createUser(
                      server,
                      password: userC.text.trim(),
                      minutes: int.tryParse(durationC.text.trim()) ?? 60,
                    );
                  } else {
                    await api.createUser(
                      server,
                      password: userC.text.trim(),
                      days: int.tryParse(durationC.text.trim()) ?? 30,
                    );
                  }
                  if (!mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User berhasil dibuat')),
                  );
                  await _load();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal create user: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  String _randomId() => DateTime.now().millisecondsSinceEpoch.toString();
}