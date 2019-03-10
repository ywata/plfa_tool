#!/usr/bin/perl

use strict;
use Getopt::Long qw(:config posix_default no_ignore_case gnu_compat );
use Unicode::UCD qw/charinfo/;
use utf8;

my $MAX_SHOW_TIMES = 3;
my $debug    = 0;
my $update   = 0;


my $oldsignal = $SIG{__WARN__};
$SIG{__WARN__} = sub {}; # drop it. GetOption raise warn if unknown option is provided.
my $opt = GetOptions(
    "help" => sub {usage()},
    "debug" => \$debug,
    "update" => \$update
    );
$SIG{__WARN__} = $oldsignal; # recover handler.

binmode(STDOUT, ":utf8");
binmode(STDERR, ":utf8");
binmode(STDIN, "<:utf8");

if($#ARGV == 1){
    my $CHAPTERS             = $ARGV[0];
    my $UNICODE_INSTRUCTIONS = $ARGV[1];

    my @line_of_chapter_file = &readLines($CHAPTERS);
    my ($chapter, %chapter_max_instructions) = &parseChapterLine(@line_of_chapter_file);
    my(@chapters) = @{$chapter};
    my %unicode_instructions = &readUnicode($UNICODE_INSTRUCTIONS);

    my ($all, $selected) = &generate_characters(\@chapters, \%unicode_instructions, , \%chapter_max_instructions);

    my %target;

# set $target based on $debug
    if($debug){
	%target = %{$all};
    }else{
	%target = %{$selected};
    }

# main
    foreach my $file (@chapters){
	my @chars = @{$target{$file}};
	my $message = &generate_instruction(\@chars, \%unicode_instructions);
	if($update){
	    &force_replace_instructions($file, $message);
	}else{
	    print <<"EOF";
$file
$message
EOF
	}
    }
}elsif($#ARGV == 0){
    my $UNICODE_INSTRUCTIONS = $ARGV[0];
    &checkUnicodeInstruction($UNICODE_INSTRUCTIONS);
}else{
    &usage;
    exit 1;
}


sub parseChapterLine{
    my(@line) = @_;
    my(@chapters);
    my(%chapter_max_show);
    foreach my $l (@line){
	if($l =~ m|(\d+)\s+([a-zA-Z0-9\.]+)$|){
	    $chapter_max_show{$2} = $1;
	    push @chapters, $2;
	}elsif($l =~ m|([a-zA-Z0-9\.]+)|){
	    $chapter_max_show{$1} = $MAX_SHOW_TIMES;
	    push @chapters, $1;
	}
    }
    return(\@chapters, %chapter_max_show);
}


# forcefully update original file
sub force_replace_instructions{
    my($file, $message) = @_;

    open(my $F, "<:encoding(UTF-8)", $file) or die $!;
    local $/;
    my $contents = <$F>;
    close($F);
    my($instruction_block);

    $contents =~ s/\n(((    .  U\+[0-9A-F]+) .+\n)+)/\n$message/;

    open(my $F, ">:encoding(UTF-8)", $file) or die $!;
    print $F $contents;
    close($F);
}

# return file -> array of unicode characters for all character and characters selected.
sub generate_characters{
    my($chapters, $uni_instr, $num_show) = @_;
    my(@chapters) = @{$chapters};
    my(%unicode_instructions) = %{$uni_instr};
    my(%chapter_max_instructions) = %{$num_show};
    my %char_counter;
    my %all;
    my %result;
    foreach my $file (@chapters){
	my $contents = &readFile($file);
	my @uniq = sort(&uniq(&dropAscii($contents)));

	my @r; # @result
	foreach my $c (@uniq){
	    $char_counter{$c} = $char_counter{$c} + 1;
	    if($char_counter{$c} <= $chapter_max_instructions{$file}){
		push @r, $c;
	    }
	}
	$all{$file} = \@uniq;
	$result{$file} = \@r;
    }
    return (\%all, \%result);
}

# 
sub generate_instruction{
    my($characters, $uni_instr) = @_;
    my(@characters) = @{$characters};
    my(%unicode_instructions) = %{$uni_instr};

    my ($found, $missing) = &format(\%unicode_instructions, @characters);
    my $instructions;
    if($debug){
	$instructions = $found . $missing;
    }else{
	$instructions = $found;
    }
    return $instructions;
}

# format instruction.
sub format{
    my($instr, @chars) = @_;
    my(%instr) = %{$instr};
    my $missing;
    my $found;

    foreach my $c (@chars){
	if(defined($instr{$c})){
	    $found .= "    $c$instr{$c}\n";
	}else{
	    $missing .= "$c not found\n";
	}
    }
    return ($found, $missing);
}

# remove character duplication supplied by argument
sub uniq{
    my($contents) = @_;
    my @res = split //, $contents;
    my %res;
    foreach my $c (@res){
	$res{$c} = $c;
    }
    my @r = keys %res;
    return @r;
}

# drop ascii characters
sub dropAscii{
    my ($contents) = @_;
    $contents =~ s/[ -~\r\n\t]//g;
    return $contents;
}

# read entire file in String
sub readFile{
    my($lagda_file) = @_;
    local $/;
    open(my $LAGDA_FILE, "<:encoding(UTF-8)", $lagda_file) or die $!;
    my $lagda = <$LAGDA_FILE>;  # Read entire file in string!
    close($LAGDA_FILE);

    return $lagda;
}


# read unicode instruction.
# return hash of unicode character to instruction message
sub readUnicode{
    my($file) = @_;
    my @lines = &readLines($file);
    my %unicode;
    foreach my $l (@lines){
	$l =~ s/^\s+(.)(.+)//;
	$unicode{$1} = $2;
    }
    return %unicode;
}

# read file and return array
sub readLines{
    my($file) = @_;
    open(my $F, "<:encoding(UTF-8)", $file) or die $!;
    my @res;
    while(my $l = <$F>){
	chomp $l;
	if($l ne ""){
	    push @res, $l;
	}
    }
    close($F);
    return @res;
}

sub writeString{
    my($file, $str) = @_;
    open(my $F, ">:encoding(UTF-8)", $file) or die $!;
    print $F $str;
    close($F);
}

sub checkUnicodeInstruction{
    my($file) = @_;

    open(my $F, "<:encoding(UTF-8)", $file) or die "$!:$file";
    while(my $l = <$F>){
	if($l =~ m|^    (.)  (U\+[0-9A-F]+)  ([A-Z\- ]+)|){
	    &checkUnicodeInstructionValidity($1, $2, $3);
	}elsif($l =~ m|^    (.)|){
	    &checkUnicodeCodepoint($1);
	}
    }
    close $F;
}

sub checkUnicodeCodepoint{
    my($char) = @_;
    my($cp) = &getUnicodeCodepoint($char);
    my %charinfo = %{charinfo($cp)};

    print "    $char  $cp  $charinfo{name}\n";
}

sub checkUnicodeInstructionValidity{
    my ($char, $code_point, $name) = @_;
    $name =~ s/ +$//;
    #    print "$1 $2 $3\n";
    my $charinfo = charinfo($code_point);
    my %charinfo = %{$charinfo};

    if($name ne $charinfo{name}){
	print "$code_point\n$name\n$charinfo{name}\n\n";
    }

    my $cpp = &getUnicodeCodepoint($char);
    if($cpp ne $code_point){
	print "$code_point\n";
    }else{
#	print "$cpp $code_point\n";
    }
}

sub getUnicodeCodepoint{
    my($char) = @_;
    use Encode qw/decode_utf8/;
    use Data::Dumper;

    my $cp = Dumper(decode_utf8($char));
    $cp =~ m|^\$VAR1 = ...{(.+)}|;
    my $cpp = $1;
    $cpp =~ tr/[a-z]/[A-Z]/;
    if(length($cpp) == 2){
	$cpp = "U+00$cpp";
    }elsif(length($cpp) == 3){
	$cpp = "U+0$cpp";
    }else{
	$cpp = "U+$cpp";
    }
    return $cpp;
}

sub usage{
    print STDERR <<"EOF";
usage: $0 [--debug|--update] chapter_file unicode_instruction_file
This style checks and/or update unicode sections of chapters that
appears in chapter_file. 
This format accepts two options:
--debug: all the unicode characters are target
         if this is not set, characters are selected at most $MAX_SHOW_TIMES
         in chapter order.
--update: force update .lagda file
         if this is not set, result is printed on screen.

usage: $0 unicode_instruction_file
This style checks unicode_instruction_file. It checks unicode
characters against code point and name. If they do not coinsides
they are reported.
If code point and name are missing, code point and name are printed.
--debug and --update does not affect for this style.
EOF
}
__END__
