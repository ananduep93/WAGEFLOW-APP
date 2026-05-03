import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/worker.dart';
import 'package:uuid/uuid.dart';

final workerProvider = StateNotifierProvider<WorkerNotifier, List<Worker>>((ref) {
  return WorkerNotifier();
});

class WorkerNotifier extends StateNotifier<List<Worker>> {
  WorkerNotifier() : super([]) {
    _loadWorkers();
  }

  final _box = Hive.box<Worker>('workers');

  void _loadWorkers() {
    state = _box.values.toList();
  }

  Future<void> addWorker(String name, String phone, double wageRate) async {
    final worker = Worker(
      id: const Uuid().v4(),
      name: name,
      phone: phone,
      wageRate: wageRate,
    );
    await _box.put(worker.id, worker);
    state = [...state, worker];
  }

  Future<void> updateWorker(Worker worker) async {
    await _box.put(worker.id, worker);
    state = [
      for (final w in state)
        if (w.id == worker.id) worker else w
    ];
  }

  Future<void> deleteWorker(String id) async {
    await _box.delete(id);
    state = state.where((w) => w.id != id).toList();
  }
}
