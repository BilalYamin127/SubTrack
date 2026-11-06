import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LegalScreen extends StatelessWidget {
  final String title, asset;
  const LegalScreen({super.key, required this.title, required this.asset});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<String>(
      future: rootBundle.loadString(asset),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Document unavailable. Please reopen SubTrack.'),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SelectableText(
                snapshot.data!.replaceAll(
                  RegExp(r'^#{1,3} ', multiLine: true),
                  '',
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
          ),
        );
      },
    ),
  );
}
