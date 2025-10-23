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
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Social', 'Games', 'Ent.', 'Productivity'];

  // Map kategori berdasarkan package name atau app name
  String _getCategoryForApp(String packageName, String appName) {
    final lowerPackage = packageName.toLowerCase();
    final lowerName = appName.toLowerCase();

    // Social apps
    if (lowerPackage.contains('facebook') ||
        lowerPackage.contains('instagram') ||
        lowerPackage.contains('twitter') ||
        lowerPackage.contains('whatsapp') ||
        lowerPackage.contains('telegram') ||
        lowerPackage.contains('snapchat') ||
        lowerPackage.contains('tiktok')) {
      return 'Social';
    }

    // Games
    if (lowerPackage.contains('game') ||
        lowerPackage.contains('play') ||
        lowerName.contains('game')) {
      return 'Games';
    }

    // Entertainment
    if (lowerPackage.contains('spotify') ||
        lowerPackage.contains('youtube') ||
        lowerPackage.contains('netflix') ||
        lowerPackage.contains('music') ||
        lowerPackage.contains('video')) {
      return 'Ent.';
    }

    // Productivity
    if (lowerPackage.contains('chrome') ||
        lowerPackage.contains('calendar') ||
        lowerPackage.contains('gmail') ||
        lowerPackage.contains('docs') ||
        lowerPackage.contains('drive') ||
        lowerPackage.contains('office') ||
        lowerPackage.contains('outlook')) {
      return 'Productivity';
    }

    return 'Productivity'; // Default
  }

  List<AppUsageWithIcon> _getFilteredItems() {
    if (selectedCategory == 'All') {
      return widget.items;
    }

    return widget.items.where((item) {
      final category = _getCategoryForApp(item.packageName, item.appName);
      return category == selectedCategory;
    }).toList();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Color _getCategoryColor(String appName, String packageName) {
    final category = _getCategoryForApp(packageName, appName);
    switch (category) {
      case 'Social':
        return Colors.pink;
      case 'Games':
        return Colors.purple;
      case 'Ent.':
        return Colors.green;
      case 'Productivity':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _getFilteredItems();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Text(
            'App Usage',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Category Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: categories.map((category) {
              final isSelected = selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(
                    category,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = category;
                    });
                  },
                  backgroundColor: const Color(0xFF1E293B),
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        // App List
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Text(
                    'No apps in this category',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final usageMinutes = item.usage.inMinutes;
                    const totalMinutesInDay = 24 * 60;
                    final progress = (usageMinutes / totalMinutesInDay).clamp(0.0, 1.0);
                    final categoryColor = _getCategoryColor(item.appName, item.packageName);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // App Icon
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: item.icon != null
                                ? Image.memory(
                                    item.icon!,
                                    width: 32,
                                    height: 32,
                                    fit: BoxFit.contain,
                                  )
                                : Icon(
                                    Icons.apps,
                                    color: categoryColor,
                                    size: 32,
                                  ),
                          ),

                          const SizedBox(width: 16),

                          // App Name and Category
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.appName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getCategoryForApp(item.packageName, item.appName),
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Usage Time and Progress Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _formatDuration(item.usage),
                                style: const TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    color: categoryColor,
                                    backgroundColor: Colors.grey.shade800,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}