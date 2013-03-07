#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

my %db  = ();
my @rec = ();

sub flush {
  $db{ $rec[0] } = {
    lat => $rec[1],
    lon => $rec[2] } if @rec;
  @rec = ();
}

while (<>) {
  chomp;
  if (/^\|-/) {
    flush();
  }
  elsif (/^\|\s+(.+)/) {
    push @rec, $1;
  }
}
flush();

print JSON->new->pretty->canonical->encode( \%db );

# vim:ts=2:sw=2:sts=2:et:ft=perl

