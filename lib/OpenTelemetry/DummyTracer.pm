package OpenTelemetry::DummyTracer;

use v5.38;
use experimental qw( try defer );

sub new ( $class, @args ) {
	my $self = {
		( @args == 1 and ref $args[0] eq 'HASH' ) ? $args[0]->%*  :
		( @args == 1 and ref $args[0] eq 'CODE' ) ? $args[0]->( $class ) :
		@args
	};
	$self->{spans} //= [];
	return bless $self, $class;
}

sub new_span ( $self, @args ) {
	require OpenTelemetry::DummySpan;
	my $span = OpenTelemetry::DummySpan->new( @args );
	push $self->{spans}->@*, $span;
	return $span;
}

# I don't know what a context is. I'm assuming only one per tracer?
# Maybe there are multiple. Who knows?
sub get_context ( $self ) {
	require OpenTelemetry::DummyContext;
	$self->{context} //= OpenTelemetry::DummyContext->new;
}

1;
