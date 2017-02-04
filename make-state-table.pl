#!/usr/bin/perl

use common::sense;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use JSON;

my $grammar_filename = 'grammar.csv';
my $debug            = 0;

my $printer = JSON->new->canonical( 1 )->pretty( 1 );

my $lines   = [];
my $choices = {};

open( my $fh, '<', $grammar_filename ) or die "Couldn't open $grammar_filename for reading: $!";
@{$lines} = <$fh>;
close $fh;

# first row is comments; chunk it
shift @{$lines};

my $rules   = rules_from_lines( $lines );
my $choices = choices_from_rules( $rules );
my $states  = states_from_choices( $choices );

print Dumper( $choices ) if $debug;

foreach my $state ( @{$states} ) {
    say "$state->{name}";
    if ( $state->{returns} ) {
        say "    return: $state->{returns} with $state->{depth} parts";
        say;
    }
    else {
        say "    nows:   $_" foreach @{ $state->{nows} };
        say "    nexts:  $_" foreach @{ $state->{nexts} };
        say "    others: $_" foreach @{ $state->{others} };
        say;
    }
}

sub rules_from_lines {
    my ( $lines ) = @_;
    my $rules = [];

    foreach my $line ( @{$lines} ) {
        my $rule = {};
        my @parts = split( /,/, $line );
        $rule->{token_name} = $parts[0];
        $rule->{parts}      = [ grep { $_ ne '' } @parts[ 1 .. 6 ] ];
        $rule->{category}   = $parts[7];
        $rule->{sort_order} = $parts[8];
        push @{$rules}, $rule;
    }
    return $rules;
}

sub choices_from_rules {
    my ( $rules ) = @_;
    my $choices = {};

    foreach my $rule ( @{$rules} ) {
        my @parts             = @{ $rule->{parts} };
        my $token_name        = $rule->{token_name};
        my $forbid_whitespace = $rule->{forbid_whitespace};

        @parts = grep { $_ ne '' } @parts;
        next if scalar @parts == 0;

        my $ref = $choices;

        if ( $debug ) {
            system( 'clear' );
            print "@parts -> $token_name\n";
            print $printer->encode( $choices );
            <>;
        }

        while ( 1 ) {

            my $part = shift @parts;

            if ( scalar @parts == 0 ) {
                if   ( ref $ref->{$part} eq 'HASH' ) { $ref->{$part}{'space'} = $token_name; }
                else                                 { $ref->{$part}          = $token_name; }
                last;
            }
            else {
                $ref->{$part} //= {};
                if ( ref $ref->{$part} eq 'HASH' ) {
                    $ref = $ref->{$part};
                }
                else {
                    my $holder = $ref->{$part};
                    $ref->{$part} = { 'space' => $holder };
                    $ref = $ref->{$part};
                }
            }
        }
    }
    return $choices;
}

sub states_from_choices {
    my ( $choices, $name_so_far, $depth ) = @_;
    my @states;

    $name_so_far //= '';
    $depth       //= 1;

    foreach my $key ( sort keys %$choices ) {
        if ( ref $choices->{$key} eq 'HASH' ) {

            # "nows" have to be checked before whitespace is discarded.
            #     ( "nows" is short for "no whitespace allowed" )
            # "nexts" are checked right after whitespace is discarded.
            #     They will call $name_so_far_$next.
            # "others" are checked last. Their return replaces the token being
            #     evaluated, and we go back to checking "nexts". They
            #     will call their own name, as if starting from scratch.
            my ( @nows, @nexts, @laters );
            foreach my $choice ( sort keys %{ $choices->{$key} } ) {
                next if ref $choice eq 'HASH';
                if   ( $choice =~ m/[*]/ ) { push @nows,  $choice; }
                else                       { push @nexts, $choice; }
            }

            foreach my $now ( @nows ) { $now =~ s/[*]//; }
            push @states,
                { name   => "$name_so_far$key",
                  nows   => \@nows,
                  nexts  => \@nexts,
                  others => find_valid_nexts( $choices->{$key} ),
                };
            push @states, @{ states_from_choices( $choices->{$key}, "$name_so_far$key\_", $depth + 1 ) };
        }
        else {
            push @states,
                { name    => "$name_so_far$key",
                  returns => $choices->{$key},
                  depth   => $depth, };
        }
    }
    foreach my $state ( @states ) { $state->{name} =~ s/[*]//; }
    return \@states;
}

sub find_valid_nexts {
    my ( $state ) = @_;
    my %valid_nexts;

    foreach my $key ( sort keys %{$state} ) {

        foreach my $rule ( grep { $_->{token_name} eq $key } @{$rules} ) {
            $valid_nexts{ $rule->{parts}[0] } = 1;
        }
    }

    return [ sort keys %valid_nexts ];
}
