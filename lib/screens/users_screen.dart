import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_item.dart';
import '../providers/app_providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  List<UserItem> allUsers = [];
  List<UserItem> filteredUsers = [];
  bool loading = false;
  String keyword = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(loadUsers);
  }

  Future<void> loadUsers() async {
    final server = ref.read(activeServerProvider);
    if (server == null) return;

    setState(() => loading = true);
    try {
      final users = await ref.read(apiServiceProvider).getUsers(server);
      setState(() {
        allUsers = users;
        filteredUsers = _applyFilter(users, keyword);
      });
    } catch (_) {
      setState(() {
        allUsers = [];
        filteredUsers = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }

  List<UserItem> _applyFilter(List<UserItem> users, String q) {
    if (q.trim().isEmpty) return users;
    return users
        .where((u) => u.username.toLowerCase().contains(q.toLowerCase()))
        .toList();
  }

  Future<void> _renewUser(String username) async {
    final daysC = TextEditingController(text: '30');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renew User'),
        content: TextField(
          controller: daysC,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Days'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final server = ref.read(activeServerProvider);
              if (server == null) return;
              try {
                await ref.read(apiServiceProvider).renewUser(
                      server,
                      password: username,
                      days: int.tryParse(daysC.text.trim()) ?? 30,
                    );
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Renew berhasil')),
                );
                await loadUsers();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Renew gagal: $e')),
                );
              }
            },
            child: const Text('Renew'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(String username) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Yakin mau hapus user "$username"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final server = ref.read(activeServerProvider);
    if (server == null) return;

    try {
      await ref.read(apiServiceProvider).deleteUser(server, password: username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User berhasil dihapus')),
      );
      await loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete gagal: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final server = ref.watch(activeServerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Users',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(onPressed: loadUsers, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: server == null
          ? const Center(child: Text('Belum ada server aktif'))
          : RefreshIndicator(
              onRefresh: loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    onChanged: (v) {
                      setState(() {
                        keyword = v;
                        filteredUsers = _applyFilter(allUsers, v);
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Cari user...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (loading) const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${filteredUsers.length} user',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  if (!loading && filteredUsers.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(18),
                        child: Text('Belum ada data user'),
                      ),
                    ),
                  ...filteredUsers.map(
                    (u) => Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(14),
                        title: Text(
                          u.username,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (u.status != null) Text('Status: ${u.status}'),
                            if (u.expireAt != null) Text('Expire: ${u.expireAt}'),
                            if (u.daysLeft != null) Text('Sisa hari: ${u.daysLeft}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'renew') _renewUser(u.username);
                            if (v == 'delete') _deleteUser(u.username);
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'renew', child: Text('Renew')),
                            PopupMenuItem(value: 'delete', child: Text('Delete')),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}