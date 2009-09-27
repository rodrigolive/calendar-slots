use strict;
use warnings;
use Test::More tests => 23;
use Calendar::Slots;
use DateTime;
use YAML;
sub _dump {  print Dump @_ }

{
	my $cal = new Calendar::Slots; 
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	is( $cal->find_name( date=>'2009-10-11', time=>'10:30' ), 'normal', 'time found' );
	ok( $cal->find_name( date=>'2009-10-11', time=>'11:29' ), 'time found closely' );
	ok( !$cal->find_name( date=>'2009-10-11', time=>'11:30' ), 'time not found' );
}
{
	my $cal = new Calendar::Slots();
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'11:30', end=>'22:30', name=>'urgent' ); 
	is( $cal->find_name( date=>'2009-10-11', time=>'11:30' ), 'urgent', 'urgent time found' );
	my $event = $cal->find( date=>'2009-10-11', time=>'11:30' );
	ok( ref $event, 'urgent event object exits'); 
	#$cal->weekday_event( day=>0, start=>'10:30', end=>'11:30', name=>'normal' );
}
{
	my $cal = new Calendar::Slots();
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'11:30', end=>'22:30', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'bottom adjacent events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'22:29' ), 'normal', 'bottom adjacent normal time found' );
}
{
	my $cal = new Calendar::Slots;
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'1:00', end=>'10:30', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'top adjacent events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'9:30' ), 'normal', 'top adjacent normal time found' );
}
{
	my $cal = new Calendar::Slots;
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'same events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'10:30' ), 'normal', 'same normal time found' );
}
{
	my $cal = new Calendar::Slots;
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'11:00', end=>'22:30', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'bottom crossed events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'11:30' ), 'normal', 'bottom crossed normal time found' );
}
{
	my $cal = new Calendar::Slots;
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'1:00', end=>'11:00', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'top crossed events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'1:30' ), 'normal', 'top crossed normal time found' );
}
{
	my $cal = new Calendar::Slots;
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'12:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'0:30', end=>'11:30', name=>'normal' ); 
	my @rows = $cal->list;
	is( scalar(@rows), 1, 'many overlapping events merged' );
	is( $cal->find_name( date=>'2009-10-11', time=>'0:30' ), 'normal', 'many overlapping normal time found top' );
	is( $cal->find_name( date=>'2009-10-11', time=>'11:00' ), 'normal', 'many overlapping normal time found bottom' );
}
{
	my $cal = new Calendar::Slots();
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'11:30', name=>'normal' ); 
	$cal->event( date=>'2009-10-11', start=>'11:00', end=>'22:30', name=>'urgent' ); 

	is( $cal->find_name( date=>'2009-10-11', time=>'10:59' ), 'normal', 'overlapping normal time found' );
	is( $cal->find_name( date=>'2009-10-11', time=>'11:00' ), 'urgent', 'overlapping urgent time found' );

	$cal->event( date=>'2009-10-11', start=>'11:00', end=>'22:00', name=>'normal' ); 

	is( $cal->find_name( date=>'2009-10-11', time=>'11:00' ), 'normal', 'split normal time found' );
	is( $cal->find_name( date=>'2009-10-11', time=>'21:59' ), 'normal', 'split late normal time found' );
	is( $cal->find_name( date=>'2009-10-11', time=>'22:00' ), 'urgent', 'split urgent time found' );
	is( $cal->num_events, 2, 'many overlapping events merged' );

	$cal->event( date=>'2009-10-11', start=>'12:00', end=>'13:00', name=>'urgent' ); 

	is( $cal->find_name( date=>'2009-10-11', time=>'12:00' ), 'urgent', 'split content urgent time found' );
	is( $cal->num_events, 4, 'many overlapping events merged' );

	$cal->event( date=>'2009-10-11', start=>'11:50', end=>'12:30', name=>'normal' ); 

	is( $cal->find_name( date=>'2009-10-11', time=>'12:00' ), 'normal', 're-split content normal time found' );
	is( $cal->find_name( date=>'2009-10-11', time=>'12:30' ), 'urgent', 're-split content urgent time found' );
	is( $cal->num_events, 4, 'many overlapping events merged' );

	$cal->event( date=>'2009-10-11', start=>'11:00', end=>'16:30', name=>'normal' ); 

	is( $cal->num_events, 2, 'many overlapping events merged' );
}
{
	# midnight crossed event
	my $cal = new Calendar::Slots();
	$cal->event( date=>'2009-10-11', start=>'10:30', end=>'00:30', name=>'normal' ); 
	is( $cal->find_name( date=>'2009-10-11', time=>'00:15' ), 'normal', 'midnight normal time found' );
}

#done_testing;
