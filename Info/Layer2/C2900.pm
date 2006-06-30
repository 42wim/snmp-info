# SNMP::Info::Layer2::C2900
# Max Baker
#
# Copyright (c) 2004 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2002,2003 Regents of the University of California
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

package SNMP::Info::Layer2::C2900;
$VERSION = '1.04';
# $Id$
use strict;

use Exporter;
use SNMP::Info::Layer2;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;

@SNMP::Info::Layer2::C2900::ISA = qw/SNMP::Info::Layer2 SNMP::Info::CiscoVTP 
                                     SNMP::Info::CDP SNMP::Info::CiscoStats Exporter/;
@SNMP::Info::Layer2::C2900::EXPORT_OK = qw//;

use vars qw/$VERSION %FUNCS %GLOBALS %MIBS %MUNGE $AUTOLOAD $INIT $DEBUG/;

# Set for No CDP
%GLOBALS = (
            %SNMP::Info::Layer2::GLOBALS,
            %SNMP::Info::CiscoVTP::GLOBALS,
            %SNMP::Info::CiscoStats::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
            );

%FUNCS   = (%SNMP::Info::Layer2::FUNCS,
            %SNMP::Info::CiscoVTP::FUNCS,
            %SNMP::Info::CiscoStats::FUNCS,
            %SNMP::Info::CDP::FUNCS,
            'i_name'               => 'ifAlias',
            # C2900PortEntry
            'c2900_p_index'        => 'c2900PortIfIndex',
            'c2900_p_duplex'       => 'c2900PortDuplexStatus',
            'c2900_p_duplex_admin' => 'c2900PortDuplexState',
            'c2900_p_speed_admin'  => 'c2900PortAdminSpeed',
           );

%MIBS    = ( %SNMP::Info::Layer2::MIBS,
             %SNMP::Info::CiscoVTP::MIBS,
             %SNMP::Info::CiscoStats::MIBS,
             %SNMP::Info::CDP::MIBS,
            'CISCO-C2900-MIB' => 'ciscoC2900MIB',
           );

%MUNGE   = (%SNMP::Info::Layer2::MUNGE,
            %SNMP::Info::CiscoVTP::MUNGE,
            %SNMP::Info::CDP::MUNGE,
            %SNMP::Info::CiscoStats::MUNGE,
           );

sub vendor {
    return 'cisco';
}

sub cisco_comm_indexing {
    1;
}

sub i_duplex {
    my $c2900 = shift;
    
    my $interfaces     = $c2900->interfaces();
    my $c2900_p_index  = $c2900->c2900_p_index();
    my $c2900_p_duplex = $c2900->c2900_p_duplex();
 

    my %reverse_2900 = reverse %$c2900_p_index;

    my %i_duplex;
    foreach my $if (keys %$interfaces){
        my $port_2900 = $reverse_2900{$if};
        next unless defined $port_2900;
        my $duplex = $c2900_p_duplex->{$port_2900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $i_duplex{$if}=$duplex; 
    }
    return \%i_duplex;
}

sub i_duplex_admin {
    my $c2900 = shift;
    
    my $interfaces     = $c2900->interfaces();
    my $c2900_p_index  = $c2900->c2900_p_index();
    my $c2900_p_admin = $c2900->c2900_p_duplex_admin();
 

    my %reverse_2900 = reverse %$c2900_p_index;

    my %i_duplex_admin;
    foreach my $if (keys %$interfaces){
        my $port_2900 = $reverse_2900{$if};
        next unless defined $port_2900;
        my $duplex = $c2900_p_admin->{$port_2900};
        next unless defined $duplex; 
    
        $duplex = 'half' if $duplex =~ /half/i;
        $duplex = 'full' if $duplex =~ /full/i;
        $duplex = 'auto' if $duplex =~ /auto/i;
        $i_duplex_admin{$if}=$duplex; 
    }
    return \%i_duplex_admin;
}

### we want to be able to set speed on 2900 class switches
###
### $info->set_i_speed_admin("100", ifIndex);
### speed choices are 'auto', '10', '100'
###
sub set_i_speed_admin {
    # map speeds to those the switch will understand
    my %speeds = qw/auto 1 10 10000000 100 100000000/;

    my $c2900 = shift;
    my ($speed, $iid) = @_;
    my $c2900_p_index  = $c2900->c2900_p_index();
    my %reverse_2900 = reverse %$c2900_p_index;

    $speed = lc($speed);

    return 0 unless defined $speeds{$speed};

    # account for weirdness of c2900 mib
    $iid = $reverse_2900{$iid};

    return $c2900->set_c2900_p_speed_admin($speeds{$speed}, $iid);
}

### we want to be able to set duplex on 2900 class switches
###
### $info->set_i_duplex_admin("half", ifIndex);
### duplex choices are 'auto', 'half', 'full'
###
sub set_i_duplex_admin {
    # map a textual duplex to an integer one the switch understands
    my %duplexes = qw/full 1 half 2 auto 3/;

    my $c2900 = shift;
    my ($duplex, $iid) = @_;
    my $c2900_p_index  = $c2900->c2900_p_index();
    my %reverse_2900 = reverse %$c2900_p_index;

    $duplex = lc($duplex);

    return 0 unless defined $duplexes{$duplex};

    # account for weirdness of c2900 mib
    $iid = $reverse_2900{$iid};

    return $c2900->set_c2900_p_duplex_admin($duplexes{$duplex}, $iid);
}

# Use i_descritption for port key, cuz i_name can be manually entered.
sub interfaces {
    my $c2900 = shift;
    my $interfaces = $c2900->i_index();
    my $i_descr    = $c2900->i_description(); 

    my %if;
    foreach my $iid (keys %$interfaces){
        my $port = $i_descr->{$iid};
        next unless defined $port;

        $port =~ s/\./\//g if( $port =~ /\d+\.\d+$/);
        $port =~ s/[^\d\/,()\w]+//gi;
    
        $if{$iid} = $port;
    }

    return \%if
}

1;
__END__

=head1 NAME

SNMP::Info::Layer2::C2900 - SNMP Interface to Cisco Catalyst 2900 Switches running IOS

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c2900 = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c2900->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Provides abstraction to the configuration information obtainable from a 
C2900 device through SNMP. 

For speed or debugging purposes you can call the subclass directly, but not after determining
a more specific class using the method above. 

 my $c2900 = new SNMP::Info::Layer2::C2900(...);

=head2 Inherited Classes

=over

=item SNMP::Info::Layer2

=item SNMP::Info::CiscoVTP

=back

=head2 Required MIBs

=over

=item CISCO-C2900-MIB

Part of the v2 MIBs from Cisco.

=item Inherited Classes' MIBs

See SNMP::Info::Layer2 for its own MIB requirements.

See SNMP::Info::CiscoVTP for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=head2 Overrides

=over

=item $c2900->vendor()

    Returns 'cisco' :)

=back

=head2 Globals imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=head1 TABLE ENTRIES

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $c2900->interfaces()

    Returns reference to the map between IID and physical Port.

    On the 2900 devices i_name isn't reliable, so we override to just the description.

    Next all dots are changed for forward slashes so that the physical port name 
    is the same as the broadcasted CDP port name. 
        (Ethernet0.1 -> Ethernet0/1)

    Also, any weird characters are removed, as I saw a few pop up.

=item $c2900->i_duplex()

    Returns reference to map of IIDs to current link duplex

    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex;

=item $c2900->i_duplex_admin()

    Returns reference to hash of IIDs to admin duplex setting
    
    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex_admin;

=item $c2900->set_i_speed_admin(speed, ifIndex)

    Sets port speed, must be supplied with speed and port ifIndex

    Speed choices are 'auto', '10', '100'

    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex_admin to
    utilize port ifIndex.

    Example:
    my %if_map = reverse %{$c2900->interfaces()};
    $c2900->set_i_speed_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port speed. ",$c2900->error(1);

=item $c2900->set_i_duplex_admin(duplex, ifIndex)

    Sets port duplex, must be supplied with duplex and port ifIndex

    Speed choices are 'auto', 'half', 'full'

    Crosses $c2900->c2900_p_index() with $c2900->c2900_p_duplex_admin to
    utilize port ifIndex.

    Example:
    my %if_map = reverse %{$c2900->interfaces()};
    $c2900->set_i_duplex_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port duplex. ",$c2900->error(1);

=back

=head2 C2900-MIB Port Entry Table 

=over

=item $c2900->c2900_p_index()

    Maps the Switch Port Table to the IID

    B<c2900PortIfIndex>

=item $c2900->c2900_p_duplex()

    Gives Port Duplex Info

    B<c2900PortDuplexStatus>

=item $c2900->c2900_p_duplex_admin()

    Gives admin setting for Duplex Info

    B<c2900PortDuplexState>


=item $c2900->c2900_p_speed_admin()

    Gives Admin speed of port 

    B<c2900PortAdminSpeed>

=back

=head2 Table Methods imported from SNMP::Info::Layer2

See documentation in SNMP::Info::Layer2 for details.

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in SNMP::Info::CiscoVTP for details.

=cut
