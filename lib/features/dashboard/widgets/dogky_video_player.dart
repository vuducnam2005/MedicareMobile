import 'package:flutter/material.dart';

class DogkyVideoPlayer extends StatelessWidget {
  final double size;
  const DogkyVideoPlayer({super.key, this.size = 76.0});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/assistant-loop.gif',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
