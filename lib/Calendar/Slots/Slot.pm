package Calendar::Slots::Slot;
use Moose;
use Carp;
use Calendar::Slots::Utils;

has 'name'    => ( is => 'rw', isa => 'Str' );
has 'when'    => ( is => 'rw', isa => 'Int', required=>1 );
has 'start'   => ( is => 'rw', isa => 'Int' );
has 'end'     => ( is => 'rw', isa => 'Int' );
has 'type'    => ( is => 'rw', isa => 'Str' );

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %args = @_ == 1 && ref $_[0] ? %{ $_[0] || {} } : @_;
	%args    = format_args( %args );
	unless( $args{when} ) {
		if( $args{date} ) {
			$args{when} = $args{date};
			$args{type} = 'date';
		} else {
			$args{when} = $args{weekday};
			$args{type} = 'weekday';
		}
	}
	delete $args{date};
	delete $args{weekday};
	$class->$orig(%args);
};

sub BUILD {
	my $self = shift;
	$self->start > $self->end and confess 'Invalid slot: start time is after the end time';
}

sub contains {
	my $self    = shift;
	my %args    = format_args( @_ );
	my $type = $args{type} || ( $args{date} ? 'date' : 'weekday' );
    my $when   = $args{when} || ( $type eq 'date' ? $args{date} : $args{weekday} );
    my $time  = $args{'time'};
    my $start = $args{start};
    my $end   = $args{end};

	$time and ($start or $end ) and croak 'Parameters start/end and time are mutually exclusive';
	$when or croak 'Missing parameter when';
	return unless $type eq $self->type;
	return unless $when eq $self->when;

	if( $time ) {
		return unless $time >= $self->start && $time < $self->end;
	} else {
		return unless $start > $self->start;
		return unless $end < $self->end;
	}
	return 1;
}

#return if day/weekday are the same
sub same_day {
    my $self = shift;
	my $slot = shift,
	return 1;  #TODO
}

sub numeric {
    my $self = shift;
	if( $self->type eq 'date' ) {
		sprintf("%08d%04d%04d", $self->when, $self->start, $self->end );
	} else {
		sprintf("%01d%08d%04d%04d", $self->when, 0, $self->start, $self->end );
	}
}

1;
