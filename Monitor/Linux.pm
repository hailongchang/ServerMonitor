package Monitor::Linux;

use strict;
use warnings;
use Carp qw(croak carp);
use Try::Tiny;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(psys pid sysload sysmem syscpu osdesp dusage);
our $version = "0.1.3";


sub psys{
    my($pid) = @_;
    croak("process id is must") unless defined $pid;

    try{
	my ($cpu,$mem) = 
	    (split(/\h+/,qx/ps -u -h --pid $pid/))[2,3];
	return ($cpu,$mem);
    }
    catch{
	croak("$_");
    }
}

sub pid{
    my($pnmregx) = @_;
    croak("pnmregx is must") unless defined $pnmregx;
    my $pid;
    try{
	#get the first match item.
	$pid = (split(/\v/, qx/pgrep $pnmregx/))[0];
	return $pid;
    }
    catch{
	croak("$_");
    };
}

sub sysload{
    try{
	my $loadfm = "/proc/loadavg";
	my $loadavg = (split /\h+/,qx/cat $loadfm/)[0];
	return $loadavg;
    }
    catch{
	croak("$_");
    }
}

sub sysmem{
    try{
	my $meminfo = "/proc/meminfo";
	my($l1,$l2,$l3,$l4) = 
	    (split /\v+/,qx/head -n 4 $meminfo/);
	my ($total_mem,$total_free);
	my $wlinux = &_wlinux();
	croak("read /proc/meminfo error.") unless defined $wlinux;	
	if($wlinux eq "fedora")
	{
	    $l1 =~ s/\h+kB$//g;
	    $l3 =~ s/\h+kB$//g;	    
	    $total_mem = (split /:\h+/,$l1)[1];
	    $total_free = (split /:\h+/,$l3)[1];
	}
	if($wlinux eq "ubuntu"){
	    $l1 =~ s/\h+kB$//g;
	    $l2 =~ s/\h+kB$//g;	    
	    $l3 =~ s/\h+kB$//g;
	    $l4 =~ s/\h+kB$//g;	    
	    my $s2 = (split /:\h+/,$l2)[1];
	    my $s3 = (split /:\h+/,$l3)[1];
	    my $s4 = (split /:\h+/,$l4)[1];
	    $total_mem = (split /:\h+/,$l1)[1];
	    $total_free = $s2 + $s3 + $s4;
	}
	my $percen_mm = sprintf("%.2f",
		   100*($total_mem - $total_free)/($total_mem));
	return $percen_mm;
    }
    catch{
	croak("$_");
    }    
}

sub syscpu{
    try{
	my $cpuinfo = "/proc/stat";
	my @cputimes = (split /\h+/,qx/head -n 1 $cpuinfo/);
	my $total_time = 0;
	my $idle_time = 0;
	
	$total_time += $cputimes[$_] for(1..@cputimes-1);
	$idle_time = $cputimes[4];
	return ($total_time,$idle_time);
    }
    catch{
	croak("$_");
    }    
}


sub osdesp{    
    my $ver = (split/:/,qx/lsb_release -d/)[1];
    chomp($ver);
    $ver =~ s/^\s//g;
    return $ver;
}

sub dusage{
    try{
	my @ops = qx{df -l | grep "/dev/sd*"};
	my $size = 0;
	my $usize = 0;
	for (@ops){
	    my ($sz,$uz) = (split/\h+/, $_)[1,2];
	    $size += $sz;
	    $usize += $uz;
	}

	my $du = sprintf("%.2f",($usize/$size)*100);
	return $du;
    }
    catch{
	return 0;
    }
}

1;
