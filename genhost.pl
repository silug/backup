#!/usr/bin/perl -w
#
# $Id: genhost.pl,v 1.5 2008/01/09 19:40:38 steve Exp $

use strict;
use warnings;

my $host=shift;

if (!$host) {
    print STDERR "Usage: genhost.pl <hostname>\n";
    exit 1;
}

my @fs;

#open(DF, "ssh $host df |");

#while (<DF>) {
#    my @foo=split;
#    push(@fs, $foo[$#foo]) if ($foo[0]=~/^\/dev\// and $foo[$#foo] ne "/tmp");
#}

#close(DF);

my @df=`ssh $host df` or die "Failed to run df: $!\n";
shift @df;

for (my $n=0;$n<@df;$n++) {
    chomp $df[$n];
    if ($df[$n]=~/^\s/) {
        $df[$n-1].=$df[$n];
        splice(@df,$n,1);
        $n--;
    }
}

for my $n (@df) {
    my @foo=split ' ', $n;
    push(@fs, $foo[$#foo]) if ($foo[0]=~/^\/dev\// and $foo[$#foo] ne "/tmp");
}

print "# filesystem\tcommand\n";

for my $fs (@fs) {
    print "$fs";
    my @children=&find_children($fs, @fs);
    if (@children) {
        print "\tDEFAULT";
        for my $child (@children) {
            print " --exclude $child";
        }
    }
    print "\n";
}

sub find_children {
    my ($fs, @fs)=@_;

    my @children;

    for my $child (@fs) {
        next if ($child eq $fs);
        if ($child=~/^$fs\// or $fs eq "/") {
            $child=~s/^$fs//;
            $child="/$child/";
            $child=~s,^//+,/,;
            $child=~s,//+$,/,;
            push(@children, $child);
        }
    }

    for (my $n=0;$n<@children;$n++) {
        @children=grep { $_ eq $children[$n] or !/^$children[$n]/ } @children;
    }

    return @children;
}

# vi: set ai et:
