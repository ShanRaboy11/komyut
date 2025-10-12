// lib/features/registration/widgets/progress_bar.dart
import 'package:flutter/material.dart';

class ProgressBarStep {
  final String title;
  final bool isCompleted;
  final bool isActive;

  ProgressBarStep({
    required this.title,
    this.isCompleted = false,
    this.isActive = false,
  });
}

class ProgressBar extends StatelessWidget {
  final List<ProgressBarStep> steps;

  const ProgressBar({Key? key, required this.steps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row for circles and lines
          Row(
            children: _buildStepIndicators(),
          ),
          const SizedBox(height: 6),
          // Row for labels
          Row(
            children: _buildStepLabels(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final bool isLastStep = i == steps.length - 1;

      // Add the step circle
      indicators.add(_buildStepCircle(step));

      if (!isLastStep) {
        indicators.add(
          _buildStepDivider(
            steps[i].isCompleted || steps[i + 1].isActive || steps[i + 1].isCompleted,
          ),
        );
      }
    }
    return indicators;
  }

  List<Widget> _buildStepLabels() {
    List<Widget> labels = [];
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final bool isLastStep = i == steps.length - 1;

      // Add the label
      labels.add(_buildStepLabel(step));

      if (!isLastStep) {
        // Add spacer to match the divider width
        labels.add(const Expanded(child: SizedBox()));
      }
    }
    return labels;
  }

  Widget _buildStepCircle(ProgressBarStep step) {
    Color activeColor = const Color.fromRGBO(185, 69, 170, 1);
    Color inactiveColor = const Color.fromRGBO(198, 198, 198, 1);
    Color completedColor = const Color.fromRGBO(185, 69, 170, 1); // Changed to purple

    Color circleBorderColor = step.isCompleted
        ? completedColor
        : step.isActive
            ? activeColor
            : inactiveColor;

    Widget? innerWidget;
    Color circleFillColor = Colors.transparent;

    if (step.isCompleted) {
      innerWidget = const Icon(
        Icons.check,
        size: 14,
        color: Colors.white, // White checkmark
      );
      circleFillColor = completedColor; // Purple fill if completed
    } else if (step.isActive) {
      innerWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor,
        ),
      );
    }

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: circleFillColor,
        border: Border.all(
          color: circleBorderColor,
          width: 1.5,
        ),
      ),
      child: Center(child: innerWidget),
    );
  }

  Widget _buildStepLabel(ProgressBarStep step) {
    Color activeColor = const Color.fromRGBO(185, 69, 170, 1);
    Color inactiveColor = const Color.fromRGBO(198, 198, 198, 1);

    return SizedBox(
      width: 24, // Match circle width
      child: Text(
        step.title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: step.isActive || step.isCompleted
              ? activeColor
              : inactiveColor,
          fontFamily: 'Nunito',
          fontSize: 12,
          letterSpacing: 0.5,
          fontWeight: FontWeight.normal,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildStepDivider(bool isConnected) {
    return Expanded(
      child: Container(
        height: 1.5,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        color: isConnected
            ? const Color.fromRGBO(185, 69, 170, 1)
            : const Color.fromRGBO(198, 198, 198, 1),
      ),
    );
  }
}