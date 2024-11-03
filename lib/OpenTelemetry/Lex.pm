package OpenTelemetry::Lex;

use v5.38;
use experimental qw( try defer builtin );
use builtin qw( true false export_lexically );
use Syntax::Keyword::Dynamically;

use OpenTelemetry;
use Attribute::Handlers;
use Sub::Util ();
use Keyword::Declare;

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
	
	keyword Span ( Ident $name, Block $code ) {{{
		span(qq{«$name»}, sub { «$code» });
	}}}
	
	# This part is unfortunately not lexical, nor pretty.
	# And yes, it really does need the stringy eval.
	no strict 'refs';
	no warnings 'redefine';
	my $caller = caller;
	eval q{
		sub }.$caller.q{::Span :ATTR(CODE,RAWDATA) ( $package, $symbol, $referent, $attr, $data, $phase, $filename, $linenum ) {
			my $subname = sprintf '%s::%s', *{$symbol}{PACKAGE}, *{$symbol}{NAME};
			my $code    = *{$symbol}{CODE};
			my $replacement = sub ( @args ) {
				$tracer->in_span( $data || $subname, sub ( $new_span, $new_context ) {
					dynamically $span = $new_span;
					dynamically $context = $new_context;
					return $code->( @args );
				} );
			};
			*{$subname} = Sub::Util::set_subname($subname, $replacement);
		}
		
		1;
	} or die $@;
}

1;

=head1 SYNPOSIS

  package Your::Module;
  
  # Exports $tracer, $context, $span, span, and :Span.
  use OpenTelemetry::Lex sub {
    my $p = OpenTelemetry->tracer_provider;
    return ( tracer => $p->tracer( name => 'my_app', version => '1.0' ) );
  };
  
  sub thingy :Span(outer) ( $foo, $bar ) {
    
    $span->add_event( name => 'inside_outer' );
    
    span inner => sub {
      $span->add_event( name => 'inside inner' );
    };
  }
