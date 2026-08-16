import 'package:flutter/material.dart';

import '../models/analysis_result.dart';

class MetricTile extends StatelessWidget {
  final MetricResult metric;

  const MetricTile({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (metric.status) {
      MetricStatus.notConnected => (Icons.hourglass_empty, Colors.grey),
      MetricStatus.good => (Icons.check_circle, Colors.green),
      MetricStatus.needsWork => (Icons.error_outline, Colors.orange),
    };

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(metric.label),
      subtitle: metric.note != null ? Text(metric.note!) : null,
    );
  }
}
