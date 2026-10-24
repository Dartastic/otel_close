// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_close/otel_close.dart';

/// Traces Close calls with OpenTelemetry.
///
/// `otel_close` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Close call in
/// [tracedClose]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'close-example');

  // Wraps a Close API call in a CLIENT span.
  final closeId = await tracedClose<String>(
    operation: 'lead.create',
    invoke: () async {
      // Make the Close call here, then report what it returned.
      const id = 'close_8f3a2c';
      return const CloseCallResult(
          value: id,
          result: CloseResult(
              itemCount: 3,
              hasMore: true,
              leadStatus: 'Potential',
              opportunityStatusType: 'active',
              activityType: 'Call',
              callDirection: 'inbound',
              callDurationSec: 120,
              recordingPresent: true,
              sequenceStatus: 'active',
              smartViewId: 'smartview_8f3a2c',
              requestId: 'request_8f3a2c',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedClose lead.create returned $closeId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutCloseInstrumentationAsync.
  await runWithoutCloseInstrumentationAsync(
    () => tracedClose<String>(
      operation: 'lead.create',
      invoke: () async {
        const id = 'close_8f3a2c';
        return const CloseCallResult(
            value: id,
            result: CloseResult(
                itemCount: 3,
                hasMore: true,
                leadStatus: 'Potential',
                opportunityStatusType: 'active',
                activityType: 'Call',
                callDirection: 'inbound',
                callDurationSec: 120,
                recordingPresent: true,
                sequenceStatus: 'active',
                smartViewId: 'smartview_8f3a2c',
                requestId: 'request_8f3a2c',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
