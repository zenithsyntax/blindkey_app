import 'package:blindkey_app/application/providers.dart';
import 'package:blindkey_app/application/store/folder_notifier.dart';
import 'package:blindkey_app/presentation/dialogs/create_folder_dialog.dart';
import 'package:blindkey_app/presentation/pages/folder_view_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(folderNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BlindKey'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _importVault(context, ref),
            tooltip: "Import .blindkey",
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Keep Your Files Secure',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ),
      ),
      body: foldersAsync.when(
        data: (folders) {
          if (folders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('No Vaults Created Yet'),
                   const SizedBox(height: 24),
                   ElevatedButton.icon(
                     onPressed: () => _showCreateFolderDialog(context),
                     icon: const Icon(Icons.add),
                     label: const Text('Create Folder'),
                   ),
                   const SizedBox(height: 12),
                   OutlinedButton.icon(
                     onPressed: () => _importVault(context, ref),
                     icon: const Icon(Icons.upload_file),
                     label: const Text('Upload .blindkey'),
                   ),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return Card(
                child: InkWell(
                  onTap: () => _openFolder(context, ref, folder),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder, size: 50, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text(
                          folder.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${folder.id.substring(0, 4)}...',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        error: (e, s) => Center(child: Text('Error: $e')),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateFolderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateFolderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const CreateFolderDialog(),
    );
  }

  Future<void> _importVault(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // .blindkey is custom
      // allowedExtensions: ['blindkey'], // FileType.custom
    );
    
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      
      // Prompt for password
      final passwordController = TextEditingController();
      if (!context.mounted) return;
      
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Import Vault'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Vault Password'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final vault = ref.read(vaultServiceProvider);
                final importRes = await vault.importBlindKey(path, passwordController.text);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close Dialog
                  importRes.fold(
                    (l) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import Failed: $l'))),
                    (r) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import Successful')));
                      ref.refresh(folderNotifierProvider);
                    }
                  );
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _openFolder(BuildContext context, WidgetRef ref, dynamic folder) async {
    // Prompt for password
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Unlock ${folder.name}'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Enter Password'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              // Verify Password
              final vault = ref.read(vaultServiceProvider);
              final keyResult = await vault.verifyPasswordAndGetKey(folder, passwordController.text);
              if (keyResult.isRight()) {
                final key = keyResult.getOrElse(() => throw Exception());
                if (context.mounted) Navigator.pop(context, true); 
                if (context.mounted) {
                   Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => FolderViewPage(folder: folder, folderKey: key),
                    ),
                  );
                }
              } else {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid Password')));
                 }
              }
            },
            child: const Text('Unlock'),
          ),
        ],
      ),
    );
  }
}

