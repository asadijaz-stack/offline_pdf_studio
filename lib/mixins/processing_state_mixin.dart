import 'package:flutter/material.dart';

/// A mixin to handle common processing state, loading indicators, and error handling
/// across all PDF processing screens (Merge, Split, Compress, Image/PDF conversions).
mixin ProcessingStateMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;

  /// Returns whether a background processing task is currently running.
  bool get isProcessing => _isProcessing;

  /// Executes a [task] asynchronously. 
  /// Automatically sets [_isProcessing] to true, yields to the event loop so the 
  /// UI can show a loading indicator, and catches any errors showing a SnackBar.
  Future<void> runProcessingTask(Future<void> Function() task) async {
    if (_isProcessing) return; // Prevent double taps

    setState(() {
      _isProcessing = true;
    });

    // Allow UI to paint the progress indicator before CPU-bound operations begin
    await Future.delayed(const Duration(milliseconds: 100));

    try {
      await task();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Helper to show a generic error SnackBar
  void showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }
}
