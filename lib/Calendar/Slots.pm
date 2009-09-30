package Calendar::Slots;
use Moose;
use MooseX::AttributeHelpers;
use Carp;
use Calendar::Slots::Slot;
use Calendar::Slots::Utils;

has 'overlapping'  => ( is => 'rw', isa => 'Bool', default=>0 );
has 'slots' => (
    metaclass => 'Collection::Array',
    is        => 'ro',
    isa       => 'ArrayRef[Calendar::Slots::Slot]',
    default   => sub { [] },
    provides  => {
        'push'    => 'add_slots',
        'pop'     => 'remove_last_slot',
        'shift'   => 'remove_first_slot',
        'unshift' => 'insert_slots',
        'get'     => 'get_slot_at',
        'set'     => 'set_slot_at',
        'count'   => 'num_slots',
        'empty'   => 'has_slots',
        'clear'   => 'clear_slots',
    }
);

use YAML;
sub _dump {  print Dump @_ }

sub slot {
    my $self = shift;
	for my $slot ( $self->_create_slots( @_ ) ) {
		$self->_validate($slot) unless $self->overlapping;
		my @slots = $self->_merge( $slot, $self->all );
		$self->clear_slots;
		$self->add_slots( @slots );
	}
}

sub _create_slots {
    my $self = shift;
	scalar(@_) == 1 and return $_[0];
    my %args = format_args(@_);
    if ( $args{start} > $args{end} ) {
        my $current = Calendar::Slots::Slot->new( %args, end   => '2400' );
        my $next    = Calendar::Slots::Slot->new( %args, start => '0000' );
		$next->reschedule( days=>1 );
		return ($current, $next);
    }
    else {
        Calendar::Slots::Slot->new(%args);
    }
}

#check if different slots overlap
sub _validate {
	my $self = shift;
	my $slot = shift;
}

#merge slots that are next to each other
sub _merge {
    my $self = shift;
    my $new  = shift;
	my @slots = @_;
	unless( scalar @slots ) {
		return $new;
	}
    my $slot = shift @slots;
	unless( $slot->same_type($new) && $slot->same_day($new) ) {
		return ( $slot, $self->_merge( $new, @slots ) );
	}
    if ( $slot->name eq $new->name ) {
        if ( $slot->start <= $new->end and $slot->end >= $new->end ) {
            $slot->start( $new->start );
            return $self->_merge( $slot, @slots );
        }
        elsif ( $slot->end >= $new->start and $slot->start <= $new->start ) {
            $slot->end( $new->end );
            return $self->_merge( $slot, @slots );
        }
        elsif ( $slot->start <= $new->start and $new->end <= $slot->end ) {
            return ($slot, @slots);
        }
        elsif ( $new->start < $slot->start and $slot->end < $new->end ) {
            $slot->start( $new->start );
            $slot->end( $new->end );
            return $self->_merge( $slot, @slots );
        }
		else {
			return ($slot, $self->_merge( $new, @slots) );
		}
    } elsif( ! $self->overlapping ) {
        if ( $slot->start == $new->start and $slot->end == $new->end ) {
            return $self->_merge($new, @slots);
        }
        elsif ( $new->start < $slot->start and $new->end >= $slot->start and $new->end <= $slot->end ) {
            $slot->start( $new->end );
            return ($slot, $self->_merge( $new, @slots ) );
        }
        elsif ( $new->start >= $slot->start and $new->start < $slot->end and $new->end >= $slot->end ) {
            $slot->end( $new->start );
            return ($slot, $self->_merge( $new, @slots ) );
        }
        elsif ( $slot->start < $new->start and $new->end < $slot->end ) {
            my $third = new Calendar::Slots::Slot(
                name  => $slot->name,
                when   => $slot->when,
                start => $new->end,
                end   => $slot->end
            );
            $slot->end( $new->start );
            return ( $slot, $third, $new, @slots );
        }
        elsif ( $new->start < $slot->start and $slot->end < $new->end ) {
            return $self->_merge( $new, @slots );
        }
		else {
			return ($slot, $self->_merge( $new, @slots) );
		}
	}
	else {
		# overlapping 
		return ($slot, $self->_merge( $new, @slots) );
	}
}

sub all {
	my $self = shift;
	@{ $self->slots };
}

sub sorted {
	my $self = shift;
	sort {
		$a->numeric <=> $b->numeric
	} $self->all;
}

sub find {
    my $self = shift;
	my %args = @_;
	for my $slot ( grep { $_->type eq 'date' } $self->all ) {
        return $slot
          if $slot->contains(%args);
	}
	for my $slot ( grep { $_->type eq 'weekday' } $self->all ) {
        return $slot
          if $slot->contains(%args);
	}
}

sub name {
	my $slot;
	return $slot->name if $slot = find( @_ );
}

1; 

__END__

=pod

=head1 NAME

Calendar::Slots - Manage time slots

=head1 SYNOPSIS

	use Calendar::Slots;
	my $cal = new Calendar::Slots;
	$cal->slot( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'busy' ); 
	my $slot = $cal->find( date=>'2009-10-11', time=>'11:00' );
	print $slot->name;    # 'busy'

=head1 DESCRIPTION

This is a simple module to manage a calendar of very generic time slots. Time slots are anything
with a start and end time on a given date or weekday. Time slots cannot overlap. If a new
time slot overlaps another pre-existing time slot, the calendar will acommodate the slot automatically.

It handles two types of slots: fixed dates, or recurring on weekdays. 
When looking for an event, it will search from most specific (date) to more
generic (recurring). That is, if a slot exist for both a date and a weekday, 
it returns the date slot only. 

The calendar is able to compact itself and generate rows that can be easily
stored in a file or database. 

=head1 LIMITATIONS

Some of it current limitations:

=over

=item * No overlapping of time slots. 

=item * If a time-slot spans over midnight, two slots will be created, one for the
selected date until midnight, and another for the next day from midnight until end-time.

=item * It does not handle timezones.

=item * It does not know of daylight-savings or any other DateTime features.

=back

=head1 METHODS

=head2 slot ( name=>Str, { date=>'YYYY-MM-DD' | weekday=>1..7 }, start=>'HH:MM', end=>'HH:MM' )

Add a time slot to the calendar.

If the new time slot overlaps an existing slot with the same C<name>, 
the slots are merged and become a single slot. 

If the new time slot overlaps an existing slot with a different C<name>,
it overwrites the previous slot, splitting it if necessary. 

=head2 find ( { date=>'YYYY-MM-DD' | weekday=>1..7 }, time=>'HH:MM' )

Returns a L<Calendar::Slots::Slot> object for a given .

	$cal->find( weekday=>1, time=>'11:30' );   # find what's on Monday at 11:30

=head2 name 

Shortcut method to L<find|/find> a slot and return a name. 

=head2 sorted 

Returns a  ARRAY of all slot objects in the calendar.

=head2 all 

Returns an ARRAY of all slot objects in the calendar.

=head1 TODO

There are many improvements planned for this module, as this is just 
an ALPHA release that allows me to get somethings done at $work...

=over

=item * Other types of recurrence: first Monday, last Friday of September...

=item * Merge several calendars into one.

=item * Create subclasses of Calendar::Slots::Slot for each slot type. 

=item * Better input formatting based on DateTime objects and the such.

=head1 AUTHOR

Rodrigo de Oliveira C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

