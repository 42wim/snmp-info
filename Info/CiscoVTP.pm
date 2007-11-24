# SNMP::Info::CiscoVTP
# Max Baker
#
# Copyright (c) 2004 Max Baker changes from version 0.8 and beyond.
#
# Copyright (c) 2003 Regents of the University of California
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

package SNMP::Info::CiscoVTP;
$VERSION = '1.05';
# $Id$

use strict;

use Exporter;
use SNMP::Info;
 
use vars qw/$VERSION %MIBS %FUNCS %GLOBALS %MUNGE/;
@SNMP::Info::CiscoVTP::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::CiscoVTP::EXPORT_OK = qw//;

%MIBS    = (
            'CISCO-VTP-MIB'                       => 'vtpVlanName',
            'CISCO-VLAN-MEMBERSHIP-MIB'           => 'vmMembershipEntry',
            'CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB' => 'cviRoutedVlanIfIndex',
           );

%GLOBALS = (
            'vtp_version'           => 'vtpVersion',
            'vtp_maxstore'          => 'vtpMaxVlanStorage',
            'vtp_notify'            => 'vtpNotificationsEnabled',
            'vtp_notify_create'     => 'vtpVlanCreatedNotifEnabled',
            'vtp_notify_delete'     => 'vtpVlanDeletedNotifEnabled',
            'vtp_trunk_set_serial'  => 'vlanTrunkPortSetSerialNo',
           );

%FUNCS   = (
            # CISCO-VTP-MIB::managementDomainTable
            'vtp_d_index'     => 'managementDomainIndex',
            'vtp_d_name'      => 'managementDomainName',
            'vtp_d_mode'      => 'managementDomainLocalMode',
            'vtp_d_rev'       => 'managementDomainConfigRevNumber',
            'vtp_d_updater'   => 'managementDomainLastUpdater',
            'vtp_d_last'      => 'managementDomainLastChange',
            'vtp_d_status'    => 'managementDomainRowStatus',
            'vtp_d_tftp'      => 'managementDomainTftpServer',
            'vtp_d_tftp_path' => 'managementDomainTftpPathname',
            'vtp_d_pruning'   => 'managementDomainPruningState',
            'vtp_d_ver'       => 'managementDomainVersionInUse',
            # CISCO-VTP-MIB::vtpVlanTable
            'v_state'    => 'vtpVlanState',
            'v_type'     => 'vtpVlanType',
            'v_name'     => 'vtpVlanName',
            'v_mtu'      => 'vtpVlanMtu',
            'v_said'     => 'vtpVlanDot10Said',
            'v_ring'     => 'vtpVlanRingNumber',
            'v_bridge'   => 'vtpVlanBridgeNumber',
            'v_stp'      => 'vtpVlanStpType',
            'v_parent'   => 'vtpVlanParentVlan',
            'v_trans1'   => 'vtpVlanTranslationalVlan1',
            'v_trans2'   => 'vtpVlanTranslationalVlan2',
            'v_btype'    => 'vtpVlanBridgeType',
            'v_hop_are'  => 'vtpVlanAreHopCount',
            'v_hop_ste'  => 'vtpVlanSteHopCount',
            'v_crf'      => 'vtpVlanIsCRFBackup',
            'v_type_ext' => 'vtpVlanTypeExt',
            'v_if'       => 'vtpVlanIfIndex',
            # CISCO-VLAN-MEMBERSHIP-MIB::vmMembershipTable
            'i_vlan_type' => 'vmVlanType',
            'i_vlan2'     => 'vmVlan',
            'i_vlan_stat' => 'vmPortStatus',
            'i_vlan_1'    => 'vmVlans',
            'i_vlan_2'    => 'vmVlans2k',
            'i_vlan_3'    => 'vmVlans3k',
            'i_vlan_4'    => 'vmVlans4k',
            # CISCO-VLAN-MEMBERSHIP-MIB::vmVoiceVlanTable
            'i_voice_vlan' => 'vmVoiceVlanId',
            # CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB
            'v_cvi_if'    => 'cviRoutedVlanIfIndex',
            # CISCO-VTP-MIB::vlanTrunkPortTable
            'vtp_trunk_mgmt_dom' => 'vlanTrunkPortManagementDomain',
            'vtp_trunk_encaps_t' => 'vlanTrunkPortEncapsulationType',
            'vtp_trunk_vlans'    => 'vlanTrunkPortVlansEnabled',
            'vtp_trunk_vlans_2k' => 'vlanTrunkPortVlansEnabled2k',
            'vtp_trunk_vlans_3k' => 'vlanTrunkPortVlansEnabled3k',
            'vtp_trunk_vlans_4k' => 'vlanTrunkPortVlansEnabled4k',
            'vtp_trunk_native'   => 'vlanTrunkPortNativeVlan',
            'i_pvid'             => 'vlanTrunkPortNativeVlan',
            'vtp_trunk_rstat'    => 'vlanTrunkPortRowStatus',
            'vtp_trunk_dyn'      => 'vlanTrunkPortDynamicState',
            'vtp_trunk_dyn_stat' => 'vlanTrunkPortDynamicStatus',
            'vtp_trunk_vtp'      => 'vlanTrunkPortVtpEnabled',
            'vtp_trunk_encaps'  => 'vlanTrunkPortEncapsulationOperType',
            # TODO Add these tables if someone wants them..
            # vtpEditControlTable
            # vtpVlanEditTable
            # vtpStatsTable
           );

%MUNGE   = (
           );

sub v_index {
    my $vtp = shift;
    my $partial = shift;

    my $v_name = $vtp->v_name($partial);
    my %v_index;
    foreach my $idx (keys %$v_name) {
        my ($mgmtdomain, $vlan) = split(/\./, $idx);
        $v_index{$idx} = $vlan;
    }
    return \%v_index;
}

sub i_vlan {
    my $vtp = shift;
    my $partial = shift;

    my $port_vlan = $vtp->vtp_trunk_native($partial) || {};
    my $i_vlan = $vtp->i_vlan2($partial) || {};
    my $trunk_dyn_stat = $vtp->vtp_trunk_dyn_stat($partial) || {};

    my %i_vlans;
    # Get access ports
    foreach my $port (keys %$i_vlan) {
        my $vlan = $i_vlan->{$port};
        next unless defined $vlan;
        
        $i_vlans{$port} = $vlan;
    }

    # Get trunk ports
    foreach my $port (keys %$port_vlan) {
        my $vlan = $port_vlan->{$port};
        next unless defined $vlan;
        my $stat = $trunk_dyn_stat->{$port};
        if ( defined $stat and $stat =~ /^trunking/ ) {
            $i_vlans{$port} = $vlan;
        }
    }

    # Check in CISCO-VLAN-IFTABLE-RELATION-MIB
    # Is this only for Aironet???  If so, it needs
    # to be removed from this class
    
    my $v_cvi_if = $vtp->v_cvi_if();
    if ( defined $v_cvi_if ) {

        # Translate vlan.physical_interface -> iid
        #       to iid -> vlan
        foreach my $i (keys %$v_cvi_if){
            my ($vlan,$phys) = split(/\./,$i);
            my $iid = $v_cvi_if->{$i};

            $i_vlans{$iid} = $vlan;
        }
    }

    return \%i_vlans;
}

sub i_vlan_membership {
    my $vtp = shift;
    my $partial = shift;

    my $ports_vlans    = $vtp->vtp_trunk_vlans($partial) || {};
    my $ports_vlans_2k = $vtp->vtp_trunk_vlans_2k($partial) || {};
    my $ports_vlans_3k = $vtp->vtp_trunk_vlans_3k($partial) || {};
    my $ports_vlans_4k = $vtp->vtp_trunk_vlans_4k($partial) || {};
    my $voice_vlans    = $vtp->i_voice_vlan($partial) || {};
    my $vtp_vlans      = $vtp->v_state();
    my $i_vlan         = $vtp->i_vlan2($partial) || {};
    my $trunk_dyn_stat = $vtp->vtp_trunk_dyn_stat($partial) || {};

    my $i_vlan_membership = {};

    # Get access ports
    foreach my $port (keys %$i_vlan) {
        my $vlan = $i_vlan->{$port};
        next unless defined $vlan;
        my $stat = $trunk_dyn_stat->{$port};
        if ( defined $stat and $stat =~ /notTrunking/ ) {
            push(@{$i_vlan_membership->{$port}}, $vlan);
        }
    }

    # Get special voice VLANs (0 and 4096)
    foreach my $port (keys %$voice_vlans) {
        my $vlan = $voice_vlans->{$port};
        next unless defined $vlan;
        # Going to assume we would catch regular VLANs with the other methods
        next unless ($vlan == 0 or $vlan == 4096);
            push(@{$i_vlan_membership->{$port}}, $vlan);
    }

    # Get trunk ports

    my %oper_vlans;
    foreach my $iid (keys %$vtp_vlans) {
        my $vlan = 0;
        my $vtp_dom =0;
        my $state = $vtp_vlans->{$iid};
        next unless defined $state;
        next if $state !~ /operational/;
        if ($iid =~ /(\d+)\.(\d+)/ ) {
            $vtp_dom = $1;
            $vlan    = $2;
        }
        $oper_vlans{$vlan}++;
    }

    foreach my $port (keys %$ports_vlans) {
        my $stat = $trunk_dyn_stat->{$port};
        if ( defined $stat and $stat =~ /^trunking/ ) {
            my $k = 0;
            foreach my $list ("$ports_vlans->{$port}", "$ports_vlans_2k->{$port}",
                          "$ports_vlans_3k->{$port}", "$ports_vlans_4k->{$port}") {
                my $vlanlist = [split(//, unpack("B*", $list))];
                my $offset = 1024 * $k;
                foreach my $vlan (keys %oper_vlans) {            
                    push(@{$i_vlan_membership->{$port}}, $vlan) if (@$vlanlist[$vlan]-$offset);
                }
                $k++;
            }
        }
    }

    return $i_vlan_membership;
}

sub set_i_pvid {
    my $vtp = shift;
    my ($vlan_id, $ifindex) = @_;

    return undef unless ( $vtp->validate_vlan_param ($vlan_id, $ifindex) );

    my $native_vlan = $vtp->vtp_trunk_native($ifindex);
    if (defined $native_vlan) {

        print "Changing native VLAN from $native_vlan->{$ifindex} to $vlan_id on IfIndex: $ifindex\n" if $vtp->debug();

        my $rv = $vtp->set_vtp_trunk_native($vlan_id, $ifindex);
        unless ($rv) {
            $vtp->error_throw("Unable to change native VLAN to $vlan_id on IfIndex: $ifindex");
            return undef;
        }
        return $rv;
    }
    $vtp->error_throw("Can't find ifIndex: $ifindex - Is it a trunk port?");
    return undef;
}

sub set_i_vlan {
    my $vtp = shift;
    my ($vlan_id, $ifindex) = @_;

    return undef unless ( $vtp->validate_vlan_param ($vlan_id, $ifindex) );

    my $i_vlan = $vtp->i_vlan2($ifindex);
    if (defined $i_vlan) {

        print "Changing VLAN from $i_vlan->{$ifindex} to $vlan_id on IfIndex: $ifindex\n" if $vtp->debug();

        my $rv = $vtp->set_i_vlan2($vlan_id, $ifindex);
        unless ($rv) {
            $vtp->error_throw("Unable to change VLAN to $vlan_id on IfIndex: $ifindex");
            return undef;
        }
        return $rv;
    }
    $vtp->error_throw("Can't find ifIndex: $ifindex - Is it an access port?");
    return undef;
}

sub set_add_i_vlan_tagged {
    my $vtp = shift;
    my ($vlan_id, $ifindex) = @_;

    return undef unless ( $vtp->validate_vlan_param ($vlan_id, $ifindex) );

    print "Adding VLAN: $vlan_id to ifIndex: $ifindex\n" if $vtp->debug();

    my $trunk_serial = $vtp->load_vtp_trunk_set_serial();
    my $trunk_members   = $vtp->vtp_trunk_vlans($ifindex);

    unless (defined $trunk_members) {
        $vtp->error_throw("Can't find ifIndex: $ifindex - Is it a trunk port?");
        return undef;
    }

    my @member_list = split(//, unpack("B*", $trunk_members->{$ifindex}));
    
    print "Original vlan list for ifIndex: $ifindex: @member_list \n" if $vtp->debug();
    $member_list[$vlan_id] = '1';
    print "Modified vlan list for ifIndex: $ifindex: @member_list \n" if $vtp->debug();
    my $new_list = pack("B*", join('', @member_list));
    #Add VLAN to member list
    my $list_rv = $vtp->set_vtp_trunk_vlans($new_list, $ifindex);
    unless ($list_rv) {
        $vtp->error_throw("Unable to add VLAN: $vlan_id to ifIndex: $ifindex member list");
        return undef;
    }
    #Make sure no other SNMP manager was making modifications at the same time.
    my $serial_rv = $vtp->set_vtp_trunk_set_serial($trunk_serial);
    unless ($serial_rv) {
        $vtp->error_throw("Unable to increment trunk set serial number - check configuration!");
        return undef;
    }
    return 1;
}

sub set_remove_i_vlan_tagged {
    my $vtp = shift;
    my ($vlan_id, $ifindex) = @_;

    return undef unless ( $vtp->validate_vlan_param ($vlan_id, $ifindex) );

    print "Removing VLAN: $vlan_id from ifIndex: $ifindex\n" if $vtp->debug();

    my $trunk_serial   = $vtp->load_vtp_trunk_set_serial();
    my $trunk_members  = $vtp->vtp_trunk_vlans($ifindex);

    unless (defined $trunk_members) {
        $vtp->error_throw("Can't find ifIndex: $ifindex - Is it a trunk port?");
        return undef;
    }

    my @member_list = split(//, unpack("B*", $trunk_members->{$ifindex}));
    
    print "Original vlan list for ifIndex: $ifindex: @member_list \n" if $vtp->debug();
    $member_list[$vlan_id] = '0';
    print "Modified vlan list for ifIndex: $ifindex: @member_list \n" if $vtp->debug();
    my $new_list = pack("B*", join('', @member_list));
    #Remove VLAN to member list
    my $list_rv = $vtp->set_vtp_trunk_vlans($new_list, $ifindex);
    unless ($list_rv) {
        $vtp->error_throw("Error: Unable to remove VLAN: $vlan_id from ifIndex: $ifindex member list");
        return undef;
    }
    #Make sure no other manager was making modifications at the same time.
    my $serial_rv = $vtp->set_vtp_trunk_set_serial($trunk_serial);
    unless ($serial_rv) {
        $vtp->error_throw("Error: Unable to increment trunk set serial number - check configuration!");
        return undef;
    }
    return 1;
}

#
# These are internal methods and are not documented.  Do not use directly. 
#
sub validate_vlan_param {
    my $vtp = shift;
    my ($vlan_id, $ifindex) = @_;

    # VID and ifIndex should both be numeric
    unless ( defined $vlan_id and defined $ifindex and $vlan_id =~ /^\d+$/ and $ifindex =~ /^\d+$/ ) {
        $vtp->error_throw("Invalid parameter");
        return undef;
    }
    
    # Check that ifIndex exists on device
    my $index = $vtp->interfaces($ifindex);

    unless ( exists $index->{$ifindex} ) {
        $vtp->error_throw("ifIndex $ifindex does not exist");
        return undef;
    }

    #Check that VLAN exists on device
    my $vtp_vlans   = $vtp->v_state();
    my $vlan_exists = 0;
    
    foreach my $iid (keys %$vtp_vlans) {
        my $vlan = 0;
        my $vtp_dom =0;
        my $state = $vtp_vlans->{$iid};
        next unless defined $state;
        next if $state !~ /operational/;
        if ($iid =~ /(\d+)\.(\d+)/ ) {
            $vtp_dom = $1;
            $vlan    = $2;
        }
        
        $vlan_exists = 1 if ( $vlan_id eq $vlan );
    }
    unless ( $vlan_exists ) {
        $vtp->error_throw("VLAN $vlan_id does not exist or is not operational");
        return undef;
    }

    return 1;
}

1;
__END__

=head1 NAME

SNMP::Info::CiscoVTP - SNMP Interface to Cisco's VLAN Management MIBs

=head1 AUTHOR

Max Baker

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $vtp = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $vtp->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::CiscoVTP is a subclass of SNMP::Info that provides 
information about a Cisco device's VLAN and VTP Domain memebership.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item CISCO-VTP-MIB

=item CISCO-VLAN-MEMBERSHIP-MIB

=item CISCO-VLAN-IFTABLE-RELATIONSHIP-MIB

=back

MIBs can be found at ftp://ftp.cisco.com/pub/mibs/v2/v2.tar.gz

=head1 GLOBALS

=over

=item $vtp->vtp_version()

(B<vtpVersion>)

=item $vtp->vtp_maxstore()

(B<vtpMaxVlanStorage>)

=item $vtp->vtp_notify()

(B<vtpNotificationsEnabled>)

=item $vtp->vtp_notify_create()

(B<vtpVlanCreatedNotifEnabled>)

=item $vtp->vtp_notify_delete()

(B<vtpVlanDeletedNotifEnabled>)

=item $vtp->vtp_trunk_set_serial()

(B<vlanTrunkPortSetSerialNo>)

=back

=head1 TABLE METHODS

Your device will only implement a subset of these methods.

=over

=item $vtp->i_vlan()

Returns a mapping between ifIndex and assigned VLAN ID for access ports and the
default VLAN ID for trunk ports.

=item $vtp->i_vlan_membership()

Returns reference to hash of arrays: key = ifIndex, value = array of VLAN IDs.
These are the VLANs which are members of enabled VLAN list for the port.

  Example:
  my $interfaces = $vtp->interfaces();
  my $vlans      = $vtp->i_vlan_membership();
  
  foreach my $iid (sort keys %$interfaces) {
    my $port = $interfaces->{$iid};
    my $vlan = join(',', sort(@{$vlans->{$iid}}));
    print "Port: $port VLAN: $vlan\n";
  }

=back

=head2 VLAN Table (B<CISCO-VTP-MIB::vtpVlanTable>)

See ftp://ftp.cisco.com/pub/mibs/supportlists/wsc5000/wsc5000-communityIndexing.html
for a good treaty of how to connect to the VLANs

=over

=item $vtp->v_index()

(B<vtpVlanIndex>)

=item $vtp->v_state()

(B<vtpVlanState>)

=item $vtp->v_type()

(B<vtpVlanType>)

=item $vtp->v_name()

(B<vtpVlanName>)

=item $vtp->v_mtu()

(B<vtpVlanMtu>)

=item $vtp->v_said()

(B<vtpVlanDot10Said>)

=item $vtp->v_ring()

(B<vtpVlanRingNumber>)

=item $vtp->v_bridge()

(B<vtpVlanBridgeNumber>)

=item $vtp->v_stp()

(B<vtpVlanStpType>)

=item $vtp->v_parent()

(B<vtpVlanParentVlan>)

=item $vtp->v_trans1()

(B<vtpVlanTranslationalVlan1>)

=item $vtp->v_trans2()

(B<vtpVlanTranslationalVlan2>)

=item $vtp->v_btype()

(B<vtpVlanBridgeType>)

=item $vtp->v_hop_are()

(B<vtpVlanAreHopCount>)

=item $vtp->v_hop_ste()

(B<vtpVlanSteHopCount>)

=item $vtp->v_crf()

(B<vtpVlanIsCRFBackup>)

=item $vtp->v_type_ext()

(B<vtpVlanTypeExt>)

=item $vtp->v_if()

(B<vtpVlanIfIndex>)

=back

=head2 VLAN Membership Table (B<CISCO-VLAN-MEMBERSHIP-MIB::vmMembershipTable>)

=over

=item $vtp->i_vlan_type()

Static, Dynamic, or multiVlan.  

(B<vmVlanType>)

=item $vtp->i_vlan2()

The VLAN that an access port is assigned to.

(B<vmVlan>)

=item $vtp->i_vlan_stat()

Inactive, active, shutdown.

(B<vmPortStatus>)

=item $vtp->i_vlan_1()

Each bit represents a VLAN.  This is 0 through 1023

(B<vmVlans>)

=item $vtp->i_vlan_2()

Each bit represents a VLAN.  This is 1024 through 2047

(B<vmVlans2k>)

=item $vtp->i_vlan_3()

Each bit represents a VLAN.  This is 2048 through 3071

(B<vmVlans3k>)

=item $vtp->i_vlan_4()

Each bit represents a VLAN.  This is 3072 through 4095

(B<vmVlans4k>)

=back

=head2 VLAN Membership Voice VLAN Table (B<CISCO-VLAN-MEMBERSHIP-MIB::vmVoiceVlanTable>)

=over

=item $vtp->i_voice_vlan() 

(B<vmVoiceVlanId>)

=back

=head2 Managment Domain Table (B<CISCO-VTP-MIB::managementDomainTable>)

=over

=item $vtp->vtp_d_index()

(B<managementDomainIndex>)

=item $vtp->vtp_d_name()

(B<managementDomainName>)

=item $vtp->vtp_d_mode()

(B<managementDomainLocalMode>)

=item $vtp->vtp_d_rev()

(B<managementDomainConfigRevNumber>)

=item $vtp->vtp_d_updater()

(B<managementDomainLastUpdater>)

=item $vtp->vtp_d_last()

(B<managementDomainLastChange>)

=item $vtp->vtp_d_status()

(B<managementDomainRowStatus>)

=item $vtp->vtp_d_tftp()

(B<managementDomainTftpServer>)

=item $vtp->vtp_d_tftp_path()

(B<managementDomainTftpPathname>)

=item $vtp->vtp_d_pruning()

(B<managementDomainPruningState>)

=item $vtp->vtp_d_ver()

(B<managementDomainVersionInUse>)

=back

=head2 VLAN Trunk Port Table (B<CISCO-VTP-MIB::vlanTrunkPortTable>)

=over

=item $vtp->vtp_trunk_mgmt_dom()

(B<vlanTrunkPortManagementDomain>)

=item $vtp->vtp_trunk_encaps_t()

(B<vlanTrunkPortEncapsulationType>)

=item $vtp->vtp_trunk_vlans()

(B<vlanTrunkPortVlansEnabled>)

=item $vtp->vtp_trunk_vlans_2k()

(B<vlanTrunkPortVlansEnabled2k>)

=item $vtp->vtp_trunk_vlans_3k()

(B<vlanTrunkPortVlansEnabled3k>)

=item $vtp->vtp_trunk_vlans_4k()

(B<vlanTrunkPortVlansEnabled4k>)

=item $vtp->vtp_trunk_native()

(B<vlanTrunkPortNativeVlan>)

=item $vtp->i_pvid()

(B<vlanTrunkPortNativeVlan>)

=item $vtp->vtp_trunk_rstat()

(B<vlanTrunkPortRowStatus>)

=item $vtp->vtp_trunk_dyn()

(B<vlanTrunkPortDynamicState>)

=item $vtp->vtp_trunk_dyn_stat()

(B<vlanTrunkPortDynamicStatus>)

=item $vtp->vtp_trunk_vtp()

(B<vlanTrunkPortVtpEnabled>)

=item $vtp->vtp_trunk_encaps()

(B<vlanTrunkPortEncapsulationOperType>)

=back

=head1 SET METHODS

These are methods that provide SNMP set functionality for overridden methods or
provide a simpler interface to complex set operations.  See
L<SNMP::Info/"SETTING DATA VIA SNMP"> for general information on set operations. 

=over

=item $vtp->set_i_vlan ( vlan, ifIndex )

Changes an access (untagged) port VLAN, must be supplied with the numeric
VLAN ID and port ifIndex.  This method should only be used on end station
(non-trunk) ports.

  Example:
  my %if_map = reverse %{$vtp->interfaces()};
  $vtp->set_i_vlan('2', $if_map{'FastEthernet0/1'}) 
    or die "Couldn't change port VLAN. ",$vtp->error(1);

=item $vtp->set_i_pvid ( pvid, ifIndex )

Sets port default VLAN, must be supplied with the numeric VLAN ID and
port ifIndex.  This method should only be used on trunk ports.

  Example:
  my %if_map = reverse %{$vtp->interfaces()};
  $vtp->set_i_pvid('2', $if_map{'FastEthernet0/1'}) 
    or die "Couldn't change port default VLAN. ",$vtp->error(1);

=item $vtp->set_add_i_vlan_tagged ( vlan, ifIndex )

Adds the VLAN to the enabled VLANs list of the port, must be supplied with the
numeric VLAN ID and port ifIndex.

  Example:
  my %if_map = reverse %{$vtp->interfaces()};
  $vtp->set_add_i_vlan_tagged('2', $if_map{'FastEthernet0/1'}) 
    or die "Couldn't add port to egress list. ",$vtp->error(1);

=item $vtp->set_remove_i_vlan_tagged ( vlan, ifIndex )

Removes the VLAN from the enabled VLANs list of the port, must be supplied
with the numeric VLAN ID and port ifIndex.

  Example:
  my %if_map = reverse %{$vtp->interfaces()};
  $vtp->set_remove_i_vlan_tagged('2', $if_map{'FastEthernet0/1'}) 
    or die "Couldn't add port to egress list. ",$vtp->error(1);

=cut
