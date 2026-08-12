import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../widgets/ad_banner.dart';

class SuccessScreen extends StatelessWidget {
  final String filePath;

  const SuccessScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Matching the off-white from HomeScreen
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Task Complete',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600), // Web/Desktop constraint
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Success Icon & Decoration
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFA5D6A7), width: 2),
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2E7D32),
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Typography Hierarchy
                        Text(
                          'Success! File Saved.',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E1E1E),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        
                        if (!kIsWeb && filePath != 'Web Download')
                          Text(
                            'Your file has been processed locally and saved securely to:\n$filePath',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF757575),
                                  height: 1.5,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 48),

                        // Action Buttons (Material 3 Style)
                        if (!kIsWeb)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F), // Crimson Red
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                if (filePath != 'Web Download') {
                                  OpenFilex.open(filePath);
                                }
                              },
                              icon: const Icon(Icons.folder_open_rounded),
                              label: const Text(
                                'Open File',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E1E1E),
                              side: const BorderSide(color: Color(0xFFE0E0E0), width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              // Navigate back to the home screen grid
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text(
                              'Back to Dashboard',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // The ad banner sits safely at the bottom during the high-linger success state
            const AdBannerWidget(), 
          ],
        ),
      ),
    );
  }
}