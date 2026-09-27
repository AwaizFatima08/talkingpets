import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A sum question a toddler can't answer (Families policy "neutral age
/// screen" for grown-up areas, rewarded ads and links out of the app).
class GateQuestion {
  GateQuestion(this.a, this.b, this.options);

  factory GateQuestion.random([math.Random? rng]) {
    final r = rng ?? math.Random();
    final a = 3 + r.nextInt(7), b = 3 + r.nextInt(7);
    final answer = a + b;
    final opts = <int>{answer};
    while (opts.length < 4) {
      final o = answer + r.nextInt(9) - 4;
      if (o > 1 && o != answer) opts.add(o);
    }
    return GateQuestion(a, b, opts.toList()..shuffle(r));
  }

  final int a, b;
  final List<int> options;
  int get answer => a + b;
}

/// Returns true only if a grown-up answers correctly.
Future<bool> showParentGate(BuildContext context, {String reason = 'For grown-ups'}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (_) => _ParentGateDialog(reason: reason, question: GateQuestion.random()),
  );
  return ok ?? false;
}

class _ParentGateDialog extends StatelessWidget {
  const _ParentGateDialog({required this.reason, required this.question});

  final String reason;
  final GateQuestion question;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const Key('parent-gate'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(reason, textAlign: TextAlign.center),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Please ask a grown-up to answer:'),
        const SizedBox(height: 12),
        Text('${question.a} + ${question.b} = ?',
            key: const Key('gate-question'), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final o in question.options)
            SizedBox(
              width: 72,
              height: 56,
              child: FilledButton.tonal(
                key: Key('gate-$o'),
                onPressed: () => Navigator.of(context).pop(o == question.answer),
                child: Text('$o', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ),
            ),
        ]),
      ]),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel'))],
    );
  }
}
