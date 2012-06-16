#!/usr/bin/env perl

use strict;
use warnings;
# use Smart::Comments;

my %vbox = (
  manager  => 'VBoxManage',
);
my (%ebox, @vms, %what);

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

# get list of VirtualBox machines and their info
open(my $machines, '-|', "$ebox{manager} list -l vms")
  or die "Can't run $ebox{manager}: $!\n";
{
  # hack to split machine info after state
  local $/ = 'Monitor count';
  while (<$machines>) {
    my @info = split /\n/;
    my $vm_info;
    foreach (@info) {
      next unless m/^(Name|Guest OS|UUID|State):\s+([\w\s.-]+)/;
      $vm_info->{$1} = $2;
    }
    ### VM Info: $vm_info
    if ($vm_info) {
      push @vms, $vm_info;
    }
  }
}
close $machines or die "$!\n";
### @vms

system("clear");

sub show_in_menu {
  my ($index, $action, $name, $type) = @_;
  $type = $type ? "[$type]" : '';
  printf qq(%3s. %s\t %s %s\n), $index, $action, $name, $type;
}

show_in_menu('q', 'Exit', '');
foreach my $index ( 0 .. $#vms) {
  my %vbox = %{$vms[$index]};
  foreach (keys %vbox) {
    next unless m/State/;
    my $action = 'Run   ';
    my $type = 'gui';
    if ( $vbox{State} =~ /(saved|off)/) {
      $action = 'Wake  ' if $1 eq 'saved';
      unless ($vbox{'Guest OS'} =~ /windows/i ) {
        my $type = 'headless';
        $what{$index} = qq($ebox{manager} startvm $vbox{UUID} --type $type);
        show_in_menu($index, $action, $vbox{Name}, $type);
      }
      $index .= 'g' unless $vbox{'Guest OS'} =~ /windows/i;
      $what{$index} = qq($ebox{manager} startvm $vbox{UUID} --type $type);
    } elsif ($vbox{State} =~ /running/) {
      $action = 'Save  ';
      $what{$index} = qq($ebox{manager} controlvm $vbox{UUID} savestate);
    }
    elsif ($vbox{State} =~ /paused/) {
      $action = 'Resume';
      $what{$index} = qq($ebox{manager} controlvm $vbox{UUID} resume);
    }
    else {
      $index = '#';
      $action = $vbox{State};
    }
    show_in_menu($index, $action, $vbox{Name}, $type);
  }
}
### %what
print "Please choose action: ";
my $answer = <STDIN>;
chomp $answer;
`$what{$answer}` if exists $what{$answer};
print qq(See you later\n);
