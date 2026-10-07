import 'package:flutter/material.dart';

void main() => runApp(const HabitsApp());

class HabitsApp extends StatelessWidget {
  const HabitsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'عاداتي اليومية',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF347FC4)),
      builder: (context, child) => Directionality(textDirection: TextDirection.rtl, child: child!),
      home: const Shell(),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 5; // نبدأ على "أفكاري" عشان نجرّب القلم
  static const _tabs = <(String, IconData)>[
    ('الرئيسية', Icons.home_rounded),
    ('الصلوات', Icons.nightlight_round),
    ('الأهداف', Icons.flag_rounded),
    ('الدراسة', Icons.school_rounded),
    ('مصروفاتي', Icons.account_balance_wallet_rounded),
    ('أفكاري', Icons.lightbulb_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _i, children: [
          for (var k = 0; k < 5; k++) _Placeholder(_tabs[k].$1, _tabs[k].$2),
          const IdeasPage(),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: [for (final t in _tabs) NavigationDestination(icon: Icon(t.$2), label: t.$1)],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  final String title;
  final IconData icon;
  const _Placeholder(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text('قريبًا'),
        ]),
      );
}

class Stroke {
  final List<Offset> pts;
  final Color color;
  final double width;
  Stroke(this.pts, this.color, this.width);
}

class IdeasPage extends StatefulWidget {
  const IdeasPage({super.key});
  @override
  State<IdeasPage> createState() => _IdeasPageState();
}

class _IdeasPageState extends State<IdeasPage> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redo = [];
  Stroke? _cur;
  Color _color = const Color(0xFF1D2B3A);
  double _width = 3;
  bool _eraser = false;
  bool _lined = false;

  void _erase(Offset pos) {
    final before = _strokes.length;
    _strokes.removeWhere((s) => s.pts.any((p) => (p - pos).distance < 14));
    if (_strokes.length != before) setState(() {});
  }

  Widget _chip(Color c) => GestureDetector(
        onTap: () => setState(() {
          _color = c;
          _eraser = false;
        }),
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: c,
            shape: BoxShape.circle,
            border: Border.all(width: 3, color: _color == c && !_eraser ? Colors.black54 : Colors.transparent),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(6),
        child: Wrap(spacing: 2, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          IconButton(
              tooltip: 'قلم',
              isSelected: !_eraser,
              onPressed: () => setState(() => _eraser = false),
              icon: const Icon(Icons.edit)),
          IconButton(
              tooltip: 'ممحاة',
              isSelected: _eraser,
              onPressed: () => setState(() => _eraser = true),
              icon: const Icon(Icons.cleaning_services)),
          _chip(const Color(0xFF1D2B3A)),
          _chip(const Color(0xFF347FC4)),
          _chip(const Color(0xFFC0392B)),
          _chip(const Color(0xFF1A8A5F)),
          SizedBox(
            width: 110,
            child: Slider(min: 1, max: 14, value: _width, onChanged: (v) => setState(() => _width = v)),
          ),
          IconButton(
              tooltip: 'تراجع',
              onPressed: _strokes.isEmpty ? null : () => setState(() => _redo.add(_strokes.removeLast())),
              icon: const Icon(Icons.undo)),
          IconButton(
              tooltip: 'إعادة',
              onPressed: _redo.isEmpty ? null : () => setState(() => _strokes.add(_redo.removeLast())),
              icon: const Icon(Icons.redo)),
          IconButton(
              tooltip: 'خطوط الورق',
              isSelected: _lined,
              onPressed: () => setState(() => _lined = !_lined),
              icon: const Icon(Icons.view_headline)),
          IconButton(
              tooltip: 'مسح الصفحة',
              onPressed: () => setState(() {
                    _strokes.clear();
                    _redo.clear();
                  }),
              icon: const Icon(Icons.delete_outline)),
        ]),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(blurRadius: 10, color: Color(0x22000000))],
          ),
          clipBehavior: Clip.antiAlias,
          // Listener بيستقبل القلم والإصبع والماوس
          child: Listener(
            onPointerDown: (e) {
              if (_eraser) {
                _erase(e.localPosition);
              } else {
                setState(() {
                  _cur = Stroke([e.localPosition], _color, _width);
                  _strokes.add(_cur!);
                  _redo.clear();
                });
              }
            },
            onPointerMove: (e) {
              if (_eraser) {
                _erase(e.localPosition);
              } else if (_cur != null) {
                setState(() => _cur!.pts.add(e.localPosition));
              }
            },
            onPointerUp: (_) => _cur = null,
            onPointerCancel: (_) => _cur = null,
            child: CustomPaint(painter: _Painter(_strokes, _lined), size: Size.infinite),
          ),
        ),
      ),
    ]);
  }
}

class _Painter extends CustomPainter {
  final List<Stroke> strokes;
  final bool lined;
  _Painter(this.strokes, this.lined);

  @override
  void paint(Canvas canvas, Size size) {
    if (lined) {
      final line = Paint()
        ..color = const Color(0xFFCDDCEA)
        ..strokeWidth = 1;
      for (double y = 34; y < size.height; y += 34) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
      }
    }
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.pts.length == 1) {
        canvas.drawCircle(s.pts.first, s.width / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path()..moveTo(s.pts.first.dx, s.pts.first.dy);
        for (final p in s.pts.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _Painter old) => true;
}
