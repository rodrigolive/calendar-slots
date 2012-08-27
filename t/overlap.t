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

done_testing;
