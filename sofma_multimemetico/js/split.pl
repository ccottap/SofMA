#!/usr/bin/perl

use strict;
use warnings;
use File::Slurp qw(read_file);
use Statistics::Basic qw(mean);
use v5.10;

my $file = read_file( shift );

my @chunks = split( /\n{2,}/, $file );

my @results;
for my $c (@chunks ) {
  my @lines = split( "\n", $c );
  if ( $#lines > 7000 ) {
    for ( my $i = 0; $i <$#lines; $i ++ ) {
      push @{$results[$i]}, $lines[$i];
    }
  }
}
for ( my $j = 512; $j < $#results; $j++ ) {
  say mean $results[$j];
}
