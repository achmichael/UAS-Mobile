import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app_limiter/types/entities.dart';

class ListItem extends StatefulWidget {
  final List<AppUsageWithIcon> items;

  const ListItem({super.key, required this.items});

  @override
  State<ListItem> createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final AppUsageWithIcon usage = (
          packageName: item.packageName,
          appName: item.appName,
          usage: item.usage,
          icon: item.icon,
        );
        final usageMinutes = usage.usage.inMinutes;
        const totalMinutesInDay = 24 * 60; 
        final progress = (usageMinutes / totalMinutesInDay).clamp(0.0, 1.0);
        return ListTile(
          leading: usage.icon != null
              ? Image.memory(usage.icon!, width: 40, height: 40)
              : const Icon(Icons.apps),
          title: Text(usage.appName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.white),),
          subtitle: Text("Durasi: ${usageMinutes.toString()} menit", style: TextStyle(color: Colors.grey[300]),),
          trailing: SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LinearProgressIndicator(
                  value: progress,
                  color: AppColors.primary,
                  backgroundColor: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(12),
                  minHeight: 6,
                ),
                const SizedBox(height: 2),
                Text('${usageMinutes}m', style: const TextStyle(fontSize: 12, color: AppColors.white)),
              ],
            ),
          ),
        );
      },
    );
  }
}
