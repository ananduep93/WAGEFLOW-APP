import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/providers/firebase_provider.dart';
import '../../models/project.dart';
import '../../core/constants/app_colors.dart';
import 'project_detail_screen.dart';

final projectsStreamProvider = StreamProvider<List<Project>>((ref) {
  return ref.watch(firebaseServiceProvider).getProjects();
});

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsStreamProvider);

    return Scaffold(
      body: projectsAsync.when(
        data: (projects) {
          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.architecture, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('No projects yet. Add your first site!', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: const Icon(Icons.business, color: AppColors.primary),
                  ),
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(project.location, style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Contract: ₹${project.contractAmount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProjectDetailScreen(project: project)),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddProjectDialog(context, ref),
        label: const Text('Add Site'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Site'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Site Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Contract Amount (₹) (Optional)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final project = Project(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  location: locationController.text.trim(),
                  contractAmount: double.tryParse(amountController.text) ?? 0,
                  businessId: '', // Set by service
                  createdAt: DateTime.now(),
                );
                await ref.read(firebaseServiceProvider).addProject(project);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create Site'),
          ),
        ],
      ),
    );
  }
}
