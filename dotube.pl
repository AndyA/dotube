#!/usr/bin/env perl

use strict;
use warnings;

use Geo::Coordinates::OSGB qw( ll_to_grid );
use JSON;
use List::Util qw( min max );
use Path::Class;

use constant WIDTH  => 200;
use constant HEIGHT => 150;

use constant MAP => 'tube.json';

my $map    = load_json(MAP);
my $loc    = $map->{loc};
my $lines  = $map->{lines};
my %to_nd  = ();
my %to_en  = ();
my @names  = uniq( map { @{ $_->{stops} } } @$lines );
my $next   = 0;
my @no_loc = ();
my ( @e, @n );

for my $nm (@names) {
  $to_nd{$nm} = 'n' . ++$next;
  my $ln = delete $loc->{$nm};
  if ( defined $ln ) {
    my ( $east, $north ) = ll_to_grid( $ln->{lat}, $ln->{lon} );
    $to_en{$nm} = [$east, $north];
    push @e, $east;
    push @n, $north;
  }
  else {
    push @no_loc, $nm;
  }
}

my $emin = min(@e);
my $emax = max(@e);
my $nmin = min(@n);
my $nmax = max(@n);

sub scale {
  my ( $e, $n ) = @_;
  my $ee = ( $e - $emin ) * WIDTH /  ( $emax - $emin );
  my $nn = ( $n - $nmin ) * HEIGHT / ( $nmax - $nmin );
  return ( $ee, $nn );
}

print qq(graph "tube" {\n);
while ( my ( $name, $node ) = each %to_nd ) {
  my @extra = ();
  if ( my $loc = $to_en{$name} ) {
    my ( $x, $y ) = scale(@$loc);
    push @extra, qq{pos="$x,$y"};
  }
  print qq{  $node [},
   join( ', ',
    qq(label="$name"), 'color=none', 'shape=plaintext',
    'width=0.1', 'height=0.1', 'fontname="Gil Sans"',
    'fontsize=10', @extra ),
   qq{];\n};
}

for my $line (@$lines) {
  print qq{  edge [color="$line->{colour}", penwidth=4];\n};
  print '  ', join( ' -- ', map { $to_nd{$_} } @{ $line->{stops} } ),
   ";\n";
}

print qq(}\n);

sub nd { $to_nd{ $_[0] } ||= "n" . ++$next }
sub load_json { JSON->new->utf8->decode( scalar file( $_[0] )->slurp ) }

sub uniq {
  my %seen = ();
  return grep { !$seen{$_}++ } @_;
}

# vim:ts=2:sw=2:sts=2:et:ft=perl

