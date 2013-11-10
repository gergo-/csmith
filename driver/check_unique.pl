#!/usr/bin/perl -w

use strict;
use File::Temp;

my $strings = $ARGV[0];
die unless defined ($strings);
my $dir = $ARGV[1];
die unless defined ($dir);
my $opt = $ARGV[2];
die unless defined ($opt);
my $comp = $ARGV[3];
die unless defined ($comp);

# TODO: 
# randomize optimization flag instead of using the one given to us?
# don't treat processors individually; that will require some locking

my $cmd = "$comp $opt -c -w small.c > crash.txt 2>&1";
# print "$cmd\n";
system $cmd;

my $err;
open INF, "<crash.txt" or die;
while (my $line = <INF>) {
    chomp $line;
    # for now, we only support uniqueness checking for a few specific kinds of error
    if ($line =~ /internal compiler error: (.*)$/) {
	$err = $1;
    } elsif ($line =~ =~ /Assertion(.*)failed./m) {
	$err = $1;
    } else {
	exit 0;
    }
}
close INF;

# escape the string so we can use it in a shell command
$err =~ s/[.*+?|\(\)\'\"\`\[\]\{\}\\]/\\$&/g;

my $lines = "";
my $found = 0;
my $cnt;

open INF, "<$strings" or die;
while (my $line = <INF>) {
    chomp $line;
    die unless ($line =~ /^([0-9]+) <<< (.*) >>>$/);
    if ($2 eq $err) {
	$found = 1;
    }
}
close INF;

if (!$found) {
    open OUTF, ">>$strings" or die;
    print OUTF "10000000 <<< $err >>>\n";
    close OUTF;
    my $tmpfn = File::Temp::tempnam ($dir, "crashXXXXXX").".c";
    system "cp small.c ${tmpfn}";
    open OUTF, ">>${tmpfn}" or die;
    print OUTF "// '$err' <- '$comp $opt'\n";
    close OUTF;
}

exit 0
