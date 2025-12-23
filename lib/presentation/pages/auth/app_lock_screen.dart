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
child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            Widget buildHeader() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter PIN',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
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
                          color: index < pinFn.value.length
                              ? Colors.white
                              : Colors.white24,
                          border: Border.all(color: Colors.white),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  if (errorFn.value.isNotEmpty)
                    Text(
                      errorFn.value,
                      style:
                          const TextStyle(color: Colors.redAccent, fontSize: 16),
                    ),
                ],
              );
            }

            Widget buildKeypad({required bool isLandscape}) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: isLandscape ? 1.6 : 1.2,
                  crossAxisSpacing: isLandscape ? 16 : 24,
                  mainAxisSpacing: isLandscape ? 16 : 24,
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
                        child: FittedBox(
                          child: Text(
                            number.toString(),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 28),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }

            if (isLandscape) {
              return Center(
                child: SizedBox(
                  width: 900,
                  child: Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: buildHeader(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32.0, vertical: 16),
                                child: buildKeypad(isLandscape: true),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 32),
                        buildHeader(),
                        SizedBox(height: errorFn.value.isNotEmpty ? 48 : 24),
                        // Number Pad
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: buildKeypad(isLandscape: false),
                        ),
                        SizedBox(height: constraints.maxHeight * 0.1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


