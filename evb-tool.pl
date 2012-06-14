#!/usr/bin/env perl

use strict;
use warnings;
#use Smart::Comments;

my %vbox = (
  manager  => 'VBoxManage',
);
my (%ebox, %vms, %what);

# check for needed commands and give their full path
foreach (keys %vbox) {
  my $which = `which $vbox{$_}`;
  chomp $which;
  ### $which
  unless ($which) {
    die qq(You don't have '$vbox{$_}' in your \$PATH variable\n);
  }
  $ebox{$_} = $which;
}
### %ebox

# get list of VirtualBox machines
open(my $machines, '-|', "$ebox{manager} list vms")
  or die "Can't run $ebox{manager}: $!\n";
while (<$machines>) {
  chomp;
  my ($name, $uuid) = split;
  $uuid =~ s/[{}]//g;
  $vms{$uuid}{name} = $name;
}
close $machines or die "$!\n";

# get state of VirtualBox machines
foreach my $uuid (keys %vms) {
  open(my $state, '-|', "$ebox{manager} showvminfo $uuid --machinereadable")
    or die "Can't run $ebox{manager}: $!\n";
  while (<$state>) {
    chomp;
    next unless /^(VMState|GuestOSType)="(\w+)"/;
    $vms{$uuid}{$1} = $2;
  }
  close $state or die "$!\n";
}
### %vms
# Show menu with commands
system("clear");

my $i;
print "0. exit\n";
$what{0} = '';
foreach (keys %vms) {
  if ($vms{$_}{VMState} =~ /saved|poweroff/) {
    my $type = $vms{$_}{GuestOSType} =~ /windows/i ? 'gui' : 'headless';
    print ++$i, '. Start', "\t",  $vms{$_}{name}, "\n";
    $what{$i} = qq($ebox{manager} startvm $_ --type $type);
  }
  elsif ($vms{$_}{VMState} =~ /running/) {
    print ++$i, '. Save ', "\t", $vms{$_}{name}, "\n";
    $what{$i} = qq($ebox{manager} controlvm $_ savestate);
  }
}
### %what
print "Please choose action: ";
my $answer = <STDIN>;
chomp $answer;
`$what{$answer}`;
