#
# Copyright (c) 2002, Regents of the University of California
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice,
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright notice,
#       this list of conditions and the following disclaimer in the documentation
#       and/or other materials provided with the distribution.
#     * Neither the name of the University of California, Santa Cruz nor the 
#       names of its contributors may be used to endorse or promote products 
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; 
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
# SNMP::Info::Layer2::Bay
# Max Baker <max@warped.org>

package SNMP::Info::Layer2::Bay;
$VERSION = 0.1;
use strict;

use Exporter;
use SNMP::Info::Layer2;

@SNMP::Info::Layer2::Bay::ISA = qw/SNMP::Info::Layer2 Exporter/;
@SNMP::Info::Layer2::Bay::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

# Set for No CDP
%GLOBALS = ( %SNMP::Info::Layer2::GLOBALS,
             'cdp_id'  => 's5EnMsTopIpAddr',
             'cdp_run' => 's5EnMsTopStatus',
           );

%FUNCS   = (%SNMP::Info::Layer2::FUNCS,
            'imac2'      => 'ifPhysAddress',
            # S5-ETH-MULTISEG-TOPOLOGY-MIB::s5EnMsTopNmmTable
            'bay_topo_slot'     => 's5EnMsTopNmmSlot',
            'bay_topo_port'     => 's5EnMsTopNmmPort',
            'bay_topo_ip'       => 's5EnMsTopNmmIpAddr',
            'bay_topo_seg'      => 's5EnMsTopNmmSegId',
            'bay_topo_mac'      => 's5EnMsTopNmmMacAddr',
            'bay_topo_platform' => 's5EnMsTopNmmChassisType',
            'bay_topo_localseg' => 's5EnMsTopNmmLocalSeg',
            );

%MIBS    = (
            %SNMP::Info::Layer2::MIBS,
            'SYNOPTICS-ROOT-MIB'           => 'synoptics',
            'S5-ETH-MULTISEG-TOPOLOGY-MIB' => 's5EnMsTop'
           );

delete $MIBS{'CISCO-CDP-MIB'};
# 450's report full duplex as speed = 20mbps?!
$SNMP::Info::SPEED_MAP{20_000_000} = '10 Mbps';
$SNMP::Info::SPEED_MAP{200_000_000} = '100 Mbps';

%MUNGE   = (%SNMP::Info::Layer2::MUNGE,
            'i_mac2' => \&SNMP::Info::munge_mac ,
            );

sub vendor {
    # or nortel, or synopsis?
    return 'bay';
}

sub i_ignore {
    my $bay = shift;
    my $descr = $bay->description();

    my $i_type = $bay->i_type();

    my %i_ignore;
    foreach my $if (keys %$i_type){
        my $type = $i_type->{$if};  
        $i_ignore{$if}++ if $type =~ /(loopback|propvirtual|cpu)/i;
    }

    return \%i_ignore;
}

sub interfaces {
    my $bay = shift;
    my $i_index = $bay->i_index();

    return $i_index;
}

sub i_mac { 
    my $bay = shift;
    my $i_mac = $bay->i_mac2();

    # Bay 303's with a hw rev < 2.11.4.5 report the mac as all zeros
    foreach my $iid (keys %$i_mac){
        my $mac = $i_mac->{$iid};
        delete $i_mac->{$iid} if $mac eq '00:00:00:00:00:00';
    }
    return $i_mac;
}


sub model {
    my $bay = shift;
    my $id = $bay->id();
    my $model = &SNMP::translateObj($id);
    $model =~ s/^sreg-//i;

    my $descr = $bay->description();

    return '303' if ($descr =~ /\D303\D/);
    return '304' if ($descr =~ /\D304\D/);
    return $model;
}

# Hack in some CDP type stuff

sub c_if {
    my $bay = shift;
    my $bay_topo_port = $bay->bay_topo_port();

    my %c_if;
    foreach my $entry (keys %$bay_topo_port){
        my $port = $bay_topo_port->{$entry};
        next if $port == 0;
        $c_if{"$port.1"} = $port;
    }
    return \%c_if;
}

sub c_ip {
    my $bay = shift;
    my $bay_topo_ip   = $bay->bay_topo_ip();
    my $bay_topo_port = $bay->bay_topo_port();
    my $ip = $bay->cdp_ip();
    
    # Count the number of devices seen on each port.
    #   more than one device seen means connected to a non-bay
    #   device, but other bay devices are squawking further away.
    my %ip_port;
    foreach my $entry (keys %$bay_topo_ip){
        my $port = $bay_topo_port->{$entry};
        next if $port == 0;
        my $ip   = $bay_topo_ip->{$entry};
        push(@{$ip_port{$port}},$ip);
    }

    my %c_ip;
    foreach my $port (keys %ip_port){
        my $ips = $ip_port{$port};
        if (scalar @$ips == 1) {
            $c_ip{"$port.1"} = $ips->[0];
        } else {
            $c_ip{"$port.1"} = $ips;
        }
    }

    return \%c_ip;
}

sub c_port {
    my $bay = shift;
    my $bay_topo_port = $bay->bay_topo_port();
    my $bay_topo_seg = $bay->bay_topo_seg();

    my %c_port;
    foreach my $entry (keys %$bay_topo_seg){
        my $port = $bay_topo_port->{$entry};
        next if $port == 0;

        # For fake remotes (multiple IPs for a c_ip), use first found
        next if defined $c_port{"$port.1"};

        my $seg  = $bay_topo_seg->{$entry};

        # Segment id is (256 * remote slot_num) + (remote_port)
        my $remote_port = $seg % 256;
    
        $c_port{"$port.1"} = $remote_port;
    }

    return \%c_port;
}

sub c_platform {
    my $bay = shift;
    my $bay_topo_port     = $bay->bay_topo_port();
    my $bay_topo_platform = $bay->bay_topo_platform();


    my %c_platform;
    foreach my $entry (keys %$bay_topo_platform){
        my $port = $bay_topo_port->{$entry};
        next if $port == 0;

        # For fake remotes (multiple IPs for a c_ip), use first found
        next if defined $c_platform{"$port.1"};

        my $platform  = $bay_topo_platform->{$entry};

        $c_platform{"$port.1"} = $platform;
    }

    return \%c_platform;
}


__END__

=head1 NAME

SNMP::Info::Layer2::Bay - SNMP Interface to old Bay Network Switches

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
Bay device through SNMP. 

Inherits from 

 SNMP::Info::Layer2

Required MIBs:

 SYNOPTICS-ROOT-MIB
 S5-ETH-MULTISEG-TOPOLOGY-MIB
 MIBS listed in SNMP::Info::Layer2

Bay MIBs can be found on the CD that came with your product.  

Or, if you still have a service contract they can be downloaded at
www.nortelnetworks.com

They have also been seen at : http://www.inotech.com/mibs/vendor/baynetworks/synoptics/synoptics.asp

Or http://www.oidview.com/mibs/detail.html under Synoptics.

You will need at least the two listed above, and probably a few more.  

=head1 AUTHOR

Max Baker (C<max@warped.org>)

=head1 SYNOPSIS

 my $bay = new SNMP::Info::Layer2::Bay(DestHost  => 'mybayswitch' , 
                              Community => 'public' ); 

=head1 CREATING AN OBJECT

=over

=item  new SNMP::Info::Layer2::Bay()

Arguments passed to new() are passed on to SNMP::Session::new()
    

    my $bay = new SNMP::Info::Layer2::Bay(
        DestHost => $host,
        Community => 'public',
        Version => 3,...
        ) 
    die "Couldn't connect.\n" unless defined $bay;

=item  $bay->session()

Sets or returns the SNMP::Session object

    # Get
    my $sess = $bay->session();

    # Set
    my $newsession = new SNMP::Session(...);
    $bay->session($newsession);

=back

=head1 GLOBALS

=over

=item $bay->vendor()

Returns 'bay' :)

=item $bay->model()

Cross references $bay->id() to the SYNOPTICS-MIB and returns
the results.  303s and 304s have the same ID, so we have a hack
to return depending on which it is. 

Removes sreg- from the model name

=item $bay->cdp_id()

Returns the IP that the device is sending out for its Nmm topology info.

(B<s5EnMsTopIpAddr>)

=item $bay->cdp_run()

Returns if the S5-ETH-MULTISEG-TOPOLOGY info is on for this device. 

(B<s5EnMsTopStatus>)

=back

=head1 TABLE ENTRIES

=head2 Overrides

=over

=item $bay->interfaces()

Returns reference to map of IIDs to physical ports. 

Currently simply returns the B<ifIndex>

=item $bay->i_ignore()

Returns reference to hash of IIDs to ignore.

Simply calls the SNMP::Info::Layer2::i_ignore() fn for this.

=item $bay->i_mac()

Returns the B<ifPhysAddress> table entries. 

Removes all entries matching '00:00:00:00:00:00' -- Certain 
older revisions of Bay 303 and 304 firmware report all zeros
for each port mac.

=back

=head2 Psuedo CDP information

All entries with port=0 are local and ignored.

=over

=item $bay->c_if()

Returns referenece to hash.  Key: port.1 Value: port (iid)

=item $bay->c_ip()

Returns referenece to hash.  Key: port.1 

The value of each hash entry can either be a scalar or an array.
A scalar value is most likely a direct neighbor to that port. 
It is possible that there is a non-bay device in between this device and the remote device.

An array value represents a list of seen devices.  The only time you will get an array
of nieghbors, is if there is a non-bay device in between two or more devices. 

Use the data from the Layer2 Topology Table below to dig deeper.

=item $bay->port()

Returns reference to hash. Key: port.1 Value: port

=item $bay->platform()

Returns reference to hash. Key: port.1 Value: Remote Device Type

=back

=head2 Layer2 Topology info (s5EnMsTopNmmTable)

=over

=item $bay->bay_topo_slot()

Returns reference to hash.  Key: Table entry, Value:slot number

(B<s5EnMsTopNmmSlot>)

=item $bay->bay_topo_port()

Returns reference to hash.  Key: Table entry, Value:Port Number (interface iid)

(B<s5EnMsTopNmmPort>)

=item $bay->bay_topo_ip()

Returns reference to hash.  Key: Table entry, Value:Remote IP address of entry

(B<s5EnMsTopNmmIpAddr>)

=item $bay->bay_topo_seg()

Returns reference to hash.  Key: Table entry, Value:Remote Segment ID

(B<s5EnMsTopNmmSegId>)

=item $bay->bay_topo_mac
(B<s5EnMsTopNmmMacAddr>)

Returns reference to hash.  Key: Table entry, Value:Remote MAC address

=item $bay->bay_topo_platform

Returns reference to hash.  Key: Table entry, Value:Remote Device Type

(B<s5EnMsTopNmmChassisType>)

=item $bay->bay_topo_localseg

Returns reference to hash.  Key: Table entry, Value:Boolean, if bay_topo_seg() is local

(B<s5EnMsTopNmmLocalSeg>)

=back

=cut
