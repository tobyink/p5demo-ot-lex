use v5.38;
use Test2::V0;
use Data::Dumper;

package MyDemo {
	
	use OpenTelemetry ();
	use OpenTelemetry::SDK::Trace::Span::Processor::Simple ();
	use OpenTelemetry::SDK::Exporter::CaptureToArray ();
	use OpenTelemetry::SDK::Trace::TracerProvider ();
	
	my @trace;
	use OpenTelemetry::Lex sub {
		my $processor = OpenTelemetry::SDK::Trace::Span::Processor::Simple->new(
			exporter => OpenTelemetry::SDK::Exporter::CaptureToArray->new( array => \@trace ),
		);
		my $provider = OpenTelemetry::SDK::Trace::TracerProvider->new;
		$provider->add_span_processor($processor);
		
		OpenTelemetry->tracer_provider = $provider;
		return (
			tracer => $provider->tracer( name => 'demo', version => '1.0' ),
		);
	};
	
	sub dump_trace () {
		return @trace;
	}
	
	sub demo_function ( $x ) {
		
		# This function runs its code in a span
		span Alice => sub {
			
			# Can call methods on the span
			$span->add_event( name => 'first' );
			
			# Nested span
			span Bob => sub {
				$span->add_event( name => 'second' );
			};
			
			# Another nested span
			span Carol => sub {
				die "My exception" if $x == 456;
				return 999;
			};
		};
	}
}

is MyDemo::demo_function( 789 ), 999, 'Got the returned value okay';

my $exception = dies {
	MyDemo::demo_function( 456 );
};
like $exception, qr/My exception/, 'An exception was the expected result';

my @trace = sort { $a->{start_timestamp} <=> $b->{start_timestamp} } MyDemo::dump_trace();
is(
	\@trace,
	array {
		
		# First call to demo function.
		item hash {
			field name => 'Alice';
			field status => hash {
				field code => 1;
				etc;
			};
			field events => array {
				item hash {
					field name => 'first';
					etc;
				};
				end;
			};
			field span_id => D();
			etc;
		};
		item hash {
			field name => 'Bob';
			field status => hash {
				field code => 1;
				etc;
			};
			field events => array {
				item hash {
					field name => 'second';
					etc;
				};
				end;
			};
			field span_id => D();
			field parent_span_id => D();
			etc;
		};
		item hash {
			field name => 'Carol';
			field status => hash {
				field code => 1;
				etc;
			};
			field events => array { end; };
			field span_id => D();
			field parent_span_id => D();
			etc;
		};
		
		# Second call to demo function.
		item hash {
			field name => 'Alice';
			field status => hash {
				field code => 2;
				etc;
			};
			field events => array {
				item hash {
					field name => 'first';
					etc;
				};
				item hash {
					field name => 'exception';
					etc;
				};
				end;
			};
			field span_id => D();
			etc;
		};
		item hash {
			field name => 'Bob';
			field status => hash {
				field code => 1;
				etc;
			};
			field events => array {
				item hash {
					field name => 'second';
					etc;
				};
				end;
			};
			field span_id => D();
			field parent_span_id => D();
			etc;
		};
		item hash {
			field name => 'Carol';
			field status => hash {
				field code => 2;
				field description => 'My exception';
				etc;
			};
			field events => array {
				item hash {
					field name => 'exception';
					field attributes => D();
					etc;
				};
				end;
			};
			field span_id => D();
			field parent_span_id => D();
			etc;
		};
		
		end; # Should be six spans exactly!
	},
	'Trace contains the correct basic data',
) or diag Dumper \@trace;

is( $trace[1]{parent_span_id}, $trace[0]{span_id}, "Alice is Bob's parent span" );
is( $trace[2]{parent_span_id}, $trace[0]{span_id}, "Alice is Carol's parent span" );

done_testing;
