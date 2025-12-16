import 'package:blindkey_app/application/store/folder_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateFolderDialog extends HookConsumerWidget {
  const CreateFolderDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final passwordController = useTextEditingController();
    final confirmPasswordController = useTextEditingController();
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final isMatching = useState(true);

    return AlertDialog(
      title: const Text('Create Secure Folder'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Folder Name'),
              validator: (v) => v!.isEmpty ? 'Name required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              validator: (v) => v!.length < 4 ? 'Min 4 chars' : null,
              onChanged: (_) {
                isMatching.value = passwordController.text == confirmPasswordController.text;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                errorText: isMatching.value ? null : 'Passwords do not match',
              ),
              obscureText: true,
              onChanged: (_) {
                isMatching.value = passwordController.text == confirmPasswordController.text;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate() && isMatching.value) {
              await ref.read(folderNotifierProvider.notifier).createFolder(
                    nameController.text,
                    passwordController.text,
                  );
              // Wait handling for error? Helper `createFolder` updates state.
              // Ideally we check for success.
              // But for now pop.
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
