#!/usr/bin/perl
package Kent;
use common::sense;

use Kent::Parser ();
use Kent::Util   ();
use Data::Dumper ();

script( @ARGV ) unless caller;

sub new {
    my ( $class ) = @_;
    return bless {}, $class;
}

sub script {
    my ( $filename ) = @_;
    my $sourcecode = Kent::Util::slurp( $filename );

    say "loaded source code from $filename";

    my $parser = Kent::Parser::BruteForce->new( sourcecode => $sourcecode );
    my $ast = $parser->parse();

    say Data::Dumper::Dumper($ast);

    return 1;
}

1;
