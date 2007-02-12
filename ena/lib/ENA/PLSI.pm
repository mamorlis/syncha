#
# PLSI ¤ò»È¤¦¥â¥¸¥å¡¼¥ë
#
package ENA::PLSI;

use Exporter;
our @ISA = qw(ENA);
our $VERSION = '0.0.1';

use strict;
use warnings;

use Carp qw(carp croak);
use Data::Dumper;

# location of results
use FindBin;
my $plsi_dir    = "$FindBin::Script/../dat/plsi";
my $plsi_base   = 'n10/';
my $plsi_prefix = 'n10';
my $Ndic_file   = $plsi_dir.'Ndic';
my $Vdic_file   = $plsi_dir.'Vdic';
my $pdz_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pdz';
my $pzd_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pzd';
my $pd_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pd' ;
my $pwz_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pwz';
my $pzw_file    = $plsi_dir.$plsi_base.$plsi_prefix.'.pzw';
my $pw_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pw' ;
my $pz_file     = $plsi_dir.$plsi_base.$plsi_prefix.'.pz' ;

my $plsi_file   = "$plsi_dir/${plsi_prefix}.result";

# coocurrence dictionary
my %cooc_dic;
# Set noun andd verb hashes
my (%noun_of, %verb_of);

sub slurp_plsi {
    my (@pwz_of, @pdz_of, @pz_of);

    open my $pz_fh, $pz_file or croak "Cannot open $pz_file";
    while (<$pz_fh>) {
        chomp;
        @pz_of = split;
    }
    close $pz_fh;
    #carp "Reading up $pz_file";

    open my $pdz_fh, $pdz_file or croak "Cannot open $pdz_file";
    my $z = 0;
    while (<$pdz_fh>) {
        chomp;
        my @pdz_i = split;
        push @pdz_of, \@pdz_i;
    }
    close $pdz_fh;
    #carp "Reading up $pdz_file";

    open my $pwz_fh, $pwz_file or croak "Cannot open $pwz_file";
    while (<$pwz_fh>) {
        chomp;
        my @pwz_i = split;
        push @pwz_of, \@pwz_i;
    }
    close $pwz_fh;
    #carp "Reading up $pwz_file";

    my %cooc_of;
    # determine wsize and dsize
    my $word_size = scalar @{ $pwz_of[0] };
    my $doc_size  = scalar @{ $pdz_of[0] };
    #carp $word_size, "\n", $doc_size;
    for (my $j = 0; $j < $word_size; $j++) {
        for (my $k = 0; $k < $doc_size; $k++) {
            $cooc_of{$j}{$k} = 0;
            for (my $i = 0; $i < @pz_of; $i++) {
                $cooc_of{$j}{$k}
                    += $pwz_of[$i][$j] * $pz_of[$i] * $pdz_of[$i][$k];
            }
            if ($cooc_of{$j}{$k} > 0 && log($cooc_of{$j}{$k}) > -10) {
                printf "%d  %d  %0.24f\n", $j, $k, $cooc_of{$j}{$k};
            }
        }
    }
}

sub set_cooc {
    open my $ndic_fh, $Ndic_file or croak "Cannot open $Ndic_file";
    while (<$ndic_fh>) {
        chomp;
        my ($noun_id, $lex_entry) = split;
        $noun_of{$noun_id} = $lex_entry;
    }
    close $ndic_fh;
    open my $vdic_fh, $Vdic_file or croak "Cannot open $Vdic_file";
    while (<$vdic_fh>) {
        chomp;
        my ($verb_id, $case_frame) = split;
        my ($case, $lex_entry) = split /:/, $case_frame;
        $verb_of{$verb_id} = $lex_entry;
    }
    close $vdic_fh;

    open my $cooc_fh, $plsi_file or croak "Cannot open $plsi_file";
    while (<$cooc_fh>) {
        chomp;
        my ($noun_id, $verb_id, $probability) = split;
        if ($probability > 0 && log($probability) > -10) {
            carp "$noun_id, $verb_id, $probability";
            $cooc_dic{$noun_of{$noun_id}}{$verb_of{$verb_id}}
                = $probability;
        }
    }
    close $cooc_fh;
}

sub get_cooc {
    my ($noun, $verb) = @_;
    return 0 unless $cooc_dic{$noun}{$verb};

    printf STDERR "cooc of %s and %s is %s\n",
        $noun, $verb, $cooc_dic{$noun}{$verb};
    return $cooc_dic{$noun}{$verb};
}

# taken from calc_mi.pl
BEGIN {
    unless (eval "use BerkeleyDB; 1") {
        use DB_File;
    }
}

my $Ndic      = "$ENV{ENA_DB_DIR}/n2id.db";
my $Vdic      = "$ENV{ENA_DB_DIR}/v2id.db";
my $ncv2score = "$ENV{ENA_DB_DIR}/ncv2score.db";

my (%Ndic, %Vdic, %ncv2score);
{
    no strict "subs";
    if (eval "require BerkeleyDB; 1") {
        tie %Ndic, 'BerkeleyDB::Hash',
            -Filename => $Ndic,
            -Flags    => DB_RDONLY,
            -Mode     => 0644
            or croak "Cannot open $Ndic:$!";
        tie %Vdic, 'BerkeleyDB::Hash',
            -Filename => $Vdic,
            -Flags    => DB_RDONLY,
            -Mode     => 0644
            or croak "Cannot open $Vdic:$!";
        tie %ncv2score, 'BerkeleyDB::Hash',
            -Filename => $ncv2score,
            -Flags    => DB_RDONLY,
            -Mode     => 0644
            or croak "Cannot open $ncv2score:$!";
    } elsif (eval "require DB_File; 1") {
        tie my %Ndic, 'DB_File', $Ndic, O_RDONLY, 0644
            or croak "Cannot open $Ndic:$!";
        tie my %Vdic, 'DB_File', $Vdic, O_RDONLY, 0644
            or croak "Cannot open $Vdic:$!";
        tie my %ncv2score, 'DB_File', $ncv2score, O_RDONLY, 0644
            or croak "Cannot open $ncv2score:$!";
    }
}

sub get_noun_word_form {
    my $morph = shift;
    my $WF = $morph->WF;
    $WF = '¡ã¸ÇÍ­Ì¾»ì'.$1.'¡ä' 
        if ($morph->POS =~ /^Ì¾»ì-¸ÇÍ­Ì¾»ì-(°ìÈÌ|¿ÍÌ¾|ÁÈ¿¥|ÃÏ°è)/);
    $WF = '¡ã¸ÇÍ­Ì¾»ì¿ÍÌ¾¡ä' if ($morph->NE =~ /PERSON/);
    $WF = '¡ã¸ÇÍ­Ì¾»ìÃÏ°è¡ä' if ($morph->NE =~ /LOCATION/);
    $WF = '¡ã¸ÇÍ­Ì¾»ìÁÈ¿¥¡ä' if ($morph->NE =~ /ORGANIZATION/);
    $WF = '¡ã¸ÇÍ­Ì¾»ì°ìÈÌ¡ä' if ($morph->NE =~ /ARTIFACT/);
    return $WF;
}

sub calc_mi {
    my ($noun, $verb) = @_; # for each morph
    my $noun_word_form = get_noun_word_form($noun);
    my $noun_id = $Ndic{$noun_word_form};
    my $verb_ga_id = $Vdic{"¤¬:$verb"};
    my $verb_wo_id = $Vdic{"¤ò:$verb"};
    my $verb_ni_id = $Vdic{"¤Ë:$verb"};
    #print STDERR "NOUN_WF: $noun_word_form, NOUN_ID: $noun_id\n";
    return '' unless ($noun_id);
    #print STDERR "VERB: $verb, GA_ID: $verb_ga_id, WO_ID: $verb_wo_id, NI_ID: $verb_ni_id\n";
    return '' unless ($verb_ga_id or $verb_wo_id or $verb_ni_id);

    my $GA = $noun_word_form.':¤¬:'.$verb;
    my $WO = $noun_word_form.':¤ò:'.$verb;
    my $NI = $noun_word_form.':¤Ë:'.$verb;
    #print STDERR "GA: $GA, WO: $WO, NI: $NI\n";

    my $score = (($ncv2score{$GA}) ? $ncv2score{$GA} : 0)
              + (($ncv2score{$WO}) ? $ncv2score{$WO} : 0)
              + (($ncv2score{$NI}) ? $ncv2score{$NI} : 0);
    if ($score) {
        return ($score eq '4294967295') ? '' : $score;
    } else {
        return 0;
    }
}

1;
