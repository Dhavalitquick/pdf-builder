import 'package:flutter/material.dart';
import 'package:pdf_builder/features/subscription/subscription_screen.dart';

void showPaywallDialog(BuildContext context, {String message = 'Upgrade to Premium to unlock unlimited conversions, OCR, and Password Protection!'}) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.stars, color: Colors.amber),
          SizedBox(width: 8),
          Text('Premium Required'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
          child: const Text('View Plans'),
        ),
      ],
    ),
  );
}
