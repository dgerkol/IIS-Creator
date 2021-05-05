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

#Site configuration

log '[Task 4]: IIS site configurator:'

$conf_file= (Get-ChildItem "sum_$conf").Name


    nlog ('Configuring sites of "' + (($conf_file) -replace "sum_","") + '" file:')
    $pdir= Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}"
    $pdir |ForEach-Object -Process {
                                       Set-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -name enabled -PSPath ("IIS:\Sites\" + $_) -Value true 
                                       if((Get-WebConfigurationProperty -Filter "/system.webServer/directoryBrowse" -name enabled -PSPath ("IIS:\Sites\" + $_)).Value)
                                       {
                                           nlog 'Enabled directory browsing with listing options: Time, Size, Extention, Date'
                                       }
                                       else
                                       {
                                           log 'Warning: failed configuring directory browsing for site'
                                           $wrn_c++
                                       }

                                       set-WebConfigurationProperty -Filter "/system.webServer/security/requestFiltering" -name allowDoubleEscaping -PSPath ("IIS:\Sites\" + $_) -Value true
                                       if((Get-WebConfigurationProperty -Filter "/system.webServer/security/requestFiltering" -name allowDoubleEscaping -PSPath ("IIS:\Sites\" + $_)).Value)
                                       {
                                       nlog "Enabled file double escaping"
                                       }
                                       else
                                       {
                                           log 'Warning: failed configuring file double escaping for site'
                                           $wrn_c++
                                       }

                                      # set-WebConfigurationProperty -Filter "/system.webServer/handlers" -name accessPolicy -PSPath ("IIS:\Sites\" + $_) -Value "Read,Write"
                                      # New-WebHandler -Name "General request handler" -Path '*' -Verb
                                      # New-WebHandler -Name "General reques" -Path '*' -Modules "RequestFilteringModule" -PSPath ("IIS:\Sites\" + $_) -ResourceType Either -RequiredAccess Read -Verb "GET"
                                      
                                       Restart-WebItem -PSPath ("IIS:\Sites\" + $_)
                                       if((Get-WebItemState -PSPath ("IIS:\Sites\" + $_)).Value -eq 'Started')
                                       {
                                           nlog ('Restarted site ' + $_ + '. Current status: Started')
                                       }
                                       else
                                       {
                                           $wrn_c++
                                           nlog ('Restarted site ' + $_ + '. Current status: Stopped')
                                           log 'Warning: failed restarting website!'
                                       }
                                       

                                   }
    nlog "Done."

status $err