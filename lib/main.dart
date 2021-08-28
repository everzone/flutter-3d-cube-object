import 'dart:math' as math;
import 'dart:ui';
import 'package:vector_math/vector_math_64.dart' hide Colors;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cube rotations',
      home: Container(
        color: Colors.grey[800],
        padding: EdgeInsets.all(32),
        child: const TestCubeWidget(),
      ),
    );
  }
}

class TestCubeWidget extends StatelessWidget {
  const TestCubeWidget();

  @override
  Widget build(BuildContext context) {
    var _offset = Offset.zero;
    return StatefulBuilder(
      builder: (context, setState) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (details) {
          setState(() => _offset += details.delta);
        },
        onDoubleTap: () {
          setState(() => _offset = Offset.zero);
        },
        child: CustomPaint(
          foregroundPainter: _CubePainter(
            angleX: -0.01 * _offset.dx + math.pi / 4,
            angleY: 0.01 * _offset.dy + math.pi / 8,
            colors: List.filled(6, Colors.green),
          ),
        ),
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  // static final light = Vector3(0, 0, -1);
  static final light = Vector3(math.cos(math.pi/3), -math.sin(math.pi/3), -math.cos(math.pi/3)).normalized();

  final List<Color> colors;
  final double angleX;
  final double angleY;

  late List<Matrix4> _positions;

  _CubePainter({
    this.angleX = 0,
    this.angleY = 0,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cubeSize = size.shortestSide / 3;

    final side = Rect.fromLTRB(-cubeSize, -cubeSize, cubeSize, cubeSize);
    final v1 = Vector3(cubeSize, cubeSize, 0);
    final v2 = Vector3(-cubeSize, cubeSize, 0);
    final v3 = Vector3(-cubeSize, -cubeSize, 0);

    _positions = [
      Matrix4.identity()..translate(0.0, 0.0, -cubeSize),
      Matrix4.identity()
        ..rotate(Vector3(1, 0, 0), -math.pi / 2)
        ..translate(0.0, 0.0, -cubeSize),
      Matrix4.identity()
        ..rotate(Vector3(0, 1, 0), -math.pi / 2)
        ..translate(0.0, 0.0, -cubeSize),
      Matrix4.identity()
        ..rotate(Vector3(0, 1, 0), math.pi / 2)
        ..translate(0.0, 0.0, -cubeSize),
      Matrix4.identity()
        ..rotate(Vector3(1, 0, 0), math.pi / 2)
        ..translate(0.0, 0.0, -cubeSize),
      Matrix4.identity()
        ..rotate(Vector3(0, 1, 0), math.pi)
        ..translate(0.0, 0.0, -cubeSize)
    ];

    final cameraMatrix = Matrix4.identity()
      ..translate(size.width / 2, size.height / 2)
      ..multiply(Matrix4.identity()
        ..setEntry(3, 2, 0.0008)
        ..rotateX(angleY)
        ..rotateY(angleX));

    List<int> sortedKeys = createZOrder(cameraMatrix, side);
    
    for (int i in sortedKeys) {
      canvas.save();

      final finalMatrix = cameraMatrix.multiplied(_positions[i]);

      final normalVector = normalVector3(
        finalMatrix.transformed3(v1),
        finalMatrix.transformed3(v2),
        finalMatrix.transformed3(v3),
      );

      canvas.transform(finalMatrix.storage);

      final directionBrightness = normalVector.dot(light).clamp(0.0, 1.0);
      final hslColor = HSLColor.fromColor(colors[i]);

      canvas.drawRect(side, Paint()..color = hslColor.withLightness(lerpDouble(0.6, 1, directionBrightness)! * hslColor.lightness).toColor());

      canvas.restore();
    }
  }

  List<int> createZOrder(Matrix4 matrix, Rect side) {
    final renderOrder = <int, double>{};
    final pos = Vector3.zero();
    for (int i = 0; i < _positions.length; i++) {
      var tmp = matrix.multiplied(_positions[i]);
      pos.x = side.center.dx;
      pos.y = side.center.dy;
      pos.z = 0.0;
      var t = tmp.transform3(pos).z;
      renderOrder[i] = t;
    }

    return renderOrder.keys.toList(growable: false)..sort((a, b) => renderOrder[b]!.compareTo(renderOrder[a]!));
  }

  @override
  bool shouldRepaint(_CubePainter oldDelegate) => true;
}

// surface normal vector
Vector3 normalVector3(Vector3 v1, Vector3 v2, Vector3 v3) {
  Vector3 s1 = Vector3.copy(v2);
  s1.sub(v1);
  Vector3 s3 = Vector3.copy(v2);
  s3.sub(v3);

  return Vector3(
    (s1.y * s3.z) - (s1.z * s3.y),
    (s1.z * s3.x) - (s1.x * s3.z),
    (s1.x * s3.y) - (s1.y * s3.x),
  ).normalized();
}
