package Calendar::Slots::Event;
use Moose;
use Carp;
use Calendar::Slots::Utils;

has 'name'    => ( is => 'rw', isa => 'Str' );
has 'weekday' => ( is => 'rw', isa => 'Int' );
has 'date'    => ( is => 'rw', isa => 'Int' );
has 'start'   => ( is => 'rw', isa => 'Int' );
has 'end'     => ( is => 'rw', isa => 'Int' );
has 'type'    => ( is => 'rw', isa => 'Str' );

around BUILDARGS => sub {
	my $orig = shift;
	my $class = shift;
	my %args = @_ == 1 && ref $_[0] ? %{ $_[0] || {} } : @_;
	%args    = format_args( %args );
	if( $args{day} ) {
		if( length( $args{day} ) eq 8 ) {
			$args{date} = $args{day};
			$args{type} = 'date';
			delete $args{weekday};
		} else {
			$args{weekday} = $args{day};
			$args{type} = 'weekday';
			delete $args{date};
		}
	}
	$class->$orig(%args);
};

sub day {
	my $self = shift;
	return $self->date || $self->weekday;
}

sub BUILD {
	my $self = shift;
	$self->date or $self->weekday or confess 'Missing either date or weekday';
	$self->end > $self->start and confess 'Invalid slot: end time is after the start time';
}

sub contains {
	my $self    = shift;
	my %args    = format_args( @_ );
	my $date    = $args{date};
	my $weekday = $args{weekday};
	my $time = $args{'time'};
	my $start = $args{start};
	my $end   = $args{end};

	$time and ($start or $end ) and croak 'Parameters start/end and time are mutually exclusive';
	$date or $weekday or croak 'Missing either day or weekday';
	$date and $weekday and croak 'Parameters day and weekday are mutually exclusive';
	$self->date and return unless $date eq $self->date;

	if( $time ) {
		return unless $time >= $self->start && $time < $self->end;
	} else {
		return unless $start > $self->start;
		return unless $end < $self->end;
	}
	return 1;
}

#return if day/weekday are the same
sub match_day {
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
