package OpenTelemetry::Lex;

use v5.38;
use experimental qw( try defer builtin );
use builtin qw( true false export_lexically );
use Syntax::Keyword::Dynamically;

use OpenTelemetry::DummyTracer;

sub import ( $class, @args ) {
	my $tracer = OpenTelemetry::DummyTracer->new( @args );
	my ( $context, $span );
	
	my sub span {
		my $code = pop;
		dynamically $span = ( $span or $tracer )->new_span( @_ );
		dynamically $context = $tracer->get_context;
		$span->{started} = true;
		defer { $span->{ended} = true };
		try {
			$code->();
		}
		catch ( $e ) {
			$span->{exception} = $e;
			die( $e ); # rethrow
		}
	};
	
	export_lexically(
		'$tracer'  => \$tracer,
		'$context' => \$context,
		'$span'    => \$span,
		span       => \&span,
	);
}

1;

=head1 SYNPOSIS

  package Your::Module;
  
  # Exports $tracer, $context, $span, and &span.
  use OpenTelemetry::Lex ( %options_for_tracer );
  
  sub thingy ( $foo, $bar ) {
    
    span %options_for_span, sub {
      
      $span->add_message( "Foo is $foo" );
      
      span %options_for_inner_span, sub {
        
        $span->add_message( "Bar is $bar" );
      };
    };
  }
