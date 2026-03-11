import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/server_config.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref.read(storageServiceProvider));
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService storage;
  ThemeModeNotifier(this.storage) : super(ThemeMode.system) {
    load();
  }

  Future<void> load() async {
    state = await storage.loadThemeMode();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await storage.saveThemeMode(mode);
  }
}

final serversProvider =
    StateNotifierProvider<ServersNotifier, List<ServerConfig>>((ref) {
  return ServersNotifier(ref.read(storageServiceProvider));
});

final activeServerProvider = Provider<ServerConfig?>((ref) {
  final servers = ref.watch(serversProvider);
  for (final s in servers) {
    if (s.isActive) return s;
  }
  return servers.isNotEmpty ? servers.first : null;
});

class ServersNotifier extends StateNotifier<List<ServerConfig>> {
  final StorageService storage;
  ServersNotifier(this.storage) : super([]) {
    load();
  }

  Future<void> load() async {
    state = await storage.loadServers();
  }

  Future<void> addServer(ServerConfig server) async {
    final list = [...state];
    if (list.isEmpty) {
      list.add(server.copyWith(isActive: true));
    } else {
      list.add(server);
    }
    state = list;
    await storage.saveServers(state);
  }

  Future<void> updateServer(ServerConfig server) async {
    state = state.map((e) => e.id == server.id ? server : e).toList();
    await storage.saveServers(state);
  }

  Future<void> deleteServer(String id) async {
    final list = state.where((e) => e.id != id).toList();
    if (list.isNotEmpty && !list.any((e) => e.isActive)) {
      list[0] = list[0].copyWith(isActive: true);
    }
    state = list;
    await storage.saveServers(state);
  }

  Future<void> setActive(String id) async {
    state = state
        .map((e) => e.copyWith(isActive: e.id == id))
        .toList(growable: false);
    await storage.saveServers(state);
  }
}