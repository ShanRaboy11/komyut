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
      // The background for the overall progress bar container remains transparent
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min, // To wrap content horizontally
        children: _buildStepIndicators(),
      ),
    );
  }

  List<Widget> _buildStepIndicators() {
    List<Widget> indicators = [];
    for (int i = 0; i < steps.length; i++) {
      final step = steps[i];
      final bool isLastStep = i == steps.length - 1;

      // Add the step circle and its title
      indicators.add(_buildStep(step, i)); // Pass the whole step and its index

      if (!isLastStep) {
        indicators.add(
          _buildStepDivider(
            steps[i].isCompleted || steps[i + 1].isActive || steps[i+1].isCompleted, // Divider connects if current step is completed OR next step is active/completed
          ),
        );
      }
    }
    return indicators;
  }

  // Refactored to build the circle and text together
  Widget _buildStep(ProgressBarStep step, int index) {
    Color activeColor = const Color.fromRGBO(185, 69, 170, 1); // Your figma purple
    Color inactiveColor = const Color.fromRGBO(198, 198, 198, 1); // Light grey for inactive border/text
    Color completedColor = const Color.fromRGBO(0, 67, 206, 1); // Blue for completed

    Color circleBorderColor = step.isCompleted
        ? completedColor
        : step.isActive
        ? activeColor
        : inactiveColor;

    Widget? innerWidget;
    Color circleFillColor = Colors.transparent; // Default to transparent for active/inactive

    if (step.isCompleted) {
      innerWidget = const Icon(
        Icons.check,
        size: 12,
        color: Colors.transparent,
      );
      circleFillColor = completedColor; // Fill blue if completed
    } else if (step.isActive) {
      innerWidget = Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor, // Inner dot for active step
        ),
      );
      // For active, the circleFillColor remains transparent, only border and inner dot
    }
    // If inactive, innerWidget is null and circleFillColor is transparent

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 24, // Slightly larger for better visibility
          height: 24, // Slightly larger for better visibility
          decoration: BoxDecoration(
            shape: BoxShape.circle, // Use BoxShape.circle for perfect circles
            color: circleFillColor,
            border: Border.all(
              color: circleBorderColor,
              width: 1.5, // Thicker border for better visibility
            ),
          ),
          child: Center(child: innerWidget),
        ),
        const SizedBox(height: 6), // Increased spacing between circle and text
        Text(
          step.title, // Use the step's title directly
          textAlign: TextAlign.center,
          style: TextStyle(
            color: step.isActive
                ? activeColor // Active text color
                : inactiveColor, // Inactive text color
            fontFamily: 'Nunito',
            fontSize: 12,
            letterSpacing: 0.5,
            fontWeight: FontWeight.normal,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(bool isConnected) {
    return Expanded(
      child: Container(
        height: 1.5, // Thicker divider for better visibility
        color: isConnected
            ? const Color.fromRGBO(185, 69, 170, 1) // Active/connected color
            : const Color.fromRGBO(198, 198, 198, 1), // Inactive/disconnected color
        
      ),
    );
  }
}