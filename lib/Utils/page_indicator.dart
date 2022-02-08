import 'package:flutter/material.dart';

class CarouselIndicator extends StatefulWidget {
  final double width;

  final double height;

  final double space;

  final int count;

  final Color activeColor;

  final Color color;

  final double cornerRadius;

  final int animationDuration;

  final int index;

  const CarouselIndicator({
    Key? key,
    this.width = 20.0,
    this.height = 6,
    this.space = 5.0,
    required this.count,
    this.cornerRadius = 6,
    this.animationDuration = 300,
    this.color = Colors.white30,
    required this.index,
    this.activeColor = Colors.white,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _CarouselIndicatorState();
  }
}

class _CarouselIndicatorState extends State<CarouselIndicator>
    with TickerProviderStateMixin {
  late Tween<double> _tween;

  late AnimationController _animationController;

  late Animation _animation;

  final Paint _paint = Paint();

  BasePainter _createPainer() {
    return SlidePainter(widget, _animation.value, _paint);
  }

  @override
  Widget build(BuildContext context) {
    Widget child = SizedBox(
      width: widget.count * widget.width + (widget.count - 1) * widget.space,
      height: widget.height,
      child: CustomPaint(
        painter: _createPainer(),
      ),
    );

    return IgnorePointer(
      child: child,
    );
  }

  @override
  void initState() {
    createAnimation(0.0, 0.0);
    super.initState();
  }

  @override
  void didUpdateWidget(CarouselIndicator oldWidget) {
    if (widget.index != oldWidget.index) {
      if (widget.index != 0) {
        _animationController.reset();

        createAnimation(oldWidget.index.toDouble(), widget.index.toDouble());
        _animationController.forward();
      } else {
        _animationController.reset();
        createAnimation(oldWidget.index.toDouble(), 0.0);
        _animationController.forward();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void createAnimation(double begin, double end) {
    _tween = Tween(begin: begin, end: end);
    _animationController = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: widget.animationDuration));
    _animation = _tween.animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }
}

abstract class BasePainter extends CustomPainter {
  final CarouselIndicator widget;
  final double page;
  final Paint _paint;

  BasePainter(this.widget, this.page, this._paint);

  void draw(Canvas canvas, double space, double width, double height,
      double radius, double cornerRadius);

  @override
  void paint(Canvas canvas, Size size) {
    _paint.color = widget.color;
    double space = widget.space;
    double width = widget.width;
    double height = widget.height;
    double distance = width + space;
    double radius = width / 2;
    for (int i = 0, c = widget.count; i < c; ++i) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset((i * distance) + radius, radius),
                  width: width,
                  height: height),
              Radius.circular(widget.cornerRadius)),
          _paint);
    }

    _paint.color = widget.activeColor;
    draw(canvas, space, width, height, radius, widget.cornerRadius);
  }

  @override
  bool shouldRepaint(BasePainter oldDelegate) {
    return oldDelegate.page != page;
  }
}

class SlidePainter extends BasePainter {
  SlidePainter(CarouselIndicator widget, double page, Paint paint)
      : super(widget, page, paint);

  @override
  void draw(Canvas canvas, double space, double width, double height,
      double radius, double cornerRadius) {
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset(radius + (page * (width + space)), radius),
                width: width,
                height: height),
            Radius.circular(cornerRadius)),
        _paint);
  }
}
