import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: TestImageScreen(),
    );
  }
}

class TestImageScreen extends StatefulWidget {
  @override
  _TestImageScreenState createState() => _TestImageScreenState();
}

class _TestImageScreenState extends State<TestImageScreen> {
  bool _imageLoaded = false;
  bool _errorOccurred = false;

  @override
  void initState() {
    super.initState();
    _testImageLoading();
  }

  Future<void> _testImageLoading() async {
    try {
      // Try to load the image asset
      final byteData = await rootBundle.load('assets/images/banner_education_1.png');
      if (mounted) {
        setState(() {
          _imageLoaded = true;
          _errorOccurred = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorOccurred = true;
          _imageLoaded = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Loading Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageLoaded)
              const Text('✅ Image loaded successfully!', style: TextStyle(fontSize: 18, color: Colors.green))
            else if (_errorOccurred)
              const Text('❌ Error loading image', style: TextStyle(fontSize: 18, color: Colors.red))
            else
              const Text('⏳ Loading image...', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testImageLoading,
              child: const Text('Test Image Loading'),
            ),
            const SizedBox(height: 20),
            // Try to display the image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
              ),
              child: _imageLoaded
                  ? Image.asset(
                      'assets/images/banner_education_1.png',
                      fit: BoxFit.contain,
                    )
                  : _errorOccurred
                      ? const Icon(Icons.error, size: 50, color: Colors.red)
                      : const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}