package OpenTelemetry::DummyContext;

use v5.38;
use experimental qw( try defer );

sub new ( $class, @args ) {
	my $self = {
		( @args == 1 and ref $args[0] eq 'HASH' ) ? $args[0]->%*  :
		( @args == 1 and ref $args[0] eq 'CODE' ) ? $args[0]->( $class ) :
		@args
	};
	return bless $self, $class;
}

sub some_method {
	return 42;
}

1;
