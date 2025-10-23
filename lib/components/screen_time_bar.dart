import 'package:app_limiter/core/common/helper.dart';
import 'package:app_limiter/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

class ScreenTimeBar extends StatefulWidget {
  final Duration screenTime;
  const ScreenTimeBar({super.key, required this.screenTime});

  @override
  State<ScreenTimeBar> createState() => _ScreenTimeBarState();
}

class _ScreenTimeBarState extends State<ScreenTimeBar> {
  String _formattedDuration = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    String result = formatDuration(widget.screenTime);
    double p = widget.screenTime.inSeconds / Duration(hours: 24).inSeconds;
    setState(() {
      _formattedDuration = result;
      _progress = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 10, left: 25, right: 25, bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Screen Time Today',
                style: TextStyle(color: Colors.grey[200], fontSize: 14),
              ),
              Text(
                _formattedDuration,
                style: TextStyle(color: Colors.grey[200]),
              ),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: _progress,
            color: AppColors.primary,
            backgroundColor: Colors.grey,
            borderRadius: BorderRadius.circular(12),
            minHeight: 10,
          ),
        ],
      ),
    );
  }
}
