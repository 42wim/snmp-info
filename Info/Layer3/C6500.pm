# SNMP::Info::Layer3::C6500
# Max Baker
#
# Copyright (c) 2003,2004,2005 Max Baker
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
#     * Neither the name of the Author, nor 
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

package SNMP::Info::Layer3::C6500;
# $Id$

use strict;

use Exporter;
use SNMP::Info::CiscoVTP;
use SNMP::Info::CiscoStack;
use SNMP::Info::CDP;
use SNMP::Info::CiscoStats;
use SNMP::Info::CiscoImage;
use SNMP::Info::CiscoPortSecurity;
use SNMP::Info::CiscoConfig;
use SNMP::Info::CiscoPower;
use SNMP::Info::Layer3;

use vars qw/$VERSION $DEBUG %GLOBALS %MIBS %FUNCS %MUNGE $INIT/ ;
$VERSION = '1.05';
@SNMP::Info::Layer3::C6500::ISA = qw/SNMP::Info::CiscoVTP SNMP::Info::CiscoStack 
                                    SNMP::Info::CDP SNMP::Info::CiscoStats 
                                    SNMP::Info::CiscoImage 
                                    SNMP::Info::CiscoPortSecurity
                                    SNMP::Info::CiscoConfig
                                    SNMP::Info::CiscoPower
                                    SNMP::Info::Layer3
                                    Exporter/;
@SNMP::Info::Layer3::C6500::EXPORT_OK = qw//;

%MIBS =    (
            %SNMP::Info::Layer3::MIBS,
            %SNMP::Info::CiscoPower::MIBS,
            %SNMP::Info::CiscoConfig::MIBS,
            %SNMP::Info::CiscoPortSecurity::MIBS,
            %SNMP::Info::CiscoImage::MIBS,
            %SNMP::Info::CiscoStats::MIBS,
            %SNMP::Info::CDP::MIBS,
            %SNMP::Info::CiscoStack::MIBS,
            %SNMP::Info::CiscoVTP::MIBS,
           );

%GLOBALS = (
            %SNMP::Info::Layer3::GLOBALS,
            %SNMP::Info::CiscoPower::GLOBALS,
            %SNMP::Info::CiscoConfig::GLOBALS,
            %SNMP::Info::CiscoPortSecurity::GLOBALS,
            %SNMP::Info::CiscoImage::GLOBALS,
            %SNMP::Info::CiscoStats::GLOBALS,
            %SNMP::Info::CDP::GLOBALS,
            %SNMP::Info::CiscoStack::GLOBALS,
            %SNMP::Info::CiscoVTP::GLOBALS,
           );

%FUNCS = (
            %SNMP::Info::Layer3::FUNCS,
            %SNMP::Info::CiscoPower::FUNCS,
            %SNMP::Info::CiscoConfig::FUNCS,
            %SNMP::Info::CiscoPortSecurity::FUNCS,
            %SNMP::Info::CiscoImage::FUNCS,
            %SNMP::Info::CiscoStats::FUNCS,
            %SNMP::Info::CDP::FUNCS,
            %SNMP::Info::CiscoStack::FUNCS,
            %SNMP::Info::CiscoVTP::FUNCS,
         );

%MUNGE = (
            %SNMP::Info::Layer3::MUNGE,
            %SNMP::Info::CiscoPower::MUNGE,
            %SNMP::Info::CiscoConfig::MUNGE,
            %SNMP::Info::CiscoPortSecurity::MUNGE,
            %SNMP::Info::CiscoImage::MUNGE,
            %SNMP::Info::CiscoStats::MUNGE,
            %SNMP::Info::CDP::MUNGE,
            %SNMP::Info::CiscoStack::MUNGE,
            %SNMP::Info::CiscoVTP::MUNGE,
         );

sub vendor {
    return 'cisco';
}

# There are some buggy 6509's out there.
sub bulkwalk_no { 1; }
sub cisco_comm_indexing { 1; }

#  Newer versions use the ETHERLIKE-MIB to report operational duplex.

sub i_duplex {
    my $c6500 = shift;
    my $partial = shift;

    my $el_duplex = $c6500->el_duplex($partial);

    # Newer software     
    if (defined $el_duplex and scalar(keys %$el_duplex)){
        my %i_duplex;
        foreach my $el_port (keys %$el_duplex){
            my $duplex = $el_duplex->{$el_port};
            next unless defined $duplex;

            $i_duplex{$el_port} = 'half' if $duplex =~ /half/i;
            $i_duplex{$el_port} = 'full' if $duplex =~ /full/i;
        }
        return \%i_duplex;
    }
    # Fall back to CiscoStack method
    else {
        return $c6500->SUPER::i_duplex($partial);
    }
}

# Newer software uses portDuplex as admin setting

sub i_duplex_admin {
    my $c6500 = shift;
    my $partial = shift;

    my $el_duplex = $c6500->el_duplex($partial);

    # Newer software     
    if (defined $el_duplex and scalar(keys %$el_duplex)){
        my $p_port   = $c6500->p_port()   || {};
        my $p_duplex = $c6500->p_duplex() || {};
        
        my $i_duplex_admin = {};
        foreach my $port (keys %$p_duplex) {
            my $iid = $p_port->{$port};
            next unless defined $iid;
            next if (defined $partial and $iid !~ /^$partial$/);
            
            $i_duplex_admin->{$iid} = $p_duplex->{$port};
        }
        return $i_duplex_admin;
    }
    # Fall back to CiscoStack method
    else {
        return $c6500->SUPER::i_duplex_admin($partial);
    }    
}

sub set_i_duplex_admin {
    # map a textual duplex to an integer one the switch understands
    my %duplexes = qw/half 1 full 2 auto 4/;

    my $c6500 = shift;
    my ($duplex, $iid) = @_;

    my $el_duplex = $c6500->el_duplex($iid);

    # Auto duplex only supported on newer software
    if (defined $el_duplex and scalar(keys %$el_duplex)){
        my $p_port  = $c6500->p_port() || {};
        my %reverse_p_port = reverse %$p_port;

       $duplex = lc($duplex);

       return 0 unless defined $duplexes{$duplex};

       $iid = $reverse_p_port{$iid};

       return $c6500->set_p_duplex($duplexes{$duplex}, $iid);
    }
    else {
        $c6500->SUPER::set_i_duplex_admin;
    }
}

1;
__END__

=head1 NAME

SNMP::Info::Layer3::C6500 - SNMP Interface to Cisco Catalyst 6500 Layer 2/3
Switches running IOS and/or CatOS

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $c6500 = new SNMP::Info(
                        AutoSpecify => 1,
                        Debug       => 1,
                        # These arguments are passed directly to SNMP::Session
                        DestHost    => 'myswitch',
                        Community   => 'public',
                        Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class      = $c6500->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

Abstraction subclass for Cisco Catalyst 6500 Layer 2/3 Switches.  

These devices run IOS but have some of the same charactersitics as the Catalyst
WS-C family (5xxx). For example, forwarding tables are held in VLANs, and
extended interface information is gleened from CISCO-SWITCH-MIB.

For speed or debugging purposes you can call the subclass directly, but not
after determining a more specific class using the method above. 

 my $c6500 = new SNMP::Info::Layer3::C6500(...);

=head2 Inherited Classes

=over

=item SNMP::Info::CiscoVTP

=item SNMP::Info::CiscoStack

=item SNMP::Info::CDP

=item SNMP::Info::CiscoStats

=item SNMP::Info::CiscoImage

=item SNMP::Info::CiscoPortSecurity

=item SNMP::Info::CiscoConfig

=item SNMP::Info::CiscoPower

=item SNMP::Info::Layer3

=back

=head2 Required MIBs

=over

=item Inherited Classes' MIBs

See L<SNMP::Info::CiscoVTP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStack/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CDP/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoStats/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoImage/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPortSecurity/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoConfig/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::CiscoPower/"Required MIBs"> for its own MIB requirements.

See L<SNMP::Info::Layer3/"Required MIBs"> for its own MIB requirements.

=back

=head1 GLOBALS

These are methods that return scalar value from SNMP

=over

=item $c6500->bulkwalk_no

Return C<1>.  There are some buggy 6509's out there, so bulkwalk
is turned off for this class.

=item $c6500->vendor()

    Returns 'cisco'

=back

=head2 Global Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"GLOBALS"> for details.

=head2 Global Methods imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"GLOBALS"> for details.

=head2 Globals imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"GLOBALS"> for details.

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Overrides

=over

=item $c6500->i_duplex()

Returns reference to hash of iid to current link duplex setting.

Newer software versions return duplex based upon the result of
$c6500->el_duplex().  Otherwise it uses the result of the call to
CiscoStack i_duplex().

See L<SNMP::Info::Etherlike> for el_duplex() method and
L<SNMP::Info::CiscoStack> for its i_duplex() method.

=item $c6500->i_duplex_admin()

Returns reference to hash of iid to administrative duplex setting.

Newer software versions return duplex based upon the result of
$c6500->p_duplex().  Otherwise it uses the result of the call to
CiscoStack i_duplex().

See L<SNMP::Info::CiscoStack> for its i_duplex() and p_duplex() methods.

=item $c6500->set_i_duplex_admin(duplex, ifIndex)

Sets port duplex, must be supplied with duplex and port ifIndex.

Speed choices are 'auto', 'half', 'full'.

Crosses $c6500->p_port() with $c6500->p_duplex() to utilize port ifIndex.

    Example:
    my %if_map = reverse %{$c6500->interfaces()};
    $c6500->set_i_duplex_admin('auto', $if_map{'FastEthernet0/1'}) 
        or die "Couldn't change port duplex. ",$c6500->error(1);

=back

=head2 Table Methods imported from SNMP::Info::CiscoVTP

See documentation in L<SNMP::Info::CiscoVTP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStack

See documentation in L<SNMP::Info::CiscoStack/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CDP

See documentation in L<SNMP::Info::CDP/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoStats

See documentation in L<SNMP::Info::CiscoStats/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoImage

See documentation in L<SNMP::Info::CiscoImage/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPortSecurity

See documentation in L<SNMP::Info::CiscoPortSecurity/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoConfig

See documentation in L<SNMP::Info::CiscoConfig/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::CiscoPower

See documentation in L<SNMP::Info::CiscoPower/"TABLE METHODS"> for details.

=head2 Table Methods imported from SNMP::Info::Layer3

See documentation in L<SNMP::Info::Layer3/"TABLE METHODS"> for details.

=cut

