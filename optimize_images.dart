import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

void main() async {
  // Optimize the large banner image
  final inputFile = File('assets/images/banner_education_1.png');
  final outputFile = File('assets/images/banner_education_1_optimized.png');
  
  if (await inputFile.exists()) {
    print('Optimizing banner_education_1.png...');
    
    final result = await FlutterImageCompress.compressAndGetFile(
      inputFile.absolute.path,
      outputFile.absolute.path,
      minHeight: 600,
      minWidth: 800,
      quality: 80,
    );
    
    if (result != null) {
      final originalSize = await inputFile.length();
      final optimizedSize = await outputFile.length();
      
      print('Original size: ${originalSize ~/ 1024} KB');
      print('Optimized size: ${optimizedSize ~/ 1024} KB');
      print('Saved: ${(originalSize - optimizedSize) ~/ 1024} KB');
      
      // Replace the original file with the optimized one
      await outputFile.rename(inputFile.path);
      print('Image optimized successfully!');
    } else {
      print('Failed to optimize image');
    }
  } else {
    print('Input file not found');
  }
}