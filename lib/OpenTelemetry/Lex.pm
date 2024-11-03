package OpenTelemetry::Lex;

use v5.38;
use experimental qw( try defer builtin );
use builtin qw( true false export_lexically );
use Syntax::Keyword::Dynamically;

use OpenTelemetry;

sub import ( $class, @args ) {
	my %options = (
		( @args == 1 and ref $args[0] eq 'HASH' ) ? $args[0]->%*  :
		( @args == 1 and ref $args[0] eq 'CODE' ) ? $args[0]->( $class ) :
		@args
	);
	
	my $tracer = $options{tracer} // die 'Missing required argument: tracer';
	my ( $context, $span );
	
	my sub span {
		my $name = shift;
		my $code = pop;
		my %rest = @_;
		$tracer->in_span( $name, %rest, sub ( $new_span, $new_context ) {
			dynamically $span = $new_span;
			dynamically $context = $new_context;
			return $code->();
		} );
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
