#!/usr/bin/perl -w
#
# $Id: genhost.pl,v 1.2 2001/07/11 20:54:38 steve Exp $

use strict;

my $host=shift;

if (!$host)
{
    print STDERR "Usage: genhost.pl <hostname>\n";
    exit 1;
}

my @fs;

open(DF, "ssh $host df |");

while (<DF>)
{
    my @foo=split;
    push(@fs, $foo[$#foo]) if ($foo[0]=~/^\/dev\// and $foo[$#foo] ne "/tmp");
}

close(DF);

for my $fs (@fs)
{
    print "$fs";
    my @children=&find_children($fs, @fs);
    if (@children)
    {
        print "\tDEFAULT";
	for my $child (@children)
	{
	    print " --exclude $child";
	}
    }
    print "\n";
}

sub find_children
{
    my ($fs, @fs)=@_;

    my @children;

    for my $child (@fs)
    {
	next if ($child eq $fs);
	if ($child=~/^$fs\// or $fs eq "/")
	{
	    $child=~s/^$fs//;
	    $child="/$child/";
	    $child=~s,^//+,/,;
	    $child=~s,//+$,/,;
	    push(@children, $child);
	}
    }

    for (my $n=0;$n<@children;$n++)
    {
	@children=grep { $_ eq $children[$n] or !/^$children[$n]/ } @children;
    }

    return @children;
}
