package Calendar::Slots;
use Moose;
use MooseX::AttributeHelpers;
use Carp;
use Calendar::Slots::Event;
use Calendar::Slots::Utils;

has 'overlapping'  => ( is => 'rw', isa => 'Bool', default=>0 );
has 'events' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Calendar::Slots::Event]',
    default   => sub { [] },
    provides  => {
        'push'    => 'add_events',
        'pop'     => 'remove_last_event',
        'shift'   => 'remove_first_event',
        'unshift' => 'insert_events',
        'get'     => 'get_event_at',
        'set'     => 'set_event_at',
        'count'   => 'num_events',
        'empty'   => 'has_events',
        'clear'   => 'clear_events',
    }
);

use YAML;
sub _dump {  print Dump @_ }

sub event {
    my $self = shift;
    my %args = format_args(@_);
	for my $event ( $self->create_events( %args ) ) {
		$self->validate($event) unless $self->overlapping;
		#$self->add_events($event);
		my @events = $self->merge( $event, $self->all );
		$self->clear_events;
		$self->add_events( @events );
	}
}

sub create_events {
    my $self = shift;
	my %args = @_;
	if( $args{start} > $args{end} ) {
		return 
		   (
            Calendar::Slots::Event->new(
                name  => $args{name},
                start => $args{start},
                end   => '2400',
                day   => $args{day}
            ),
            Calendar::Slots::Event->new(
                name  => $args{name},
                start => '0000',
                end   => $args{end},
                day   => $args{day}
              )
		   );
	} else {
        Calendar::Slots::Event->new(
            name  => $args{name},
            start => $args{start},
            end   => $args{end},
            day   => $args{day}
          )
	}
}

#check if different events overlap
sub validate {
	my $self = shift;
	my $event = shift;
}

#merge events that are next to each other
sub merge {
    my $self = shift;
    my $new  = shift;
	my @events = @_;
	unless( scalar @events ) {
		warn '-----------------NEW';
		return $new;
	}
    my $event = shift @events;
	unless( $event->match_day($new) ) {
		warn '-----------------NEXT WO DAY MATCH';
		return ( $event, $self->merge( $new, @events ) );
	}
    if ( $event->name eq $new->name ) {
        if ( $event->start <= $new->end and $event->end >= $new->end ) {
			warn "-----------------TA";
            $event->start( $new->start );
            return $self->merge( $event, @events );
        }
        elsif ( $event->end >= $new->start and $event->start <= $new->start ) {
			warn "-----------------BA";
            $event->end( $new->end );
            return $self->merge( $event, @events );
        }
        elsif ( $event->start <= $new->start and $new->end <= $event->end ) {
			warn "-----------------CONTAINS";
            return ($event, @events);
        }
        elsif ( $new->start < $event->start and $event->end < $new->end ) {
			warn "-----------------AMPL";
            $event->start( $new->start );
            $event->end( $new->end );
            return $self->merge( $event, @events );
        }
		else {
			warn "-----------------ADDED";
			return ($event, $self->merge( $new, @events) );
		}
    } else {
        if ( $event->start == $new->start and $event->end == $new->end ) {
			warn "-----------------DIF SAME";
            return $self->merge($new, @events);
        }
        elsif ( $new->start < $event->start and $new->end >= $event->start and $new->end <= $event->end ) {
			warn "-----------------DIF TA";
            $event->start( $new->end );
            return ($event, $self->merge( $new, @events ) );
        }
        elsif ( $new->start >= $event->start and $new->start < $event->end and $new->end >= $event->end ) {
			warn "-----------------DIF BA";
            $event->end( $new->start );
            return ($event, $self->merge( $new, @events ) );
        }
        elsif ( $event->start < $new->start and $new->end < $event->end ) {
			warn "-----------------DIF CONT";
            my $third = new Calendar::Slots::Event(
                name  => $event->name,
				day => $event->day,
                start => $new->end,
                end   => $event->end
            );
			$event->end( $new->start );
            return ( $event, $third, $new, @events );
        }
        elsif ( $new->start < $event->start and $event->end < $new->end ) {
			warn "-----------------DIF AMPL";
            return $self->merge( $new, @events );
        }
		else {
			warn "-----------------DIF ADDED";
			return ($event, $self->merge( $new, @events) );
		}
	}
}

sub all {
	my $self = shift;
	@{ $self->events };
}

sub list {
	my $self = shift;
	sort {
		$a->numeric <=> $b->numeric
	} $self->all;
}

sub find {
    my $self = shift;
	my %args = @_;
	for my $event ( $self->list ) {
        return $event
          if $event->contains(%args);
	}
}

sub find_name {
	my $event;
	return $event->name if $event = find( @_ );
}

1;

