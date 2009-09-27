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
    my %args = format_args(@_);
	for my $slot ( $self->create_slots( %args ) ) {
		$self->validate($slot) unless $self->overlapping;
		#$self->add_slots($slot);
		my @slots = $self->merge( $slot, $self->all );
		$self->clear_slots;
		$self->add_slots( @slots );
	}
}

sub create_slots {
    my $self = shift;
	my %args = @_;
    if ( $args{start} > $args{end} ) {
        return (
            Calendar::Slots::Slot->new( %args, end   => '2400' ),
            Calendar::Slots::Slot->new( %args, start => '0000' )
        );
    }
    else {
        Calendar::Slots::Slot->new(%args);
    }
}

#check if different slots overlap
sub validate {
	my $self = shift;
	my $slot = shift;
}

#merge slots that are next to each other
sub merge {
    my $self = shift;
    my $new  = shift;
	my @slots = @_;
	unless( scalar @slots ) {
		warn '-----------------NEW';
		return $new;
	}
    my $slot = shift @slots;
	unless( $slot->same_day($new) ) {
		warn '-----------------NEXT WO DAY MATCH';
		return ( $slot, $self->merge( $new, @slots ) );
	}
    if ( $slot->name eq $new->name ) {
        if ( $slot->start <= $new->end and $slot->end >= $new->end ) {
			warn "-----------------TA";
            $slot->start( $new->start );
            return $self->merge( $slot, @slots );
        }
        elsif ( $slot->end >= $new->start and $slot->start <= $new->start ) {
			warn "-----------------BA";
            $slot->end( $new->end );
            return $self->merge( $slot, @slots );
        }
        elsif ( $slot->start <= $new->start and $new->end <= $slot->end ) {
			warn "-----------------CONTAINS";
            return ($slot, @slots);
        }
        elsif ( $new->start < $slot->start and $slot->end < $new->end ) {
			warn "-----------------AMPL";
            $slot->start( $new->start );
            $slot->end( $new->end );
            return $self->merge( $slot, @slots );
        }
		else {
			warn "-----------------ADDED";
			return ($slot, $self->merge( $new, @slots) );
		}
    } else {
        if ( $slot->start == $new->start and $slot->end == $new->end ) {
			warn "-----------------DIF SAME";
            return $self->merge($new, @slots);
        }
        elsif ( $new->start < $slot->start and $new->end >= $slot->start and $new->end <= $slot->end ) {
			warn "-----------------DIF TA";
            $slot->start( $new->end );
            return ($slot, $self->merge( $new, @slots ) );
        }
        elsif ( $new->start >= $slot->start and $new->start < $slot->end and $new->end >= $slot->end ) {
			warn "-----------------DIF BA";
            $slot->end( $new->start );
            return ($slot, $self->merge( $new, @slots ) );
        }
        elsif ( $slot->start < $new->start and $new->end < $slot->end ) {
            warn "-----------------DIF CONT";
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
			warn "-----------------DIF AMPL";
            return $self->merge( $new, @slots );
        }
		else {
			warn "-----------------DIF ADDED";
			return ($slot, $self->merge( $new, @slots) );
		}
	}
}

sub all {
	my $self = shift;
	@{ $self->slots };
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
	for my $slot ( $self->list ) {
        return $slot
          if $slot->contains(%args);
	}
}

sub find_name {
	my $slot;
	return $slot->name if $slot = find( @_ );
}

1;

