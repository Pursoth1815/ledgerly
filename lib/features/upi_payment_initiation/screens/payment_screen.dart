import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/features/upi_payment_initiation/providers/providers.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ledgerly/theme/themes.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class PaymentPage extends HookConsumerWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final step = ref.watch(paymentStepProvider);

    // controller
    final controller = useAnimationController(duration: const Duration(milliseconds: 450));

    // animation value: 0 → 1 → 2
    final animation = useMemoized(
      () => Tween<double>(begin: 0, end: 2).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic)),
      [controller],
    );

    // react to step change
    useEffect(() {
      final target = step.index.toDouble();
      controller.animateTo(
        target / 2, // normalize (0–1)
      );
      return null;
    }, [step]);

    return Scaffold(
      backgroundColor: AppColors.gray100,
      body: SafeArea(
        child: Column(
          children: [
            PaymentStepper(animation: animation),
            const SizedBox(height: 24),
            Expanded(child: _buildStep(step, ref)),
          ],
        ),
      ),
    );
  }
}

Widget _buildStep(PaymentStep step, ref) {
  switch (step) {
    case PaymentStep.summary:
      return InkWell(
        onTap: () {
          ref.read(paymentStepProvider.notifier).state = PaymentStep.method;
        },
        child: Container(width: 150, color: AppColors.redAccent),
      );

    case PaymentStep.method:
      return Container();

    case PaymentStep.result:
      return Container();
  }
}

class PaymentStepper extends StatelessWidget {
  final Animation<double> animation;

  const PaymentStepper({super.key, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: StepProgressIndicator(
            totalSteps: 3,
            currentStep: animation.value.round() + 1,
            size: 12,
            padding: 8,
            roundedEdges: const Radius.circular(12),

            // circles
            selectedColor: AppColors.primary,
            unselectedColor: AppColors.primary.withOpacity(0.3),

            // fill
            customStep: (index, color, _) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: index < animation.value + 1 ? AppColors.primary : AppColors.primary.withOpacity(0.3),
                    width: 3,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}



//ref.read(paymentStepProvider.notifier).state = PaymentStep.method; 
