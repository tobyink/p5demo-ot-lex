use Object::Pad ':experimental(init_expr)';

package OpenTelemetry::SDK::Exporter::CaptureToArray;

class OpenTelemetry::SDK::Exporter::CaptureToArray
	:does(OpenTelemetry::Exporter)
{
	use Future::AsyncAwait;
	use OpenTelemetry::Constants -trace_export;

	field $stopped;
	field $array :param :reader;

	my sub dump_event ($event) {
		{
			timestamp          => $event->timestamp,
			name               => $event->name,
			attributes         => $event->attributes,
			dropped_attributes => $event->dropped_attributes,
		}
	}

	my sub dump_link ($link) {
		{
			trace_id           => $link->context->hex_trace_id,
			span_id            => $link->context->hex_span_id,
			attributes         => $link->attributes,
			dropped_attributes => $link->dropped_attributes,
		}
	}

	my sub dump_status ($status) {
		{
			code        => $status->code,
			description => $status->description,
		}
	}

	my sub dump_scope ($scope) {
		{
			name    => $scope->name,
			version => $scope->version,
		}
	}

	method export ( $spans, $timeout = undef ) {
		return TRACE_EXPORT_FAILURE if $stopped;

		for my $span (@$spans) {
			my $resource = $span->resource;

			push $array->@*, {
				attributes            => $span->attributes,
				end_timestamp         => $span->end_timestamp,
				events                => [ map dump_event($_), $span->events ],
				instrumentation_scope => dump_scope($span->instrumentation_scope),
				kind                  => $span->kind,
				links                 => [ map dump_link($_), $span->links ],
				name                  => $span->name,
				parent_span_id        => $span->hex_parent_span_id,
				resource              => $resource ? $resource->attributes : {},
				span_id               => $span->hex_span_id,
				start_timestamp       => $span->start_timestamp,
				status                => dump_status($span->status),
				dropped_attributes    => $span->dropped_attributes,
				dropped_events        => $span->dropped_events,
				dropped_links         => $span->dropped_links,
				trace_flags           => $span->trace_flags->flags,
				trace_id              => $span->hex_trace_id,
				trace_state           => $span->trace_state->to_string,
			};
		}

		TRACE_EXPORT_SUCCESS;
	}

	async method shutdown ( $timeout = undef ) {
		$stopped = 1;
		TRACE_EXPORT_SUCCESS;
	}

	async method force_flush ( $timeout = undef ) { TRACE_EXPORT_SUCCESS }
}

1;