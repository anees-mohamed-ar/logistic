import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:logistic/controller/gc_form_controller.dart';

class SessionTimerWidget extends StatelessWidget {
  const SessionTimerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GCFormController>();
    
    return Obx(() {
      final isFillingTemporary = controller.isFillTemporaryMode.value;

      if (!isFillingTemporary || !controller.isSessionActive.value) {
        return const SizedBox.shrink();
      }

      final minutes = controller.timeRemaining.value.inMinutes.remainder(60);
      final seconds = controller.timeRemaining.value.inSeconds.remainder(60);
      
      // Determine color based on remaining time
      Color timerColor;
      if (controller.timeRemaining.value.inMinutes < 5) {
        timerColor = Colors.red;
      } else if (controller.timeRemaining.value.inMinutes < 15) {
        timerColor = Colors.orange;
      } else {
        timerColor = Theme.of(context).primaryColor;
      }
      
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: timerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: timerColor.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 18,
              color: timerColor,
            ),
            const SizedBox(width: 6),
            Text(
              '${controller.timeRemaining.value.inHours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: timerColor,
              ),
            ),
            if (controller.timeRemaining.value.inMinutes < 15) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: controller.extendSession,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: timerColor.withOpacity(0.1),
                ),
                child: const Text('Extend', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      );
    });
  }
}
