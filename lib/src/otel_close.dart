// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_close_suppression.dart';

const _tracerName = 'dartastic_otel_libs_close';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class CloseResult {
  /// Creates a result.
  const CloseResult({
    this.itemCount,
    this.hasMore,
    this.leadStatus,
    this.opportunityStatusType,
    this.activityType,
    this.callDirection,
    this.callDurationSec,
    this.recordingPresent,
    this.sequenceStatus,
    this.smartViewId,
    this.requestId,
    this.statusCode,
  });

  /// `data.length`.
  final int? itemCount;

  /// `has_more` pagination flag.
  final bool? hasMore;

  /// Custom lead status label (e.g. `Potential`, `Bad Fit`).
  final String? leadStatus;

  /// `active` / `won` / `lost` for opportunity status_type.
  final String? opportunityStatusType;

  /// `Call` / `Email` / `SMS` / `Note` / `Meeting` / `Task` /
  /// `LeadStatusChange` / `OpportunityStatusChange`.
  final String? activityType;

  /// `inbound` / `outbound` / `outbound_manual`.
  final String? callDirection;

  /// Call duration in seconds.
  final int? callDurationSec;

  /// Whether a recording URL was attached.
  final bool? recordingPresent;

  /// `active` / `paused` / `done` / `bounced` / `unsubscribed`.
  final String? sequenceStatus;

  /// Smart View id when listing leads via a saved query — drives
  /// search-side latency.
  final String? smartViewId;

  /// `X-Request-Id`.
  final String? requestId;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class CloseCallResult<T> {
  /// Creates a call result.
  const CloseCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final CloseResult? result;
}

/// Wraps a Close API call in a CLIENT span. [operation] is one of
/// `lead.list`, `lead.get`, `lead.create`, `lead.update`, `lead.merge`,
/// `opportunity.list`, `opportunity.create`, `opportunity.update`,
/// `contact.list`, `contact.create`, `activity.list`, `activity.create`,
/// `call.list`, `call.create`, `email.send`, `sms.send`,
/// `sequence_subscription.create`, `sequence_subscription.list`,
/// `smart_view.list`, `webhook.create`.
Future<T> tracedClose<T>({
  required String operation,
  required Future<CloseCallResult<T>> Function() invoke,
}) async {
  if (closeInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'close',
    'rpc.method': operation,
    'close.operation': operation,
  };

  final span = _tracer().startSpan(
    'close $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.itemCount != null) {
        extras.add(OTelAPI.attributeInt(
          'close.item_count',
          r.result!.itemCount!,
        ));
      }
      if (r.result!.hasMore != null) {
        extras.add(OTelAPI.attributeBool(
          'close.has_more',
          r.result!.hasMore!,
        ));
      }
      if (r.result!.leadStatus != null) {
        extras.add(OTelAPI.attributeString(
          'close.lead.status',
          r.result!.leadStatus!,
        ));
      }
      if (r.result!.opportunityStatusType != null) {
        extras.add(OTelAPI.attributeString(
          'close.opportunity.status_type',
          r.result!.opportunityStatusType!,
        ));
      }
      if (r.result!.activityType != null) {
        extras.add(OTelAPI.attributeString(
          'close.activity.type',
          r.result!.activityType!,
        ));
      }
      if (r.result!.callDirection != null) {
        extras.add(OTelAPI.attributeString(
          'close.call.direction',
          r.result!.callDirection!,
        ));
      }
      if (r.result!.callDurationSec != null) {
        extras.add(OTelAPI.attributeInt(
          'close.call.duration_sec',
          r.result!.callDurationSec!,
        ));
      }
      if (r.result!.recordingPresent != null) {
        extras.add(OTelAPI.attributeBool(
          'close.call.recording.present',
          r.result!.recordingPresent!,
        ));
      }
      if (r.result!.sequenceStatus != null) {
        extras.add(OTelAPI.attributeString(
          'close.sequence.status',
          r.result!.sequenceStatus!,
        ));
      }
      if (r.result!.smartViewId != null) {
        extras.add(OTelAPI.attributeString(
          'close.smart_view.id',
          r.result!.smartViewId!,
        ));
      }
      if (r.result!.requestId != null) {
        extras.add(OTelAPI.attributeString(
          'close.request.id',
          r.result!.requestId!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Close HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
