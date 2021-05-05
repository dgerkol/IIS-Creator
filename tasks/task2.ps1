param([string]$conf)
cd "C:\Users\Administrator\Desktop" 
$loip = (Get-NetIPAddress -InterfaceIndex 2).IPAddress    #Get executing machine IP
$logfile = "C:\users\Administrator\desktop\ilogger.log"   #Create and set log file name and location
$global:wrn_c = 0   #Create and set warning count to 0
$err = 0            #Create and set error flag to false
#--------------------------------------------------------------------
#Event logger 
function log($logstr) 
{
	$timestamp = (Get-Date -format hh:mm:ss-tt) + "|"
	$timestamp + " " + $logstr |Out-File -FilePath $logfile -Append
}	

#No timestamp event logger
function nlog($logstr)
{
    "             " + $logstr |Out-File -FilePath $logfile -Append
}

#Task end status check
function status($sflag)
{
    if($sflag)
    {
        log 'Session is terminated due to an error, check log for details.'
        exit
    }
    elseif($wrn_c)
    {
        log ('Ended task with ' + $wrn_c + ' warning(s), check log for details.')
        $global:wrn_c = 0
    }
    else
    {
        log ('Task ended successfully!')
    }
}

#--------------------------------------------------------------------

#DNS zone and record configuration

$conf_file= (Get-ChildItem "sum_$conf").Name 

log '[Task 2]: DNS configurator:'


    nlog ('Creating zones for "' + (($conf_file) + '"' -replace "sum_","") + ' file:')
    $host_count= ((Get-Content -path $conf_file |Select-String -NotMatch "[a-z]") -replace " ", "")

    $tmp=((Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}") -replace " .*","")

    $tmp= $tmp |Select-Object -Unique
    $tmp |ForEach-Object -Process { 
                                      Add-DnsServerPrimaryZone -Name $_ -ZoneFile ($_ + '.dns'); 
                                      nlog ('Created new zone "' + $_ + '" at ' + $loip + " name server")
                                     
                                      Add-DnsServerResourceRecordA -Name $_ -ZoneName $_ -AllowUpdateAny -IPv4Address $loip -TimeToLive 01:00:00
                                      nlog "Added record of target host in newly created zone"
                                  }
    nlog 'Done.'
  
status $err