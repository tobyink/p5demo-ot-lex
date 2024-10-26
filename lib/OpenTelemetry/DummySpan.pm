package OpenTelemetry::DummySpan;

use v5.38;
use experimental qw( try defer );

use parent 'OpenTelemetry::DummyTracer';

sub new ( $class, @args ) {
	my $self = $class->SUPER::new( @args );
	$self->{messages} //= [];
	return $self;
}

sub add_message ( $self, $msg ) {
	push $self->{messages}->@*, $msg;
}

1;
