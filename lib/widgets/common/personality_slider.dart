import 'package:flutter/material.dart';

class PersonalitySlider extends StatelessWidget {
  final String label;
  final Color color;
  final double value;
  final ValueChanged<double> onChanged;
  final String leftLabel;
  final String rightLabel;

  const PersonalitySlider({
    Key? key,
    required this.label,
    required this.color,
    required this.value,
    required this.onChanged,
    required this.leftLabel,
    required this.rightLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
          ),
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 60,
              thumbShape: RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 2,
              ),
              overlayShape: SliderComponentShape.noOverlay,
              activeTrackColor: color.withOpacity(0.6),
              inactiveTrackColor: Colors.transparent,
              thumbColor: color,
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              leftLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value.round().toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            Text(
              rightLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }
} 