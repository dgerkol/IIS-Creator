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

#Web services configuration

log '[Task 3]: IIS site creator:'

$conf_file= (Get-ChildItem "sum_$conf").Name
 
    nlog ('Creating IIS sites for "' + (($conf_file) -replace "sum_","") + '" file:')
    $pdir= Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}"
    $vdir= (Get-Content -Path $conf_file |Select-String "/") -replace "^/","" -replace "/","\"
    $pdir |ForEach-Object -Process {
                                      $sdir = $_
                                      New-Item -ItemType Directory -Path "C:\inetpub" -Name $_;
                                      New-Website -Name $_ -Port ($_ -replace ".* ","") -HostHeader ($_ -replace " [0-9]{1,4}","") -PhysicalPath ("C:\inetpub\" + $_)
                                    
                                      nlog ('Created site "' + ((Get-Website $_ |Select-Object -ExpandProperty name) -replace " [0-9]{1,4}","") + '" with id of '   `
                                            + (Get-Website $_ |Select-Object -ExpandProperty id) + ' at ' + (Get-Website $_ |Select-Object -ExpandProperty physicalpath) `
                                            + ' binding port ' + ($_ -replace ".* ",""))
                                      
                                      $vdir |ForEach-Object -Process {
                                                                         New-WebVirtualDirectory -Site $sdir -Name $_ -PhysicalPath ('C:\inetpub\' + $sdir + '\')
                                                                         nlog "Added new virtual directory $_"
                                                                     }

                                  }
    nlog "Done."

status $err
