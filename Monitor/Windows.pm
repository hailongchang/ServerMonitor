package Monitor::Windows;

use strict;
use warnings;
use Carp qw/croak carp/;
use Win32::OLE qw/in/;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/new/;
our $version = "2.1.3";

use constant wbemFlagReturnImmediately => 0x10;
use constant wbemFlagForwardOnly => 0x20;
sub new{
    my $class = shift;
    my %args = @_;
    my $obj = {
	computerIP => "",
	username => "",
	password => "",
	wmiobj => undef,
	wbemobj => undef,
    };
    $obj->{$_} = $args{$_} for keys %args;

    $obj->{wbemobj} = Win32::OLE->new("WbemScripting.SWbemLocator") or die "ERROR CREATING OBJ: ", Win32::OLE->LastError;
    $obj->{wbemobj}->{Security_}->{impersonationlevel} = 3;
    $obj->{wmiobj} = $obj->{wbemobj}->ConnectServer($obj->{computerIP}, "root\\cimv2", $obj->{username}, $obj->{password}) 
	or die  "WMI connection failed.\n", Win32::OLE->LastError;
    if(defined $obj->{wbemobj} && defined $obj->{wmiobj}){
	bless $obj, $class;
	# return $obj;
    }else{
	return undef;
    }    
}

sub GetCpuLoad{
    my $self = shift;
    my $i = 0;
    my $total = 0;

    my $items = $self->{wmiobj}->ExecQuery("SELECT * FROM Win32_Processor", 
					     "WQL",
					     wbemFlagReturnImmediately | wbemFlagForwardOnly);    
    foreach my $it (in $items){
	$i++;
	$total += $it->{LoadPercentage} if defined $it->{LoadPercentage};
    }
    return $total / $i;
}


sub GetPhyMem {
    my $self = shift;
    my $total = 0;
    my $items = $self->{wmiobj}->ExecQuery("SELECT * FROM Win32_PhysicalMemory", 
					     "WQL",
					     wbemFlagReturnImmediately | wbemFlagForwardOnly);    
    foreach my $it (in $items){
	$total += $it->{Capacity} if defined $it->{Capacity};
    }
    return $total;
}

sub GetFreeMem {
    my $self = shift;
    my $amem = 0;
    my $items = $self->{wmiobj}->ExecQuery("SELECT * FROM Win32_PerfRawData_PerfOS_Memory", 
					     "WQL",
					     wbemFlagReturnImmediately | wbemFlagForwardOnly);    
    foreach my $it (in $items){
	$amem += $it->{AvailableMBytes} if defined $it->{AvailableMBytes};
    }
    return $amem;
}

sub GetOs {
    # if using win32 function, below code can get windows OS caption.

    # my $OS_string = Win32::GetOSDisplayName();
    my $self = shift;
    my $items = $self->{wmiobj}->ExecQuery("SELECT * FROM Win32_OperatingSystem", 
					     "WQL",
					     wbemFlagReturnImmediately | wbemFlagForwardOnly);
    my $oscap = "";
    foreach my $it (in $items){
	$oscap = $it->{Caption} if defined $it->{Caption};
    }
    return $oscap;
}

sub GetDiskUsage{
    my $self = shift;
    my $size = 0;
    my $fsize = 0;
    my $items = $self->{wmiobj}->ExecQuery("SELECT * FROM Win32_LogicalDisk", 
					     "WQL",
					     wbemFlagReturnImmediately | wbemFlagForwardOnly);    
    foreach my $it (in $items){
	$size += $it->{Size} if(defined $it->{Size});
	$fsize += $it->{FreeSpace} if(defined $it->{FreeSpace});
    }
    my $usage = sprintf("%.2f",($size - $fsize) / $size * 100);

    return $usage;
}
1;
