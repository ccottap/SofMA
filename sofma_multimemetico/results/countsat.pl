#!/usr/bin/perl

use strict;
use warnings;

sub binomial{
    my $n = shift;
    my $k = shift;
	my $r = 1;
	for (1 .. $k){
        $r *= $n + 1 - $_, $r /= $_;
    }
#    print "binomial($n, $k) = $r\n";
	return int($r);
}


sub countsat {
	my $x = shift;
	my $n = shift || die "how many bits has the chromosome?";
    return $x + $n*($n-1)*($n-2) - 2*($n-2)*binomial($x,2) + 6*binomial($x,3);
}


my $max_fitness = countsat(32, 32);
