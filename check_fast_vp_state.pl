#!/usr/bin/perl
use warnings;
use strict;
use Sys::Hostname;

my $host = hostname;
my $lun;
my @fastvpstate;
my $nagios_str;
my $nagios_code;

if ($host eq "drs1tsm01") {
  $lun = 41;
}
elsif ($host eq "cxpprod3") {
  $lun = 42;
}
else {
  $lun = 42;
}
open my $fh, "/usr/symcli/bin/symfast -sid $lun list -state |" or die "Can't pipe from symfast: $!";
while (my $line = <$fh>) {
  chomp $line;
  next unless $line =~ /^FAST VP State/;
#  @fastvpstate = split(/\s+:\s+/, $line);
  @fastvpstate = split(/:/, $line);
}

close $fh;

if (@fastvpstate) {
  for my $unit (@fastvpstate) {
    $unit =~ s/^\s+//;
    $unit =~ s/\s+$//;
  }

  if ($fastvpstate[1] eq "Enabled") {
    $nagios_str = "FAST VP State enabled";
    $nagios_code = 0;
  }
  else {
    $nagios_str = "FAST VP State problem";
    $nagios_code = 1;

  }
}
else {
  $nagios_str = "FAST VP State unknown, please investigate";
  $nagios_code = 3;
}

print $nagios_str;
exit $nagios_code;
