# SNMP::Info::NortelStack
# Eric Miller
# $Id$
#
# Copyright (c) 2004-6 Eric Miller, Max Baker
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

package SNMP::Info::NortelStack;
$VERSION = '1.03'; 

use strict;

use Exporter;
use SNMP::Info;

@SNMP::Info::NortelStack::ISA = qw/SNMP::Info Exporter/;
@SNMP::Info::NortelStack::EXPORT_OK = qw//;

use vars qw/$VERSION $DEBUG %FUNCS %GLOBALS %MIBS %MUNGE $INIT/;

%MIBS    = (
            # S5-ROOT-MIB and S5-TCS-MIB required by the MIBs below
            'S5-AGENT-MIB'   => 's5AgMyGrpIndx',
            'S5-CHASSIS-MIB' => 's5ChasType',
            );

%GLOBALS = (
            # From S5-AGENT-MIB
            'ns_ag_ver'    => 's5AgInfoVer',
            'ns_op_mode'   => 's5AgSysCurrentOperationalMode',
            'ns_auto_pvid' => 's5AgSysAutoPvid',
            'tftp_host'    => 's5AgSysTftpServerAddress',
            'tftp_file'    => 's5AgSysBinaryConfigFilename',
            'tftp_action'  => 's5AgInfoFileAction',
            'tftp_result'  => 's5AgInfoFileStatus',
            'vlan'         => 's5AgSysManagementVlanId',
            # From S5-CHASSIS-MIB
            'serial'       => 's5ChasSerNum',
            'ns_cfg_chg'   => 's5ChasGblConfChngs',
            'ns_cfg_time'  => 's5ChasGblConfLstChng',
            );

%FUNCS  = (
            # From S5-AGENT-MIB::s5AgMyIfTable
            'i_cfg_file'       => 's5AgMyIfCfgFname',
            'i_cfg_host'       => 's5AgMyIfLdSvrAddr',
            # From S5-CHASSIS-MIB::s5ChasComTable
            'ns_com_grp_idx'   => 's5ChasComGrpIndx',
            'ns_com_ns_com_idx'=> 's5ChasComIndx',
            'ns_com_sub_idx'   => 's5ChasComSubIndx',
            'ns_com_type'      => 's5ChasComType',
            'ns_com_descr'     => 's5ChasComDescr',
            'ns_com_ver'       => 's5ChasComVer',
            'ns_com_serial'    => 's5ChasComSerNum',
            # From S5-CHASSIS-MIB::s5ChasStoreTable
            'ns_store_grp_idx' => 's5ChasStoreGrpIndx',
            'ns_store_ns_com_idx' => 's5ChasStoreComIndx',
            'ns_store_sub_idx' => 's5ChasStoreSubIndx',
            'ns_store_idx'     => 's5ChasStoreIndx',
            'ns_store_type'    => 's5ChasStoreType',
            'ns_store_size'    => 's5ChasStoreCurSize',
            'ns_store_ver'     => 's5ChasStoreCntntVer',
          );

%MUNGE = (

         );

sub os_ver {
    my $bayhub = shift;
    my $ver = $bayhub->ns_ag_ver();
    return undef unless defined $ver;

    if ($ver =~ m/(\d+\.\d+\.\d+\.\d+)/){
        return $1;
    }      
    if ($ver =~ m/V(\d+\.\d+\.\d+)/i){
        return $1;
    }  
   return undef;
}

sub os_bin {
    my $bayhub = shift;
    my $ver = $bayhub->ns_ag_ver();
    return undef unless defined $ver;

    if ($ver =~ m/(\d+\.\d+\.\d+\.\d+)/i){
        return $1;
    }     
    if ($ver =~ m/V(\d+\.\d+.\d+)/i){
        return $1;
    }
   return undef;
}

1;
__END__

=head1 NAME

SNMP::Info::NortelStack - Perl5 Interface to Nortel Stack information using SNMP

=head1 AUTHOR

Eric Miller

=head1 SYNOPSIS

 # Let SNMP::Info determine the correct subclass for you. 
 my $stack = new SNMP::Info(
                          AutoSpecify => 1,
                          Debug       => 1,
                          # These arguments are passed directly on to SNMP::Session
                          DestHost    => 'myswitch',
                          Community   => 'public',
                          Version     => 2
                        ) 
    or die "Can't connect to DestHost.\n";

 my $class = $stack->class();
 print "SNMP::Info determined this device to fall under subclass : $class\n";

=head1 DESCRIPTION

SNMP::Info::NortelStack is a subclass of SNMP::Info that provides an interface
to C<S5-AGENT-MIB> and C<S5-CHASSIS-MIB>.  These MIBs are used across the
Nortel Stackable Ethernet Switches (BayStack), as well as, older Nortel devices
such as the Centillion family of ATM switches.

Use or create in a subclass of SNMP::Info.  Do not use directly.

=head2 Inherited Classes

None.

=head2 Required MIBs

=over

=item S5-AGENT-MIB

=item S5-CHASSIS-MIB

=item S5-ROOT-MIB and S5-TCS-MIB are required by the other MIBs.

=back

=head1 GLOBAL METHODS

These are methods that return scalar values from SNMP

=over

=item $baystack->serial()

Returns (B<s5ChasSerNum>)

=item $stack->os_ver()

Returns the software version extracted from (B<s5AgInfoVer>)

=item $stack->os_bin()

Returns the firmware version extracted from (B<s5AgInfoVer>)

=item $stack->ns_ag_ver()

Returns the version of the agent in the form 'major.minor.maintenance[letters]'. 

(B<s5AgInfoVer>)

=item $stack->ns_op_mode()

Returns the stacking mode. 

(B<s5AgSysCurrentOperationalMode>)

=item $stack->tftp_action()

This object is used to download or upload a config file or an image file.

(B<s5AgInfoFileAction>)

=item $stack->tftp_result()

Returns the status of the latest action as shown by $stack->tftp_action().

(B<s5AgInfoFileStatus>)

=item $stack->ns_auto_pvid()

Returns the value indicating whether adding a port as a member of a VLAN
automatically results in its PVID being set to be the same as that VLAN ID.

(B<s5AgSysAutoPvid>)

=item $stack->tftp_file()

Name of the binary configuration file that will be downloaded/uploaded when
the $stack->tftp_action() object is set.

(B<s5AgSysBinaryConfigFilename>)

=item $stack->tftp_host()

The IP address of the TFTP server for all TFTP operations.

(B<s5AgSysTftpServerAddress>)

=item $stack->vlan()

Returns the VLAN ID of the system's management VLAN.

(B<s5AgSysManagementVlanId>)

=item $stack->ch_ser()

Returns the serial number of the chassis.

(B<s5ChasSerNum>)

=item $stack->ns_cfg_chg()

Returns the total number of configuration changes (other than attachment changes,
or physical additions or removals) in the chassis that have been detected since
cold/warm start.

(B<s5ChasGblConfChngs>)

=item $stack->ns_cfg_time()

Returns the value of sysUpTime when the last configuration change (other than
attachment changes, or physical additions or removals) in the chassis was
detected.

(B<s5ChasGblConfLstChng>)

=back

=head1 TABLE METHODS

These are methods that return tables of information in the form of a reference
to a hash.

=head2 Agent Interface Table (s5AgMyIfTable)

=over

=item $stack->i_cfg_file()

Returns reference to hash.  Key: Table entry, Value: Name of the file

(B<s5AgMyIfCfgFname>)

=item $stack->i_cfg_host()

Returns reference to hash.  Key: Table entry, Value: IP address of the load server

(B<s5AgMyIfLdSvrAddr>)

=back

=head2 Chassis Components Table (s5ChasComTable)

=over

=item $stack->ns_com_grp_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the chassis level
group which contains this component.

(B<s5ChasComGrpIndx>)

=item $stack->ns_com_ns_com_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the component in
the group.  For modules in the 'board' group, this is the slot number.

(B<s5ChasComIndx>)

=item $stack->ns_com_sub_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the sub-component
in the component.

(B<s5ChasComSubIndx>)

=item $stack->ns_com_type()

Returns reference to hash.  Key: Table entry, Value: Type

(B<s5ChasComType>)

=item $stack->ns_com_descr()

Returns reference to hash.  Key: Table entry, Value: Description

(B<s5ChasComDescr>)

=item $stack->ns_com_ver()

Returns reference to hash.  Key: Table entry, Value: Version

(B<s5ChasComVer>)

=item $stack->ns_com_serial()

Returns reference to hash.  Key: Table entry, Value: Serial Number

(B<s5ChasComSerNum>)

=back

=head2 Storage Area Table (s5ChasStoreTable)

=over

=item $stack->ns_store_grp_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the chassis level
group.

(B<s5ChasStoreGrpIndx>)

=item $stack->ns_store_ns_com_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the group.

(B<s5ChasStoreComIndx>)

=item $stack->ns_store_sub_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the sub-component.

(B<s5ChasStoreSubIndx>)

=item $stack->ns_store_idx()

Returns reference to hash.  Key: Table entry, Value: Index of the storage area.

(B<s5ChasStoreIndx>)

=item $stack->ns_store_type()

Returns reference to hash.  Key: Table entry, Value: Type

(B<s5ChasStoreType>)

=item $stack->ns_store_size()

Returns reference to hash.  Key: Table entry, Value: Size

(B<s5ChasStoreCurSize>)

=item $stack->ns_store_ver()

Returns reference to hash.  Key: Table entry, Value: Version

(B<s5ChasStoreCntntVer>)

=back

=cut
