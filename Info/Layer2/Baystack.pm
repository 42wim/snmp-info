# SNMP::Info::Layer2::Baystack
# Eric Miller
# $Id$
#
# Copyright (c) 2004-6 Max Baker changes from version 0.8 and beyond.
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

package SNMP::Info::Layer2::Baystack;
$VERSION = '1.05';
use strict;

use Exporter;
use SNMP::Info::SONMP;
use SNMP::Info::NortelStack;
use SNMP::Info::RapidCity;
use SNMP::Info::LLDP;
use SNMP::Info::Layer3;

@SNMP::Info::Layer2::Baystack::ISA = qw/SNMP::Info::SONMP SNMP::Info::NortelStack
                                      SNMP::Info::RapidCity SNMP::Info::LLDP
                                      SNMP::Info::Layer3 Exporter/;
@SNMP::Info::Layer2::Baystack::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

%MIBS    = (
            %SNMP::Info::Layer3::MIBS,
            %SNMP::Info::LLDP::MIBS,
            %SNMP::Info::RapidCity::MIBS,
            %SNMP::Info::NortelStack::MIBS,
            %SNMP::Info::SONMP::MIBS,
           );

%GLOBALS = ( 
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::LLDP::GLOBALS,
            %SNMP::Info::RapidCity::GLOBALS,
            %SNMP::Info::NortelStack::GLOBALS,
            %SNMP::Info::SONMP::GLOBALS,
           );

%FUNCS   = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::LLDP::FUNCS,
            %SNMP::Info::RapidCity::FUNCS,
            %SNMP::Info::NortelStack::FUNCS,
            %SNMP::Info::SONMP::FUNCS,
            );

# 450's report full duplex as speed = 20mbps?!
$SNMP::Info::SPEED_MAP{20_000_000} = '10 Mbps';
$SNMP::Info::SPEED_MAP{200_000_000} = '100 Mbps';
$SNMP::Info::SPEED_MAP{2_000_000_000} = '1.0 Gbps';

%MUNGE   = (
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::LLDP::MUNGE,
            %SNMP::Info::RapidCity::MUNGE,
            %SNMP::Info::NortelStack::MUNGE,
            %SNMP::Info::SONMP::MUNGE,
            );

sub os {
    my $baystack = shift;
    my $descr = $baystack->description();
    my $model = $baystack->model();

    if ((defined $model and $model =~ /(470|460|BPS|5510|5520|5530)/) and (defined $descr and $descr =~ m/SW:v[3-5]/i)) {
       return 'boss';
    }
    return 'baystack';
}

sub os_bin {
    my $baystack = shift;
    my $descr = $baystack->description();
    return undef unless defined $descr;

    # 303 / 304
    if ($descr =~ m/Rev: \d+\.(\d+\.\d+\.\d+)-\d+\.\d+\.\d+\.\d+/){
        return $1;
    }

    # 450
    if ($descr =~ m/FW:V(\d+\.\d+)/){
        return $1;
    }

    if ($descr =~ m/FW:(\d+\.\d+\.\d+\.\d+)/i){
        return $1;
    }
    return undef;
}

sub vendor {
    return 'nortel';
}

sub model {
    my $baystack = shift;
    my $id = $baystack->id();
    return undef unless defined $id;
    my $model = &SNMP::translateObj($id);
    return $id unless defined $model;

    my $descr = $baystack->description();

    return '303' if (defined $descr and $descr =~ /\D303\D/);
    return '304' if (defined $descr and $descr =~ /\D304\D/);
    return 'BPS' if ($model =~ /BPS2000/i);
    return $2 if ($model =~ /(ES|ERS|BayStack|EthernetRoutingSwitch|EthernetSwitch)(\d+)/);
    
    return $model;
}

sub i_ignore {
    my $baystack = shift;
    my $i_type = $baystack->i_type();

    my %i_ignore;
    foreach my $if (keys %$i_type){
        my $type = $i_type->{$if};
        next unless defined $type;
        $i_ignore{$if}++ if $type =~ /(54|loopback|propvirtual|cpu)/i;
    }
    return \%i_ignore;
}

sub interfaces {
    my $baystack = shift;
    my $partial = shift;

    my $i_index = $baystack->i_index($partial) || {};
    my $index_factor = $baystack->index_factor();
    my $slot_offset = $baystack->slot_offset();
    
    my %if;
    foreach my $iid (keys %$i_index){
        my $index = $i_index->{$iid};
        next unless defined $index;
        # Ignore cascade ports
        next if $index > 513;

        my $port = ($index % $index_factor);
        my $slot = (int($index / $index_factor)) + $slot_offset;

        my $slotport = "$slot.$port";
        $if{$iid} = $slotport;
    }
    return \%if;
}

sub i_mac { 
    my $baystack = shift;
    my $partial = shift;

    my $i_mac = $baystack->orig_i_mac($partial) || {};

    my %i_mac;
    # Baystack 303's with a hw rev < 2.11.4.5 report the mac as all zeros
    foreach my $iid (keys %$i_mac){
        my $mac = $i_mac->{$iid};
        next unless defined $mac;
        next if $mac eq '00:00:00:00:00:00';
        $i_mac{$iid}=$mac;
    }
    return \%i_mac;
}

sub i_name {
    my $baystack = shift;
    my $partial = shift;

    my $i_index = $baystack->i_index($partial) || {};
    my $i_alias = $baystack->i_alias($partial) || {};
    my $i_name2  = $baystack->orig_i_name($partial) || {};

    my %i_name;
    foreach my $iid (keys %$i_name2){
        my $name = $i_name2->{$iid};
        my $alias = $i_alias->{$iid};
        $i_name{$iid} = (defined $alias and $alias !~ /^\s*$/) ?
                        $alias : 
                        $name;
    }

    return \%i_name;
}

sub index_factor {
    my $baystack   = shift;
    my $model   = $baystack->model();
    my $os      = $baystack->os();
    my $op_mode = $baystack->ns_op_mode();
    
    $op_mode = 'pure' unless defined $op_mode;

    my $index_factor = 32;
    $index_factor = 64 if ((defined $model and $model =~ /(470)/) or ($os eq 'boss') and ($op_mode eq 'pure'));
    
    return $index_factor;
}

#  Use SONMP and/or LLDP

sub hasCDP {
    my $baystack = shift;

    return $baystack->hasLLDP() || $baystack->SUPER::hasCDP();
}

sub c_ip {
    my $baystack = shift;
    my $partial = shift;

    my $cdp  = $baystack->SUPER::c_ip($partial) || {};
    my $lldp = $baystack->lldp_ip($partial) || {};

    my %c_ip;
    foreach my $iid (keys %$cdp){
        my $ip = $cdp->{$iid};
        next unless defined $ip;

        $c_ip{$iid} = $ip;
    }

    foreach my $iid (keys %$lldp){
        my $ip = $lldp->{$iid};
        next unless defined $ip;

        $c_ip{$iid} = $ip;
    }
    return \%c_ip;
}

sub c_if {
    my $baystack = shift;
    my $partial = shift;

    my $lldp = $baystack->lldp_if($partial) || {};;
    my $cdp  = $baystack->SUPER::c_if($partial) || {};
    
    my %c_if;
    foreach my $iid (keys %$cdp){
        my $if = $cdp->{$iid};
        next unless defined $if;

        $c_if{$iid} = $if;
    }

    foreach my $iid (keys %$lldp){
        my $if = $lldp->{$iid};
        next unless defined $if;

        $c_if{$iid} = $if;
    }
    return \%c_if;
}

sub c_port {
    my $baystack = shift;
    my $partial = shift;

    my $lldp = $baystack->lldp_port($partial) || {};
    my $cdp  = $baystack->SUPER::c_port($partial) || {};
    
    my %c_port;
    foreach my $iid (keys %$cdp){
        my $port = $cdp->{$iid};
        next unless defined $port;

        $c_port{$iid} = $port;
    }

    foreach my $iid (keys %$lldp){
        my $port = $lldp->{$iid};
        next unless defined $port;

        $c_port{$iid} = $port;
    }
    return \%c_port;
}

sub c_id {
    my $baystack = shift;
    my $partial = shift;

    my $lldp = $baystack->lldp_id($partial) || {};
    my $cdp  = $baystack->SUPER::c_id($partial) || {};

    my %c_id;
    foreach my $iid (keys %$cdp){
        my $id = $cdp->{$iid};
        next unless defined $id;

        $c_id{$iid} = $id;
    }

    foreach my $iid (keys %$lldp){
        my $id = $lldp->{$iid};
        next unless defined $id;

        $c_id{$iid} = $id;
    }
    return \%c_id;
}

sub c_platform {
    my $baystack = shift;
    my $partial = shift;

    my $lldp = $baystack->lldp_rem_sysdesc($partial) || {};
    my $cdp  = $baystack->SUPER::c_platform($partial) || {};

    my %c_platform;
    foreach my $iid (keys %$cdp){
        my $platform = $cdp->{$iid};
        next unless defined $platform;

        $c_platform{$iid} = $platform;
    }

    foreach my $iid (keys %$lldp){
        my $platform = $lldp->{$iid};
        next unless defined $platform;

        $c_platform{$iid} = $platform;
    }
    return \%c_platform;
}

1;

__END__

=head1 NAME

SNMP::Info::Layer2::Baystack - SNMP Interface to Nortel Ethernet (Baystack) Switches

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you.
 my $baystack = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
  or die "Can't connect to DestHost.\n";

 my $class = $baystack->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a Nortel 
Ethernet Switch (Baystack) through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

my $baystack = new SNMP::Info::Layer2::Baystack(...);

=head2 Inherited Classes

=over

=item SNMP::Info::SONMP

=item SNMP::Info::NortelStack

=item SNMP::Info::RapidCity

=item SNMP::Info::LLDP

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=back

=head2 Inherited MIBs

See L<SNMP::Info::SONMP/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::NortelStack/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::RapidCity/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::LLDP/"Required MIBs"> for its MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its MIB requirements.

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $baystack->vendor()

Returns 'nortel'

=item $baystack->model()

Cross references $baystack->id() to the SYNOPTICS-MIB and returns
the results.  303s and 304s have the same ID, so we have a hack
to return depending on which it is.

Returns BPS for Business Policy Switch

For BayStack, EthernetRoutingSwitch, or EthernetSwitch extracts and returns
the switch numeric designation.

=item $baystack->os()

Returns 'baystack' or 'boss' depending on software version.

=item $baystack->os_bin()

Returns the firmware version extracted from B<sysDescr>.

=back

=head2 Overrides

=over

=item  $baystack->index_factor()

Required by SNMP::Info::SONMP.  Number representing the number of ports
reserved per slot within the device MIB.

Index factor on the Baystack switches are determined by the formula: Index
Factor = 64 if (model = 470 or (os eq 'boss' and operating in pure mode))
or else Index factor = 32.

Returns either 32 or 64 based upon the formula.

=back

=head2 Global Methods imported from SNMP::Info::SONMP

See L<SNMP::Info::SONMP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::NortelStack

See L<SNMP::Info::NortelStack/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $baystack->interfaces()

Returns reference to the map between IID and physical Port.

  Slot and port numbers on the Baystack switches are determined by the formula:
  
  port = (Interface index % Index factor)
  slot = (int(Interface index / Index factor)) + Slot offset
 
  The physical port name is returned as slot.port.

=item $baystack->i_ignore()

Returns reference to hash of IIDs to ignore.

=item $baystack->i_mac()

Returns the B<ifPhysAddress> table entries. 

Removes all entries matching '00:00:00:00:00:00' -- Certain 
revisions of Baystack firmware report all zeros for each port mac.

=item $baystack->i_name()

Crosses ifName with ifAlias and returns the human set port name if exists.

=back

=head2 Topology information

Based upon the software version devices may support SynOptics Network
Management Protocol (SONMP) and Link Layer Discovery Protocol (LLDP). These
methods will query both and return the combination of all information. As a
result, there may be identical topology information returned from the two
protocols causing duplicate entries.  It is the calling program's
responsibility to identify any duplicate entries and de-duplicate if necessary.

=over

=item $baystack->hasCDP()

Returns true if the device is running either SONMP or LLDP.

=item $baystack->c_if()

Returns reference to hash.  Key: iid Value: local device port (interfaces)

=item $baystack->c_ip()

Returns reference to hash.  Key: iid Value: remote IPv4 address

If multiple entries exist with the same local port, c_if(), with the same IPv4
address, c_ip(), it may be a duplicate entry.

If multiple entries exist with the same local port, c_if(), with different IPv4
addresses, c_ip(), there is either a non-SONMP/LLDP device in between two or
more devices or multiple devices which are not directly connected.  

Use the data from the Layer2 Topology Table below to dig deeper.

=item $baystack->c_port()

Returns reference to hash. Key: iid Value: remote port (interfaces)

=item $baystack->c_id()

Returns reference to hash. Key: iid Value: string value used to identify the
chassis component associated with the remote system.

=item $baystack->c_platform()

Returns reference to hash.  Key: iid Value: Remote Device Type

=back

=head2 Table Methods imported from SNMP::Info::SONMP

See L<SNMP::Info::SONMP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::NortelStack

See L<SNMP::Info::NortelStack/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::RapidCity

See L<SNMP::Info::RapidCity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::LLDP

See documentation in L<SNMP::Info::LLDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut
