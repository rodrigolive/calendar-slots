package Calendar::Slots::Utils;
use strict;
use warnings;

use vars qw(@ISA @EXPORT @EXPORT_OK $default_options);
require Exporter;
@ISA=qw(Exporter Data::Startup);
@EXPORT = qw/format_args/; 

sub format_args {
	my %args = @_;
    $args{$_} =~ s{[\-|\:|\s]}{}g for keys %args;
	return %args;
}



1;
