use v5.38;
use Test2::V0;
use Data::Dumper;

package MyDemo {
	use OpenTelemetry::Lex ( foo => 123 );
	
	sub get_tracer {
		return $tracer;
	}
	
	sub demo_function ( $x ) {
		
		# This function runs its code in a span
		span name => 'Alice', sub {
			
			# Can call methods on the span
			$span->add_message( "\$x is $x" );
			
			# And on the context
			$context->some_method();
			
			# Nested span
			span name => 'Bob', sub {
				$span->add_message( "in Bob" );
			};
			
			# Another nested span
			span name => 'Carol', sub {
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

local $Data::Dumper::Sortkeys = 1;
diag Dumper( MyDemo::get_tracer() );

done_testing;
