use strict;
use warnings;
use Test::More; 
use Calendar::Slots;
use DateTime;
sub _dump {  require YAML; warn YAML::Dump( @_ ) }

{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'10:00', end=>'14:00', name=>'normal' );
    $cal->slot( weekday=>1, start=>'12:00', end=>'14:00', name=>'normal' );
    my $slot = $cal->find( weekday=>1, time=>'11:00' );
    ok ref $slot, 'ok overlap ref';
    is  $cal->find( weekday=>1, time=>'11:00' )->name, 'normal' , 'ok overlap'
        if ref $slot;
    is scalar( $cal->all ), 1, 'overlap just one';
    # _dump [ $cal->all ];
}
{
    # make sure dates are converted to weekdays and merged
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'14:00', name=>'normal' );
    is scalar( $cal->all ), 2, 'date + wk, overlap just one';
    #ok $cal->find( weekday=>1, time=>'13:00' )->end eq 15, 'merged date + wk';
    #my ($first) = $cal->all;
    #ok $first->start eq '0000', 'date + wk start';
    #ok $first->end eq '1400', 'date + wk start';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'14:00', name=>'normal' );
    $cal->slot( date=>20110822, start=>'12:00', end=>'23:30', name=>'normal' );

    my $mat = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $mat->num_slots , 1, 'just one slot';
    my $slot = $mat->find( weekday=>1, time=>'11:00' );
    is $slot->end , '1500', 'just one slot';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' );
    $cal->slot( date=>20110822, start=>'12:00', end=>'23:30', name=>'normal' );

    my $mat = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $mat->num_slots , 1, 'just one slot2';
    my $slot = $mat->find( weekday=>1, time=>'19:00' );
    is $slot->end , '2100', 'just one slot2';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'15:00', name=>'normal' );
    $cal->slot( weekday=>2, start=>'00:00', end=>'10:00', name=>'normal' ); # tue
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' ); 
    $cal->slot( date=>20110823, start=>'12:00', end=>'23:30', name=>'normal' ); # tue

    $cal = $cal->week_of( '2011-08-24' );  # wed; monday on 8/22
    is $cal->num_slots , 3, 'three materialized';
    my $slot = $cal->find( weekday=>2, time=>'19:00' );
    is $slot->end , '2330', 'just one slot2';
}
{
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'24:00', name=>'normal' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'normal' ); 
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    is $cal->num_slots , 1, 'one materialized';
    #my $slot = $cal->find( weekday=>2, time=>'19:00' );
    #is $slot->end , '2330', 'just one slot2';
}
OO: {
    my $cal = new Calendar::Slots;
    $cal->slot( weekday=>1, start=>'00:00', end=>'24:00', name=>'B' );
    $cal->slot( date=>20120827, start=>'12:00', end=>'21:00', name=>'N' ); 
    $cal = $cal->week_of( '2012-08-29' );  # wed; monday on 8/27
    #_dump $cal;
    is $cal->num_slots , 3, 'three materialized';
    my $slot = $cal->find( weekday=>1, time=>'19:00' );
    is $slot->end , '2100', 'split slot';
}

done_testing;
