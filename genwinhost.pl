#!/usr/bin/perl -w
#
# $Id: genwinhost.pl,v 1.2 2001/07/16 20:11:54 steve Exp $

use strict;

if (@ARGV!=2 and @ARGV!=3)
{
    print STDERR
      "Usage: genwinhost.pl <hostname> <domain> [ <administrator password> ]\n";
    exit 1;
}

my ($host,$domain,$pass)=@ARGV;

if (@ARGV==2)
{
    if (!-t)
    {
	print STDERR "No password supplied, and we have no tty!\n";
	exit 1;
    }
    print STDERR "Password: ";
    system "stty -echo";
    $pass=<STDIN>;
    system "stty echo";
    print STDERR "\n";
    chomp $pass;
}

my @fs;

$ENV{'USER'}="administrator%$pass";
open(SMBCLIENT, "smbclient -L //'$host' -W '$domain' -N |")
    or die "smbclient failed: $!\n";

while (<SMBCLIENT>)
{
    my @foo=split;
    if (@foo>3 and $foo[0]=~/^([A-Z])\$$/ and $foo[1] eq "Disk")
    {
        push(@fs, $1);
    }
}

close(SMBCLIENT);

if (!@fs)
{
    print STDERR "No administrative shares found!\n";
    exit 1;
}

print "# filesystem\tcommand\n";

for my $fs (@fs)
{
    print <<END;
$fs	trap "umount /mnt/HOST/PATH" EXIT ; \\
	mkdir -p /mnt/HOST/PATH \\
	    2>/dev/null ; \\ # This can fail.
	mount -t smbfs '//HOST/PATH\$' \\
	    /mnt/HOST/PATH            \\ # This can't.
	    -o username=administrator,password=$pass,workgroup=$domain,ro && \\
	rsync -aW /mnt/HOST/PATH/. . --numeric-ids --partial --timeout=600 \\
	    --exclude /RECYCLER/ --exclude /pagefile.sys \\
	    EXTRAFLAGS
END
}
