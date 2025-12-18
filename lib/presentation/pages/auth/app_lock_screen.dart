import 'package:blindkey_app/application/auth/app_lock_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppLockScreen extends HookConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(appLockNotifierProvider.notifier);
    // Local state for PIN entry
    final pinFn = useState('');
    final errorFn = useState('');

    // Biometrics removed
    /* useEffect(() { ... }); */

    void onNumberTap(String number) {
      if (pinFn.value.length < 4) {
        pinFn.value += number;
        errorFn.value = '';
        if (pinFn.value.length == 4) {
          // Verify
          notifier.verifyPin(pinFn.value).then((isValid) {
            if (!isValid) {
              errorFn.value = 'Incorrect PIN';
              pinFn.value = '';
            }
          });
        }
      }
    }

    void onDeleteTap() {
      if (pinFn.value.isNotEmpty) {
        pinFn.value = pinFn.value.substring(0, pinFn.value.length - 1);
        errorFn.value = '';
      }
    }

    return Scaffold(
      backgroundColor: Colors.black, // High contrast
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.white),
            const SizedBox(height: 32),
            const Text(
              'Enter PIN',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < pinFn.value.length ? Colors.white : Colors.white24,
                    border: Border.all(color: Colors.white),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            if (errorFn.value.isNotEmpty)
              Text(
                errorFn.value,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            const SizedBox(height: 48),

            // Number Pad
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                       return const SizedBox();
                    }
                    if (index == 11) {
                      // Delete button
                      return InkWell(
                        onTap: onDeleteTap,
                        customBorder: const CircleBorder(),
                        child: const Center(
                          child: Icon(Icons.backspace, color: Colors.white),
                        ),
                      );
                    }
                    
                    final number = (index == 10) ? 0 : index + 1;
                    return InkWell(
                      onTap: () => onNumberTap(number.toString()),
                      customBorder: const CircleBorder(),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            number.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


