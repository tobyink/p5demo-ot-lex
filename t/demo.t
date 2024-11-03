use v5.38;
use Test2::V0;
use Data::Dumper;

package MyDemo {
	use OpenTelemetry::Lex sub {
		my $provider = OpenTelemetry->tracer_provider;
		return (
			tracer => $provider->tracer( name => 'demo', version => '1.0' ),
		);
	};
	
	sub get_tracer () {
		return $tracer;
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

diag Dumper( MyDemo::get_tracer() );

done_testing;
