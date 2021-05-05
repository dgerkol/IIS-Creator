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

#Distribute files in virtual dirs (triggered by preseed or 'GET' and 'DELETE' methods declared in conf file)

log '[Task 6]: File distributor:'

$conf_file= (Get-ChildItem "sum_$conf").Name


    nlog ('Distributing content files to sites of "' + (($conf_file) -replace "sum_","") + '" file:')
    Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}" |ForEach-Object `
                  -Process { 
                               $pdir =$_
                               (Get-Content -Path $conf_file |Select-String "type ") -replace "type ","" |ForEach-Object `
                                              -Process {
                                                           if(Get-ChildItem "*.$_")
                                                           {
                                                               Get-ChildItem "*.$_" |Copy-Item -Destination ("C:\inetpub\" + $pdir)
                                                           }
                                                           else
                                                           {
                                                               log ('Warning: "' + $conf_file + '" declared a content type of "' + $_ + '", but no such files were provided.')
                                                               $wrn_c++

                                                               if($_ -eq "xml" -or $_ -eq "json")
                                                               {
                                                                   log ('Adding [task 7] to "' + $conf_file + '" due to missing ' + $_ + ' files.')
                                                                   $task+=7
                                                                   $task=($task |Select-Object -Unique)
                                                               }
                                                           }

                                                       }
                           }
    nlog "Done."

status $err