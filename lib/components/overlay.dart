import 'package:block_app/block_app.dart';
import 'package:flutter/material.dart';

final blockApp = BlockApp();

// Custom blocking overlay widget
final overlay = blockApp.createDefaultBlockingOverlay(
  customMessage: '⏰ Time Limit Reached!\n\nYou have reached your daily limit for this app. Take a break and focus on other activities.',
  actionButtonText: 'Okay, I understand',
  backgroundColor: Colors.black.withOpacity(0.95),
  textColor: Colors.white,
);