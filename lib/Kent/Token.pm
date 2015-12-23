package Kent::Token;
use common::sense;

use Kent::Lexer::Rules    ();
use Kent::Lexer::Keywords ();

my $rule_table = Kent::Lexer::Rules::table;
my %keywords   = %Kent::Lexer::Keywords::keywords;

sub new {
    my ( $class, %args ) = @_;

    my $self = { 'name'   => $args{name},
                 'raw'    => $args{raw},
                 'width'  => length( $args{raw} ),
                 'line'   => $args{line},
                 'column' => $args{column}, };

    # Is this a keyword?
    if ( $self->{name} eq 'ID' && exists $keywords{ $self->{raw} } ) {
        $self->{name} = "kw_$self->{raw}";
    }

    return bless $self, $class;
}

sub name   { $_[0]->{name}; }
sub width  { $_[0]->{width}; }
sub raw    { $_[0]->{raw}; }
sub line   { $_[0]->{line}; }
sub column { $_[0]->{line}; }

1;
