/// Example of how to integrate the Email Verification Test Helper
/// Add this to any screen where you want quick testing access

import 'package:flutter/material.dart';
import 'package:kind_clock/utils/email_verification_test_helper.dart';

class ExampleScreenWithTesting extends StatelessWidget {
  const ExampleScreenWithTesting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Example Screen'),
        // Add test button to app bar for easy access
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: EmailVerificationTestHelper.testEmailVerification,
            tooltip: 'Test Email Verification',
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Your regular app content here'),
            SizedBox(height: 20),
            Text('🧪 Tap the bug icon in the app bar to test email verification'),
          ],
        ),
      ),
      // Or add the floating action button for testing
      floatingActionButton: EmailVerificationTestHelper.buildTestFAB(),
    );
  }
}

/// Alternative: Add to your main home screen for easy access
class HomeScreenWithTesting extends StatelessWidget {
  const HomeScreenWithTesting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TIRI'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('TIRI Menu'),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            // Add testing option to drawer
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Test Email Verification'),
              onTap: () {
                Navigator.pop(context);
                EmailVerificationTestHelper.testEmailVerification();
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text('Welcome to TIRI'),
      ),
    );
  }
}

/// Quick test from anywhere in the app
/// Just call this function from any button or action
void quickEmailVerificationTest() {
  EmailVerificationTestHelper.testEmailVerification();
}
