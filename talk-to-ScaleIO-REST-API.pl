# Name		: talk-to-ScaleIO-REST-API.pl
# Authors	: rudy.vanginneken@emc.com
# Version	: 1.0.0.0
# Created	: January 22, 2015
# Updated	: January 27, 2015
# Released	: January 27, 2015
# Purpose	: Script demonstrating how data can be retrieved from ScaleIO using the REST API.

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Cookies;
use JSON;
use Data::Dumper;

$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} 	= 0;

my $scaleio_gateway 					= "scaleio-gateway.emc.com";
my $scaleio_gateway_username			= "admin";
my $scaleio_gateway_password			= "changeme";
my $JSON 								= JSON->new->utf8;
my %sytems_lookup_table					= ();
my %protection_domains_lookup_table		= ();
my %scaleio_data_servers_lookup_table	= ();
my %storage_pools_lookup_table			= ();
my %volumes_lookup_table				= ();
my %vtrees_lookup_table					= ();
my %devices_lookup_table				= ();
my %fault_sets_lookup_table				= ();
my %scaleio_data_clients_lookup_table	= ();
my %scsi_initiators_lookup_table		= ();
my %users_lookup_table					= ();
my $token 								= "EMPTY";
my $system_name							= "";
my $protection_domain_name				= "";
my $storage_pool						= "";
my $storage_pool_id						= "";
my $volume								= "";
my $volume_id							= "";

# read the command line arguments
my $command_line1						= shift;
my $command_line2						= shift;
my $command_line3						= shift;
my $command_line4						= shift;
my $command_line5						= shift;
my $command_line6						= shift;

# make sure the command line arguments are sane
print "\n";
if (!$command_line1) {
	print "No options specified. Please use the following options:", "\n";
	print "   -s \<\"ScaleIO gateway\"\>", "\n";
	print "   -u \<\"user name\"\>", "\n";
	print "   -p password", "\n";
	print "or use -h for a list of available commands.", "\n\n";
	exit(1);
}

if ($command_line1 eq "-s") {
	if (!$command_line2) {
		print "You specified -s but did not provide the ScaleIO gateway IP address or hostname. Please specify the IP address or hostname of the ScaleIO gateway.", "\n";
		exit(1);
	} else {
		$scaleio_gateway = $command_line2;
		print "ScaleIO gateway is set to $scaleio_gateway", "\n";
	}
} else {
	if ($command_line1 eq "-h") {
		print "SCALEIO REST API SAMPLE CODE - HELP SECTION", "\n";
		print "\n";
		print "Valid options to run the program are:", "\n";
		print "   -s \<\"ScaleIO gateway\"\>, for example -s scaleio-gateway.emc.com", "\n";
		print "   -u \<\"user name\"\>, for example -u admin", "\n";
		print "   -p password, for example -p changeme", "\n";
		print "   -h will print this help option", "\n";
		print "\n";
		print "Note that these parameters should appear in the order -s -u -p or -h only.", "\n\n";
		print "Usage examples:", "\n";
		print "talk-to-ScaleIO-REST-API.pl -s scaleio-gateway.emc.com -u admin -p changeme", "\n";
		print "talk-to-ScaleIO-REST-API.pl -h", "\n\n";
		exit(1);
	} else {
		print "$command_line1 is a bad option.", "\n";
		print "Correct syntax is -s \<\"ScaleIO gateway\"\>.", "\n";
		print "For help use -h.", "\n";
		exit(1);
	}
}

if (!defined($command_line3)) {
	print "Please specify a user name.", "\n";
	exit(1);
} elsif ($command_line3 eq "-u") {
	if (!$command_line4) {
		print "You specified -u but did not provide a user name. Please specify the user name the script should use for authentication.", "\n";
		exit(1);
	}
	$scaleio_gateway_username = $command_line4;
	print "User name is set to $scaleio_gateway_username", "\n";
} else {
	print "Please specify a user name.", "\n";
	exit(1);
}

if (!defined($command_line5)) {
	print "Please specify a password.", "\n";
	exit(1);
} elsif ($command_line5 eq "-p") {
	if (!$command_line6) {
		print "You specified -p but did not provide a password. Please specify the password the script should use for authentication.", "\n";
		exit(1);
	}
	$scaleio_gateway_password = $command_line6;
	print "Password is set to $scaleio_gateway_password", "\n\n";
} else {
	print "Please specify a password.", "\n";
	exit(1);
}

sub connect_to_scaleio_gateway {
	my ($gateway, $username, $password)		= @_;
	my $uri 								= "https://" . $gateway . "/api/login";
	my $user_agent 							= LWP::UserAgent->new;
	my $request 							= new HTTP::Request('GET', $uri);
	
	$request->authorization_basic($username, $password);
	my $response = $user_agent->request($request);
	
	my $session_token = "EMPTY";
	if ($response->is_success) {
		$session_token = substr $response->content, 1, -1;
	}
	
	return $session_token;
}

sub disconnect_from_scaleio_gateway {
	my $gateway 	= @_;
	my $uri 		= "https://" . $gateway . "/api/logout";
	my $user_agent 	= LWP::UserAgent->new;
	my $request 	= new HTTP::Request("GET", $uri);
	
	$request->authorization_basic("whatever", $token);
	my $response = $user_agent->request($request);
	
	return $response->code;
}

$token = connect_to_scaleio_gateway($scaleio_gateway, $scaleio_gateway_username, $scaleio_gateway_password);

if ($token ne "EMPTY") {
	print "SUCCESSFULLY CONNECTED TO THE SCALEIO GATEWAY!", "\n\n";
} else {
	print "CANNOT CONNECT TO THE SCALEIO GATEWAY...ABORTING!", "\n";
	exit;
}

sub parse_scaleio_data_servers {
	my $JSON 						= JSON->new->utf8;
	my $json_data_structure 		= $JSON->decode(@_);
	my %scaleio_data_servers_hash	= ();
	my $indentation 				= "          ";
	my $i 							= 0;
	my $j 							= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		my $rm_cache_enabled 	= $result->{rmcacheEnabled}? "YES" : "NO";
		my $rm_cache_frozen 	= $result->{rmcacheFrozen}? "YES" : "NO";
		my $is_on_vmware 		= $result->{isOnVmWare}? "YES" : "NO";
		
		print $indentation . "=== SCALEIO DATA SERVER ==============================================================", "\n";
		print $indentation . "NAME                                         = " . $result->{name} . "\n" 						if (defined($result->{name}));
		print $indentation . "ID                                           = " . $result->{id} . "\n" 							if (defined($result->{id}));
		print $indentation . "PROTECTION DOMAIN ID                         = " . $result->{protectionDomainId} . "\n" 			if (defined($result->{protectionDomainId}));
		print $indentation . "PROTECTION DOMAIN NAME                       = " . $protection_domain_name, "\n";
		print $indentation . "STATE                                        = " . $result->{sdsState} . "\n" 					if (defined($result->{sdsState}));
		print $indentation . "MDM CONNECTION STATE                         = " . $result->{mdmConnectionState} . "\n" 			if (defined($result->{mdmConnectionState}));
		print $indentation . "MEMBERSHIP STATE                             = " . $result->{membershipState} . "\n" 				if (defined($result->{membershipState}));
		print $indentation . "PORT                                         = " . $result->{port} . "\n" 						if (defined($result->{port}));
		
		foreach my $ip_result (@{$json_data_structure->[$i-1]->{ipList}}){
 			$j++;
 			print $indentation . "IP ADDRESS                                   = " . $ip_result->{ip} . " (ROLE = " . $ip_result->{role} . ")", "\n";
		}
		if (!$j) { print $indentation . "NO DETAILED IP ADDRESS INFORMATION AVAILABLE!", "\n"; }
		
		print $indentation . "RM CACHE ENABLED                             = " . $rm_cache_enabled, "\n";
		print $indentation . "   SIZE (kb)                                 = " . $result->{rmcacheSizeInKb} . "\n" 				if (defined($result->{rmcacheSizeInKb}));
		print $indentation . "   MEMORY ALLOCATION STATE                   = " . $result->{rmcacheMemoryAllocationState} . "\n"	if (defined($result->{rmcacheMemoryAllocationState}));
		print $indentation . "   FROZEN                                    = " . $rm_cache_frozen, "\n";
		print $indentation . "NUMBER OF IO BUFFERS                         = " . $result->{numOfIoBuffers} . "\n" 				if (defined($result->{numOfIoBuffers}));
		print $indentation . "DRL MODE                                     = " . $result->{drlMode} . "\n" 						if (defined($result->{drlMode}));
		print $indentation . "FAULT SET ID                                 = " . $result->{faultSetId} . "\n" 					if (defined($result->{faultSetId}));
		print $indentation . "IS ON VMWARE                                 = " . $is_on_vmware, "\n";
		print $indentation . "======================================================================================", "\n\n";
		
		$scaleio_data_servers_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== SCALEIO DATA SERVER ==============================================================", "\n";
		print $indentation . "NO SCALEIO DATA SERVERS FOUND!", "\n";
		print $indentation . "======================================================================================", "\n\n";
	}
	
	return %scaleio_data_servers_hash;
}

sub parse_storage_pools {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %storage_pools_hash		= ();
	my $indentation 			= "          ";
	my $i 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		$storage_pool				= $result->{name};
		$storage_pool_id			= $result->{id};
		
		my $rebalance_enabled 		= ($result->{rebalanceEnabled})? "YES" : "NO";
		my $rebuild_enabled 		= ($result->{rebuildEnabled})? "YES" : "NO";
		my $zero_padding_enabled	= ($result->{zeroPaddingEnabled})? "YES" : "NO";
		my $use_rm_cache 			= ($result->{useRmcache})? "YES" : "NO";
		
		print $indentation . "=== STORAGE POOL =====================================================================", "\n";
		print $indentation . "NAME                                         = " . $result->{name} . "\n" 											if (defined($result->{name}));
		print $indentation . "ID                                           = " . $result->{id} . "\n" 												if (defined($result->{id}));
		print $indentation . "PROTECTION DOMAIN ID                         = " . $result->{protectionDomainId} . "\n" 								if (defined($result->{protectionDomainId}));
		print $indentation . "PROTECTION DOMAIN NAME                       = " . $protection_domain_name, "\n";
		print $indentation . "SPARE PERCENTAGE                             = " . $result->{sparePercentage} . "\n" 									if (defined($result->{sparePercentage}));
		print $indentation . "REBALANCE ENABLED                            = " . $rebalance_enabled, "\n";
		print $indentation . "   IO PRIORITY POLICY                        = " . $result->{rebalanceIoPriorityPolicy} . "\n" 						if (defined($result->{rebalanceIoPriorityPolicy}));
		print $indentation . "   BANDWIDTH LIMIT PER DEVICE (kbps)         = " . $result->{rebalanceIoPriorityBwLimitPerDeviceInKbps} . "\n" 		if (defined($result->{rebalanceIoPriorityBwLimitPerDeviceInKbps}));
		print $indentation . "   NUMBER OF CONCURRENT IO PER DEVICE        = " . $result->{rebalanceIoPriorityNumOfConcurrentIosPerDevice} . "\n" 	if (defined($result->{rebalanceIoPriorityNumOfConcurrentIosPerDevice}));
		print $indentation . "   APP IOPS PER DEVICE THRESHOLD             = " . $result->{rebalanceIoPriorityAppIopsPerDeviceThreshold} . "\n" 	if (defined($result->{rebalanceIoPriorityAppIopsPerDeviceThreshold}));
		print $indentation . "   APP BANDWIDTH PER DEVICE THRESHOLD (kbps) = " . $result->{rebalanceIoPriorityAppBwPerDeviceThresholdInKbps} . "\n"	if (defined($result->{rebalanceIoPriorityAppBwPerDeviceThresholdInKbps}));
		print $indentation . "   QUIET PERIOD (msec)                       = " . $result->{rebalanceIoPriorityQuietPeriodInMsec} . "\n" 			if (defined($result->{rebalanceIoPriorityQuietPeriodInMsec}));
		print $indentation . "REBUILD ENABLED                              = " . $rebuild_enabled, "\n";
		print $indentation . "   IO PRIORITY POLICY                        = " . $result->{rebuildIoPriorityPolicy} . "\n" 							if (defined($result->{rebuildIoPriorityPolicy}));
		print $indentation . "   BANDWIDTH LIMIT PER DEVICE (kbps)         = " . $result->{rebuildIoPriorityBwLimitPerDeviceInKbps} . "\n" 			if (defined($result->{rebuildIoPriorityBwLimitPerDeviceInKbps}));
		print $indentation . "   NUMBER OF CONCURRENT IO PER DEVICE        = " . $result->{rebuildIoPriorityNumOfConcurrentIosPerDevice} . "\n" 	if (defined($result->{rebuildIoPriorityNumOfConcurrentIosPerDevice}));
		print $indentation . "   APP IOPS PER DEVICE THRESHOLD             = " . $result->{rebuildIoPriorityAppIopsPerDeviceThreshold} . "\n" 		if (defined($result->{rebuildIoPriorityAppIopsPerDeviceThreshold}));
		print $indentation . "   APP BANDWIDTH PER DEVICE THRESHOLD (kbps) = " . $result->{rebuildIoPriorityAppBwPerDeviceThresholdInKbps} . "\n"	if (defined($result->{rebuildIoPriorityAppBwPerDeviceThresholdInKbps}));
		print $indentation . "   QUIET PERIOD (msec)                       = " . $result->{rebuildIoPriorityQuietPeriodInMsec} . "\n" 				if (defined($result->{rebuildIoPriorityQuietPeriodInMsec}));
		print $indentation . "NUMBER OF PARALLEL JOBS PER DEVICE           = " . $result->{numOfParallelRebuildRebalanceJobsPerDevice} . "\n" 		if (defined($result->{numOfParallelRebuildRebalanceJobsPerDevice}));
		print $indentation . "ZERO PADDING ENABLED                         = " . $zero_padding_enabled, "\n";
		print $indentation . "USE RM CACHE                                 = " . $use_rm_cache, "\n";
		print $indentation . "   WRITE HANDLING MODE                       = " . $result->{rmcacheWriteHandlingMode} . "\n" 						if (defined($result->{rmcacheWriteHandlingMode}));
		print $indentation . "======================================================================================", "\n\n";
		
		my $uri_storage_pools_relationships_devices = "/api/instances/StoragePool::" . $result->{id} . "/relationships/Device";
		my $json_storage_pools_relationships_devices = simple_get($scaleio_gateway, $uri_storage_pools_relationships_devices);
		%devices_lookup_table = parse_devices($JSON->encode($json_storage_pools_relationships_devices));
		
		my $uri_storage_pools_relationships_volumes = "/api/instances/StoragePool::" . $result->{id} . "/relationships/Volume";
		my $json_storage_pools_relationships_volumes = simple_get($scaleio_gateway, $uri_storage_pools_relationships_volumes);
		%volumes_lookup_table = parse_volumes($JSON->encode($json_storage_pools_relationships_volumes));
		
		$storage_pools_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== STORAGE POOL =====================================================================", "\n";
		print $indentation . "NO STORAGE POOLS FOUND!", "\n";
		print $indentation . "======================================================================================", "\n\n";
	}
	
	return %storage_pools_hash;
}

sub parse_volumes {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %volumes_hash 			= ();
	my $indentation 			= "               ";
	my $i 						= 0;
	my $j 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		$volume								= $result->{name};
		$volume_id							= $result->{id};
		
		my $is_obfuscated 					= ($result->{isObfuscated})? "YES" : "NO";
		my $use_rm_cache 					= ($result->{useRmcache})? "YES" : "NO";
		my $mapping_to_all_sdcs_enabled		= ($result->{mappingToAllSdcsEnabled})? "YES" : "NO";
		
		print $indentation . "=== VOLUME ======================================================================", "\n";
		print $indentation . "NAME                                    = " . $result->{name} . "\n" 									if (defined($result->{name}));
		print $indentation . "ID                                      = " . $result->{id} . "\n" 									if (defined($result->{id}));
		print $indentation . "SIZE (kb)                               = " . $result->{sizeInKb} . "\n" 								if (defined($result->{sizeInKb}));
		print $indentation . "VOLUME TYPE                             = " . $result->{volumeType} . "\n" 							if (defined($result->{volumeType}));
		print $indentation . "STORAGE POOL ID                         = " . $result->{storagePoolId} . "\n" 						if (defined($result->{storagePoolId}));
		print $indentation . "STORAGE POOL NAME                       = " . $storage_pool, "\n";
		print $indentation . "CREATION TIME                           = " . scalar localtime ($result->{creationTime}) . "\n" 		if (defined($result->{creationTime}));
		print $indentation . "ANCESTOR VOLUME ID                      = " . $result->{ancestorVolumeId} . "\n"						if (defined($result->{ancestorVolumeId}));
		print $indentation . "CONSISTENCY GROUP ID                    = " . $result->{consistencyGroupId} . "\n"					if (defined($result->{consistencyGroupId}));
		print $indentation . "IS OBFUSCATED                           = " . $is_obfuscated, "\n";
		print $indentation . "USE RM CACHE                            = " . $use_rm_cache, "\n";
		print $indentation . "MAPPED SCSI INITIATOR INFO              = " . $result->{mappedScsiInitiatorInfo} . "\n"				if (defined($result->{mappedScsiInitiatorInfo}));
		print $indentation . "MAPPING TO ALL SDCS ENABLED             = " . $mapping_to_all_sdcs_enabled, "\n";
		
		foreach my $mapped_sdc_info (@{$json_data_structure->[$i-1]->{mappedSdcInfo}}){
 			$j++;
 			print $indentation . "SDC IP ADDRESS                          = " . $mapped_sdc_info->{sdcIp} . "\n"					if (defined($mapped_sdc_info->{sdcIp}));
 			print $indentation . "LIMIT IOPS                              = " . $mapped_sdc_info->{limitIops} . "\n"				if (defined($mapped_sdc_info->{limitIops}));
 			print $indentation . "LIMIT BANDWIDTH (Mbps)                  = " . $mapped_sdc_info->{limitBwInMbps}. "\n"				if (defined($mapped_sdc_info->{limitBwInMbps}));
 			print $indentation . "SCSI ID                                 = " . $mapped_sdc_info->{sdcId} . "\n"					if (defined($mapped_sdc_info->{sdcId}));
		}
		if (!$j) { print $indentation . "NO DETAILED MAPPED SDC INFORMATION AVAILABLE!", "\n"; }
		
		print $indentation . "VTREE ID                                = " . $result->{vtreeId} . "\n" 								if (defined($result->{vtreeId}));
		print $indentation . "=================================================================================", "\n\n";
		
		my $uri_vtrees = "/api/types/VTree/instances";
		my $json_vtrees = simple_get($scaleio_gateway, $uri_vtrees);
		%vtrees_lookup_table = parse_vtrees($JSON->encode($json_vtrees));
		
		$volumes_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== VOLUME ======================================================================", "\n";
		print $indentation . "NO VOLUMES FOUND!", "\n";
		print $indentation . "=================================================================================", "\n\n";
	}
	
	return %volumes_hash;
}

sub parse_vtrees {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %vtrees_hash 			= ();
	my $indentation 			= "                    ";
	my $i 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		if ($storage_pool_id eq $result->{storagePoolId} && $volume_id eq $result->{baseVolumeId}) {
			$i++;
			
			print $indentation . "=== VTREE ==================================================================", "\n";
			print $indentation . "NAME                               = " . $result->{name} . "\n" 						if (defined($result->{name}));
			print $indentation . "ID                                 = " . $result->{id} . "\n" 						if (defined($result->{id}));
			print $indentation . "BASE VOLUME ID                     = " . $result->{baseVolumeId} . "\n" 				if (defined($result->{baseVolumeId}));
			print $indentation . "VOLUME NAME                        = " . $volume, "\n";
			print $indentation . "STORAGE POOL ID                    = " . $result->{storagePoolId} . "\n" 				if (defined($result->{storagePoolId}));
			print $indentation . "STORAGE POOL NAME                  = " . $storage_pool, "\n";
			print $indentation . "============================================================================", "\n\n";
			
			$vtrees_hash{$result->{id}} = $result->{name};
		}
	}
	
	if (!$i) {
		print $indentation . "=== VTREE ==================================================================", "\n";
		print $indentation . "NO VTREES FOUND!", "\n";
		print $indentation . "============================================================================", "\n\n";
	}
	
	return %vtrees_hash;
}

sub parse_devices {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %devices_hash 			= ();
	my $indentation 			= "               ";
	my $i 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		print $indentation . "=== DEVICE ======================================================================", "\n";
		print $indentation . "NAME                                    = " . $result->{name} . "\n" 											if (defined($result->{name}));
		print $indentation . "ID                                      = " . $result->{id} . "\n" 											if (defined($result->{id}));
		print $indentation . "STORAGE POOL ID                         = " . $result->{storagePoolId} . "\n" 								if (defined($result->{storagePoolId}));
		print $indentation . "STORAGE POOL NAME                       = " . $storage_pool, "\n";
		print $indentation . "MAXIMUM CAPACITY (kb)                   = " . $result->{maxCapacityInKb} . "\n" 								if (defined($result->{maxCapacityInKb}));
		print $indentation . "CAPACITY LIMIT (kb)                     = " . $result->{capacityLimitInKb} . "\n" 							if (defined($result->{capacityLimitInKb}));
		print $indentation . "DEVICE STATE                            = " . $result->{deviceState} . "\n" 									if (defined($result->{deviceState}));
		print $indentation . "ERROR STATE                             = " . $result->{errorState} . "\n" 									if (defined($result->{errorState}));
		print $indentation . "ORIGINAL PATH NAME                      = " . $result->{deviceOriginalPathName} . "\n" 						if (defined($result->{deviceOriginalPathName}));
		print $indentation . "CURRENT PATH NAME                       = " . $result->{deviceCurrentPathName} . "\n" 						if (defined($result->{deviceCurrentPathName}));
		print $indentation . "SCALEIO DATA SERVER                     = " . $result->{sdsId} . "\n" 										if (defined($result->{sdsId}));
		print $indentation . "SCALEIO DATA SERVER                     = " . $scaleio_data_servers_lookup_table{$result->{sdsId}} . "\n"		if (defined($scaleio_data_servers_lookup_table{$result->{sdsId}}));
		print $indentation . "=================================================================================", "\n\n";
		
		$devices_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== DEVICE ======================================================================", "\n";
		print $indentation . "NO DEVICES FOUND!", "\n";
		print $indentation . "=================================================================================", "\n\n";
	}
	
	return %devices_hash;
}

sub parse_fault_sets {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %fault_sets_hash 		= ();
	my $indentation 			= "          ";
	my $i 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		print $indentation . "=== FAULT SET ========================================================================", "\n";
		print $indentation . "NAME                                         = " . $result->{name} . "\n" 				if (defined($result->{name}));
		print $indentation . "ID                                           = " . $result->{id} . "\n" 					if (defined($result->{id}));
		print $indentation . "PROTECTION DOMAIN ID                         = " . $result->{protectionDomainId} . "\n" 	if (defined($result->{protectionDomainId}));
		print $indentation . "PROTECTION DOMAIN NAME                       = " . $protection_domain_name, "\n";
		print $indentation . "======================================================================================", "\n\n";
		
		$fault_sets_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== FAULT SET ========================================================================", "\n";
		print $indentation . "NO FAULT SETS FOUND!", "\n";
		print $indentation . "======================================================================================", "\n\n";
	}
	
	return %fault_sets_hash;
}

sub parse_protection_domain_statistics {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure 	= $JSON->decode(@_);
	my $indentation 			= "          ";
	
	print $indentation . "=== STATISTICS =======================================================================", "\n";
	print $indentation . "numOfSds                                     = " . $json_data_structure->{numOfSds}, "\n";
	print $indentation . "numOfStoragePools                            = " . $json_data_structure->{numOfStoragePools}, "\n";
	print $indentation . "numOfFaultSets                               = " . $json_data_structure->{numOfFaultSets}, "\n";
	print $indentation . "rmcacheSizeInKb                              = " . $json_data_structure->{rmcacheSizeInKb}, "\n";
	print $indentation . "capacityLimitInKb                            = " . $json_data_structure->{capacityLimitInKb}, "\n";
	print $indentation . "maxCapacityInKb                              = " . $json_data_structure->{maxCapacityInKb}, "\n";
	print $indentation . "capacityInUseInKb                            = " . $json_data_structure->{capacityInUseInKb}, "\n";
	print $indentation . "thickCapacityInUseInKb                       = " . $json_data_structure->{thickCapacityInUseInKb}, "\n";
	print $indentation . "thinCapacityInUseInKb                        = " . $json_data_structure->{thinCapacityInUseInKb}, "\n";
	print $indentation . "snapCapacityInUseInKb                        = " . $json_data_structure->{snapCapacityInUseInKb}, "\n";
	print $indentation . "snapCapacityInUseOccupiedInKb                = " . $json_data_structure->{snapCapacityInUseOccupiedInKb}, "\n";
	print $indentation . "unreachableUnusedCapacityInKb                = " . $json_data_structure->{unreachableUnusedCapacityInKb}, "\n";
	print $indentation . "protectedVacInKb                             = " . $json_data_structure->{protectedVacInKb}, "\n";
	print $indentation . "degradedHealthyVacInKb                       = " . $json_data_structure->{degradedHealthyVacInKb}, "\n";
	print $indentation . "degradedFailedVacInKb                        = " . $json_data_structure->{degradedFailedVacInKb}, "\n";
	print $indentation . "failedVacInKb                                = " . $json_data_structure->{failedVacInKb}, "\n";
	print $indentation . "inUseVacInKb                                 = " . $json_data_structure->{inUseVacInKb}, "\n";
	print $indentation . "activeMovingInFwdRebuildJobs                 = " . $json_data_structure->{activeMovingInFwdRebuildJobs}, "\n";
	print $indentation . "pendingMovingInFwdRebuildJobs                = " . $json_data_structure->{pendingMovingInFwdRebuildJobs}, "\n";
	print $indentation . "activeMovingOutFwdRebuildJobs                = " . $json_data_structure->{activeMovingOutFwdRebuildJobs}, "\n";
	print $indentation . "pendingMovingOutFwdRebuildJobs               = " . $json_data_structure->{pendingMovingOutFwdRebuildJobs}, "\n";
	print $indentation . "activeMovingInBckRebuildJobs                 = " . $json_data_structure->{activeMovingInBckRebuildJobs}, "\n";
	print $indentation . "pendingMovingInBckRebuildJobs                = " . $json_data_structure->{pendingMovingInBckRebuildJobs}, "\n";
	print $indentation . "activeMovingOutBckRebuildJobs                = " . $json_data_structure->{activeMovingOutBckRebuildJobs}, "\n";
	print $indentation . "pendingMovingOutBckRebuildJobs               = " . $json_data_structure->{pendingMovingOutBckRebuildJobs}, "\n";
	print $indentation . "activeMovingInRebalanceJobs                  = " . $json_data_structure->{activeMovingInRebalanceJobs}, "\n";
	print $indentation . "pendingMovingInRebalanceJobs                 = " . $json_data_structure->{pendingMovingInRebalanceJobs}, "\n";
	print $indentation . "activeMovingRebalanceJobs                    = " . $json_data_structure->{activeMovingRebalanceJobs}, "\n";
	print $indentation . "pendingMovingRebalanceJobs                   = " . $json_data_structure->{pendingMovingRebalanceJobs}, "\n";
	print $indentation . "primaryVacInKb                               = " . $json_data_structure->{primaryVacInKb}, "\n";
	print $indentation . "secondaryVacInKb                             = " . $json_data_structure->{secondaryVacInKb}, "\n";
	print $indentation . "primaryReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{primaryReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{primaryReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{primaryReadBwc}->{numOccured}, "\n";
	print $indentation . "primaryReadFromDevBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{primaryReadFromDevBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{primaryReadFromDevBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{primaryReadFromDevBwc}->{numOccured}, "\n";
	print $indentation . "primaryWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{primaryWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{primaryWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{primaryWriteBwc}->{numOccured}, "\n";
	print $indentation . "secondaryReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{secondaryReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{secondaryReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{secondaryReadBwc}->{numOccured}, "\n";
	print $indentation . "secondaryReadFromDevBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{secondaryReadFromDevBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{secondaryReadFromDevBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{secondaryReadFromDevBwc}->{numOccured}, "\n";
	print $indentation . "secondaryWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{secondaryWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{secondaryWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{secondaryWriteBwc}->{numOccured}, "\n";
	print $indentation . "totalReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{totalReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{totalReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{totalReadBwc}->{numOccured}, "\n";
	print $indentation . "totalWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{totalWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{totalWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{totalWriteBwc}->{numOccured}, "\n";
	print $indentation . "fwdRebuildReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{fwdRebuildReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{fwdRebuildReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{fwdRebuildReadBwc}->{numOccured}, "\n";
	print $indentation . "fwdRebuildWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{fwdRebuildWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{fwdRebuildWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{fwdRebuildWriteBwc}->{numOccured}, "\n";
	print $indentation . "bckRebuildReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{bckRebuildReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{bckRebuildReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{bckRebuildReadBwc}->{numOccured}, "\n";
	print $indentation . "bckRebuildWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{bckRebuildWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{bckRebuildWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{bckRebuildWriteBwc}->{numOccured}, "\n";
	print $indentation . "rebalanceReadBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{rebalanceReadBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{rebalanceReadBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{rebalanceReadBwc}->{numOccured}, "\n";
	print $indentation . "rebalanceWriteBwc", "\n";
	print $indentation . "   totalWeightInKb                           = " . $json_data_structure->{rebalanceWriteBwc}->{totalWeightInKb}, "\n";
	print $indentation . "   numSeconds                                = " . $json_data_structure->{rebalanceWriteBwc}->{numSeconds}, "\n";
	print $indentation . "   numOccured                                = " . $json_data_structure->{rebalanceWriteBwc}->{numOccured}, "\n";
	print $indentation . "spareCapacityInKb                            = " . $json_data_structure->{spareCapacityInKb}, "\n";
	print $indentation . "capacityAvailableForVolumeAllocationInKb     = " . $json_data_structure->{capacityAvailableForVolumeAllocationInKb}, "\n";
	print $indentation . "protectedCapacityInKb                        = " . $json_data_structure->{protectedCapacityInKb}, "\n";
	print $indentation . "degradedHealthyCapacityInKb                  = " . $json_data_structure->{degradedHealthyCapacityInKb}, "\n";
	print $indentation . "degradedFailedCapacityInKb                   = " . $json_data_structure->{degradedFailedCapacityInKb}, "\n";
	print $indentation . "failedCapacityInKb                           = " . $json_data_structure->{failedCapacityInKb}, "\n";
	print $indentation . "movingCapacityInKb                           = " . $json_data_structure->{movingCapacityInKb}, "\n";
	print $indentation . "activeMovingCapacityInKb                     = " . $json_data_structure->{activeMovingCapacityInKb}, "\n";
	print $indentation . "pendingMovingCapacityInKb                    = " . $json_data_structure->{pendingMovingCapacityInKb}, "\n";
	print $indentation . "fwdRebuildCapacityInKb                       = " . $json_data_structure->{fwdRebuildCapacityInKb}, "\n";
	print $indentation . "activeFwdRebuildCapacityInKb                 = " . $json_data_structure->{activeFwdRebuildCapacityInKb}, "\n";
	print $indentation . "pendingFwdRebuildCapacityInKb                = " . $json_data_structure->{pendingFwdRebuildCapacityInKb}, "\n";
	print $indentation . "bckRebuildCapacityInKb                       = " . $json_data_structure->{bckRebuildCapacityInKb}, "\n";
	print $indentation . "activeBckRebuildCapacityInKb                 = " . $json_data_structure->{activeBckRebuildCapacityInKb}, "\n";
	print $indentation . "pendingBckRebuildCapacityInKb                = " . $json_data_structure->{pendingBckRebuildCapacityInKb}, "\n";
	print $indentation . "rebalanceCapacityInKb                        = " . $json_data_structure->{rebalanceCapacityInKb}, "\n";
	print $indentation . "activeRebalanceCapacityInKb                  = " . $json_data_structure->{activeRebalanceCapacityInKb}, "\n";
	print $indentation . "pendingRebalanceCapacityInKb                 = " . $json_data_structure->{pendingRebalanceCapacityInKb}, "\n";
	print $indentation . "atRestCapacityInKb                           = " . $json_data_structure->{atRestCapacityInKb}, "\n";
	print $indentation . "numOfUnmappedVolumes                         = " . $json_data_structure->{numOfUnmappedVolumes}, "\n";
	print $indentation . "numOfMappedToAllVolumes                      = " . $json_data_structure->{numOfMappedToAllVolumes}, "\n";
	print $indentation . "numOfThickBaseVolumes                        = " . $json_data_structure->{numOfThickBaseVolumes}, "\n";
	print $indentation . "numOfThinBaseVolumes                         = " . $json_data_structure->{numOfThinBaseVolumes}, "\n";
	print $indentation . "numOfSnapshots                               = " . $json_data_structure->{numOfSnapshots}, "\n";
	print $indentation . "numOfVolumesInDeletion                       = " . $json_data_structure->{numOfVolumesInDeletion}, "\n";
	print $indentation . "======================================================================================", "\n\n";
}

sub parse_protection_domains {
	my $JSON 						= JSON->new->utf8;
	my $json_data_structure 		= $JSON->decode(@_);
	my %protection_domains_hash		= ();
	my $indentation 				= "     ";
	my $i 							= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		my $rebalance_network_throttling_enabled	= $result->{rebalanceNetworkThrottlingEnabled}? "YES" : "NO";
		my $rebuild_network_throttling_enabled		= $result->{rebuildNetworkThrottlingEnabled}? "YES" : "NO";
		my $overall_io_network_throttling_enabled	= $result->{overallIoNetworkThrottlingEnabled}? "YES" : "NO";
		
		$protection_domain_name 					= $result->{name};
		
		print $indentation . "=== PROTECTION DOMAIN =====================================================================", "\n";
		print $indentation . "NAME                                              = " . $result->{name} . "\n" 								if (defined($result->{name}));
		print $indentation . "ID                                                = " . $result->{id} . "\n" 									if (defined($result->{id}));
		print $indentation . "SYSTEM ID                                         = " . $result->{systemId} . "\n" 							if (defined($result->{systemId}));
		print $indentation . "PROTECTION DOMAIN STATE                           = " . $result->{protectionDomainState} . "\n" 				if (defined($result->{protectionDomainState}));
		print $indentation . "REBALANCE NETWORK THROTTLING ENABLED              = " . $rebalance_network_throttling_enabled, "\n";
		print $indentation . "   NETWORK THROTTLING (kbps)                      = " . $result->{rebalanceNetworkThrottlingInKbps} . "\n"	if (defined($result->{rebalanceNetworkThrottlingInKbps}));
		print $indentation . "REBUILD NETWORK THROTTLING ENABLED                = " . $rebuild_network_throttling_enabled, "\n";
		print $indentation . "   NETWORK THROTTLING (kbps)                      = " . $result->{rebuildNetworkThrottlingInKbps} . "\n"		if (defined($result->{rebuildNetworkThrottlingInKbps}));
		print $indentation . "OVERALL NETWORK THROTTLING ENABLED                = " . $overall_io_network_throttling_enabled, "\n";
		print $indentation . "   NETWORK THROTTLING (kbps)                      = " . $result->{overallIoNetworkThrottlingInKbps} . "\n"	if (defined($result->{overallIoNetworkThrottlingInKbps}));
		print $indentation . "===========================================================================================", "\n\n";
		
		$protection_domains_hash{$result->{id}} = $result->{name};
		
		my $uri_pd_relationships_scaleio_data_servers = "/api/instances/ProtectionDomain::" . $result->{id} . "/relationships/Sds";
		my $json_pd_relationships_scaleio_data_servers = simple_get($scaleio_gateway, $uri_pd_relationships_scaleio_data_servers);
		%scaleio_data_servers_lookup_table = parse_scaleio_data_servers($JSON->encode($json_pd_relationships_scaleio_data_servers));
		
		my $uri_pd_relationships_storage_pools = "/api/instances/ProtectionDomain::" . $result->{id} . "/relationships/StoragePool";
		my $json_pd_relationships_storage_pools = simple_get($scaleio_gateway, $uri_pd_relationships_storage_pools);
		%storage_pools_lookup_table = parse_storage_pools($JSON->encode($json_pd_relationships_storage_pools));
		
		my $uri_pd_relationships_fault_sets = "/api/instances/ProtectionDomain::" . $result->{id} . "/relationships/FaultSet";
		my $json_pd_relationships_fault_sets = simple_get($scaleio_gateway, $uri_pd_relationships_fault_sets);
		%fault_sets_lookup_table = parse_fault_sets($JSON->encode($json_pd_relationships_fault_sets));
		
		my $uri_pd_relationships_statistics = "/api/instances/ProtectionDomain::" . $result->{id} . "/relationships/Statistics";
		my $json_pd_relationships_statistics = simple_get($scaleio_gateway, $uri_pd_relationships_statistics);
		parse_protection_domain_statistics($JSON->encode($json_pd_relationships_statistics));
	}
	
	if (!$i) {
		print $indentation . "=== PROTECTION DOMAIN =====================================================================", "\n";
		print $indentation . "NO PROTECTION DOMAINS FOUND!", "\n";
		print $indentation . "===========================================================================================", "\n\n";
	}
	
	return %protection_domains_hash;
}

sub parse_scaleio_data_clients {
	my $JSON 						= JSON->new->utf8;
	my $json_data_structure			= $JSON->decode(@_);
	my %scaleio_data_clients_hash	= ();
	my $indentation 				= "     ";
	my $i 							= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		my $sdc_approved	= ($result->{sdcApproved})? "YES" : "NO";
		my $is_on_vmware 	= ($result->{onVmWare})? "YES" : "NO";
		
		print $indentation . "=== SCALEIO DATA CLIENT ===================================================================", "\n";
		print $indentation . "NAME                                              = " . $result->{name} . "\n" 						if (defined($result->{name}));
		print $indentation . "ID                                                = " . $result->{id} . "\n" 							if (defined($result->{id}));
		print $indentation . "SYSTEM ID                                         = " . $result->{systemId} . "\n" 					if (defined($result->{systemId}));
		print $indentation . "SYSTEM NAME                                       = " . $system_name, "\n";
		print $indentation . "IP ADDRESS                                        = " . $result->{sdcIp} . "\n" 						if (defined($result->{sdcIp}));
		print $indentation . "GUID                                              = " . $result->{sdcGuid} . "\n" 					if (defined($result->{sdcGuid}));
		print $indentation . "MDM CONNECTION STATE                              = " . $result->{mdmConnectionState} . "\n" 			if (defined($result->{mdmConnectionState}));
		print $indentation . "SDC APPROVED                                      = " . $sdc_approved, "\n";
		print $indentation . "ON VMWARE                                         = " . $is_on_vmware, "\n";
		print $indentation . "===========================================================================================", "\n\n";
		
		$scaleio_data_clients_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== SCALEIO DATA CLIENT ===================================================================", "\n";
		print $indentation . "NO SCALEIO DATA CLIENTS FOUND!", "\n";
		print $indentation . "===========================================================================================", "\n\n";
	}
	
	return %scaleio_data_clients_hash;
}

sub parse_scsi_initiators {
	my $JSON 						= JSON->new->utf8;
	my $json_data_structure			= $JSON->decode(@_);
	my %scsi_initiators_hash		= ();
	my $indentation 				= "     ";
	my $i 							= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		print $indentation . "=== SCSI INITIATOR ========================================================================", "\n";
		print $indentation . "NAME                                              = " . $result->{name} . "\n" 						if (defined($result->{name}));
		print $indentation . "ID                                                = " . $result->{id} . "\n" 							if (defined($result->{id}));
		print $indentation . "SYSTEM ID                                         = " . $result->{systemId} . "\n" 					if (defined($result->{systemId}));
		print $indentation . "SYSTEM NAME                                       = " . $system_name, "\n";
		print $indentation . "iSCSI QUALIFIED NAME                              = " . $result->{iqn} . "\n" 						if (defined($result->{iqn}));
		print $indentation . "===========================================================================================", "\n\n";
		
		$scsi_initiators_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== SCSI INITIATOR ========================================================================", "\n";
		print $indentation . "NO SCSI INITIATORS FOUND!", "\n";
		print $indentation . "===========================================================================================", "\n\n";
	}
	
	return %scsi_initiators_hash;
}

sub parse_users {
	my $JSON 						= JSON->new->utf8;
	my $json_data_structure			= $JSON->decode(@_);
	my %users_hash					= ();
	my $indentation 				= "     ";
	my $i 							= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		my $password_change_required = ($result->{passwordChangeRequired})? "YES" : "NO";
				
		print $indentation . "=== USER ==================================================================================", "\n";
		print $indentation . "NAME                                              = " . $result->{name} . "\n" 						if (defined($result->{name}));
		print $indentation . "ID                                                = " . $result->{id} . "\n" 							if (defined($result->{id}));
		print $indentation . "SYSTEM ID                                         = " . $result->{systemId} . "\n" 					if (defined($result->{systemId}));
		print $indentation . "SYSTEM NAME                                       = " . $system_name, "\n";
		print $indentation . "USER ROLE                                         = " . $result->{userRole} . "\n" 					if (defined($result->{userRole}));
		print $indentation . "PASSWORD CHANGE REQUIRED                          = " . $password_change_required, "\n";
		print $indentation . "===========================================================================================", "\n\n";
		
		$users_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print $indentation . "=== USER ==================================================================================", "\n";
		print $indentation . "NO USERS FOUND!", "\n";
		print $indentation . "===========================================================================================", "\n\n";
	}
	
	return %users_hash;
}

sub parse_systems {
	my $JSON 					= JSON->new->utf8;
	my $json_data_structure		= $JSON->decode(@_);
	my %systems_hash 			= ();
	my $i 						= 0;
	my $j 						= 0;
	
	foreach my $result (@{$json_data_structure}){
		$i++;
		
		my $enterprise_features_enabled 	= ($result->{enterpriseFeaturesEnabled})? "YES" : "NO";
		my $restricted_sdc_mode_enabled 	= ($result->{restrictedSdcModeEnabled})? "YES" : "NO";
		my $default_is_volume_obfuscated 	= ($result->{defaultIsVolumeObfuscated})? "YES" : "NO";
		
		$system_name 						= $result->{name};
		
		print "=== SYSTEM =====================================================================================", "\n";
		print "NAME                                                   = " . $result->{name} . "\n" 										if (defined($result->{name}));
		print "ID                                                     = " . $result->{id} . "\n" 										if (defined($result->{id}));
		print "INSTALLATION ID                                        = " . $result->{installId} . "\n" 								if (defined($result->{installId}));
		print "VERSION NAME                                           = " . $result->{systemVersionName} . "\n" 						if (defined($result->{systemVersionName}));
		print "ENTERPRISE FEATURES ENABLED                            = " . $enterprise_features_enabled, "\n";
		print "DAYS INSTALLED                                         = " . $result->{daysInstalled} . "\n" 							if (defined($result->{daysInstalled}));
		print "MAXIMUM CAPACITY (Gb)                                  = " . $result->{maxCapacityInGb} . "\n" 							if (defined($result->{maxCapacityInGb}));
		print "CAPACITY ALERT HIGH THRESHOLD (%)                      = " . $result->{capacityAlertHighThresholdPercent} . "\n" 		if (defined($result->{capacityAlertHighThresholdPercent}));
		print "CAPACITY ALERT CRITICAL THRESHOLD (%)                  = " . $result->{capacityAlertCriticalThresholdPercent} . "\n" 	if (defined($result->{capacityAlertCriticalThresholdPercent}));
		print "CAPACITY TIME LEFT (days)                              = " . $result->{capacityTimeLeftInDays} . "\n" 					if (defined($result->{capacityTimeLeftInDays}));
		print "MDM MODE                                               = " . $result->{mdmMode} . "\n" 									if (defined($result->{mdmMode}));
		print "MDM CLUSTER STATE                                      = " . $result->{mdmClusterState} . "\n" 							if (defined($result->{mdmClusterState}));
		print "MDM MANAGEMENT PORT                                    = " . $result->{mdmManagementPort} . "\n" 						if (defined($result->{mdmManagementPort}));
		
		foreach my $mdm_management_ip_list (@{$json_data_structure->[$i-1]->{mdmManagementIpList}}){
 			$j++;
 			print "MDM MANAGEMENT IP ADDRESS                              = " . $mdm_management_ip_list, "\n";
		}
		if (!$j) { print "NO DETAILED MDM MANAGEMENT IP ADDRESS INFORMATION AVAILABLE!", "\n"; }
		
		print "PRIMARY MDM PORT                                       = " . $result->{primaryMdmActorPort} . "\n" 						if (defined($result->{primaryMdmActorPort}));
		
		$j = 0;
		foreach my $primary_mdm_ip_list (@{$json_data_structure->[$i-1]->{primaryMdmActorIpList}}){
 			$j++;
 			print "PRIMARY MDM IP ADDRESS                                 = " . $primary_mdm_ip_list, "\n";
 		}
		if (!$j) { print "NO DETAILED PRIMARY MDM IP ADDRESS INFORMATION AVAILABLE!", "\n"; }
		
		print "SECONDARY MDM PORT                                     = " . $result->{secondaryMdmActorPort} . "\n" 					if (defined($result->{secondaryMdmActorPort}));
		
		$j = 0;
		foreach my $secondary_mdm_ip_list (@{$json_data_structure->[$i-1]->{secondaryMdmActorIpList}}){
 			$j++;
 			print "SECONDARY MDM IP ADDRESS                               = " . $secondary_mdm_ip_list, "\n";
		}
		if (!$j) { print "NO DETAILED SECONDARY MDM IP ADDRESS INFORMATION AVAILABLE!", "\n"; }
		
		print "TIE BREAKER MDM PORT                                   = " . $result->{tiebreakerMdmActorPort} . "\n" 					if (defined($result->{tiebreakerMdmActorPort}));
		
		$j = 0;
		foreach my $tie_breaker_mdm_ip_list (@{$json_data_structure->[$i-1]->{tiebreakerMdmIpList}}){
 			$j++;
 			print "TIE BREAKER MDM IP ADDRESS                             = " . $tie_breaker_mdm_ip_list, "\n";
		}
		if (!$j) { print "NO DETAILED TIE BREAKER MDM IP ADDRESS INFORMATION AVAILABLE!", "\n"; }
		
		print "RESTRICTED SDC MODE ENABLED                            = " . $restricted_sdc_mode_enabled, "\n";
		print "IS DEFAULT VOLUME OBFUSCATED                           = " . $default_is_volume_obfuscated, "\n";
		print "================================================================================================", "\n\n";
		
		my $uri_systems_relationships_protection_domains = "/api/instances/System::" . $result->{id} . "/relationships/ProtectionDomain";
		my $json_systems_relationships_protection_domains = simple_get($scaleio_gateway, $uri_systems_relationships_protection_domains);
		%protection_domains_lookup_table = parse_protection_domains($JSON->encode($json_systems_relationships_protection_domains));
		
		my $uri_systems_relationships_scsi_initiators = "/api/instances/System::" . $result->{id} . "/relationships/ScsiInitiator";
		my $json_systems_relationships_scsi_initiators = simple_get($scaleio_gateway, $uri_systems_relationships_scsi_initiators);
		%scsi_initiators_lookup_table = parse_scsi_initiators($JSON->encode($json_systems_relationships_scsi_initiators));
		
		my $uri_systems_relationships_users = "/api/instances/System::" . $result->{id} . "/relationships/User";
		my $json_systems_relationships_users = simple_get($scaleio_gateway, $uri_systems_relationships_users);
		%users_lookup_table = parse_users($JSON->encode($json_systems_relationships_users));
		
		my $uri_systems_relationships_scaleio_data_clients = "/api/instances/System::" . $result->{id} . "/relationships/Sdc";
		my $json_systems_relationships_scaleio_data_clients = simple_get($scaleio_gateway, $uri_systems_relationships_scaleio_data_clients);
		%scaleio_data_clients_lookup_table = parse_scaleio_data_clients($JSON->encode($json_systems_relationships_scaleio_data_clients));
		
		$systems_hash{$result->{id}} = $result->{name};
	}
	
	if (!$i) {
		print "=== SYSTEM =====================================================================================", "\n";
		print "NO SYSTEMS FOUND!", "\n";
		print "================================================================================================", "\n\n";
	}
	
	return %systems_hash;
}

sub simple_get {
	my ($gateway, $url) 	= @_;
	my $uri 				= "https://" . $gateway . $url;
	my $user_agent 			= LWP::UserAgent->new;
	
	my $request = new HTTP::Request("GET", $uri);
	$request->authorization_basic("whatever", $token);
	$request->header("content-type" => "application/json");
	
	my $response = $user_agent->request($request);
	
	my $json = JSON->new->utf8->allow_nonref;
	my $decoded_json = "EMPTY";
	
	if ($response->is_success) {
    	$decoded_json = $json->decode($response->content());
	}
	
	return $decoded_json;
}

my $json_systems = simple_get($scaleio_gateway, "/api/types/System/instances");
%sytems_lookup_table = parse_systems($JSON->encode($json_systems));

my $result = disconnect_from_scaleio_gateway($scaleio_gateway);
if ($result) { print "SUCCESSFULLY DISCONNECTED FROM THE SCALEIO GATEWAY!", "\n"; }
