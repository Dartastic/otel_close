// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_close/otel_close.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_close-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('call.create records direction + duration + recording', () async {
    await tracedClose<String>(
      operation: 'call.create',
      invoke: () async => const CloseCallResult(
        value: 'ok',
        result: CloseResult(
          activityType: 'Call',
          callDirection: 'outbound',
          callDurationSec: 421,
          recordingPresent: true,
          statusCode: 201,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('close call.create')!);
    expect(a['close.call.direction'], 'outbound');
    expect(a['close.call.duration_sec'], 421);
    expect(a['close.call.recording.present'], true);
  });

  test('lead.list via smart view recorded', () async {
    await tracedClose<String>(
      operation: 'lead.list',
      invoke: () async => const CloseCallResult(
        value: 'ok',
        result: CloseResult(
          itemCount: 50,
          hasMore: true,
          smartViewId: 'sv-1',
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('close lead.list')!);
    expect(a['close.smart_view.id'], 'sv-1');
    expect(a['close.has_more'], true);
  });

  test('suppression skips spans', () async {
    await runWithoutCloseInstrumentationAsync(() async {
      await tracedClose<String>(
        operation: 'contact.list',
        invoke: () async => const CloseCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('close '), isEmpty);
  });
}
