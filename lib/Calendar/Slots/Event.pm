package Calendar::Slots::Event;
use Moose;
use Carp;
use Calendar::Slots::Utils;

has 'name'    => ( is => 'rw', isa => 'Str' );
has 'day'    => ( is => 'rw', isa => 'Int', required=>1 );
has 'start'   => ( is => 'rw', isa => 'Int' );
has 'end'     => ( is => 'rw', isa => 'Int' );
has 'type'    => ( is => 'rw', isa => 'Str' );

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %args = @_ == 1 && ref $_[0] ? %{ $_[0] || {} } : @_;
	%args    = format_args( %args );
	unless( $args{day} ) {
		if( $args ) {
			$args{day} = $args{date};
			$args{type} = 'date';
		} else {
			$args{day} = $args{weekday};
			$args{type} = 'weekday';
		}
	}
	delete $args{date};
	delete $args{weekday};
	$class->$orig(%args);
};

sub BUILD {
	my $self = shift;
	$self->end > $self->start and confess 'Invalid slot: end time is after the start time';
}

sub contains {
	my $self    = shift;
	my %args    = format_args( @_ );
	my $type = $args{type} || ( $args{date} ? 'date' : 'weekday' );
    my $day   = $args{day} || ( $type eq 'date' ? $args{date} : $args{weekday} );
    my $time  = $args{'time'};
    my $start = $args{start};
    my $end   = $args{end};

	$time and ($start or $end ) and croak 'Parameters start/end and time are mutually exclusive';
	$day or croak 'Missing parameter day';
	return unless $type eq $self->type;
	return unless $day eq $self->day;

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
	my $event = shift,
	return 1;  #TODO
}

sub numeric {
    my $self = shift;
	if( $self->date ) {
		sprintf("%08d%04d%04d", $self->date, $self->start, $self->end );
	} else {
		sprintf("%01d%08d%04d%04d", $self->weekday, 0, $self->start, $self->end );
	}
}

1;