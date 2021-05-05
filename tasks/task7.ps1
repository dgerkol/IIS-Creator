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

#XML/JSON file generator (triggered by preseed or when no files provided whilst 'GET' and 'DELETE' methods declared) 

log '[Task 7]: File generator:'
nlog 'Locating available schemas'

$conf_file= (Get-ChildItem "sum_$conf").Name

status $err 