// loading_dots.dart
import 'package:flutter/material.dart';

class LoadingDots extends StatefulWidget {
  const LoadingDots({Key? key}) : super(key: key);

  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat();

    _animation1 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _animation2 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _animation3 = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _animation1,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animation1.value),
              child: child,
            );
          },
          child: const Dot(),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _animation2,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animation2.value),
              child: child,
            );
          },
          child: const Dot(),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _animation3,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_animation3.value),
              child: child,
            );
          },
          child: const Dot(),
        ),
      ],
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}
