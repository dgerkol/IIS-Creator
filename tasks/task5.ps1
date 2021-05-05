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

#Site revomal tool (triggered by preseed only)

log '[Task 5]: IIS site remover:'

$conf_file= (Get-ChildItem "sum_$conf").Name


 
    nlog ('Removing IIS sites for "' + (($conf_file) -replace "sum_","") + '" file:')
    $pdir= Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}"
   # $vdir= (Get-Content -Path $conf_file[$i] |Select-String "/") -replace "^/","" -replace "/","\"
    $pdir |ForEach-Object -Process {
                                      #New-Item -ItemType Directory -Path "C:\inetpub" -Name $_;
                                      #New-Website -Name $_ -Port ($_ -replace ".* ","") -HostHeader ($_ -replace " [0-9]{1,4}","") -PhysicalPath ("C:\inetpub\" + $_)
                                      $sdir = ($_ -replace " [0-9]{1,4}","")

                                      Remove-Website -Name $_
                                      if(Get-Website $_)
                                      {
                                          log ('Warning: unable to remove site: "' + $sdir + ' binding port ' + ($_ -replace ".* ",""))
                                          nlog 'Skipping item due to warnings'
                                          $wrn_c++
                                          return
                                      }
                                      else
                                      {
                                          nlog ('Removed site: "' + $sdir + ' binding port ' + ($_ -replace ".* ",""))
                                      }
                                     
                                      Remove-Item -Path ("C:\inetpub\" + $_) -Recurse
                                      if(Get-ChildItem $_)
                                      {
                                          log ('Warning: unable to remove physical directory: "' + ("C:\inetpub\" + $_) + '"')
                                          nlog 'Skipping item due to warnings'
                                          $wrn_c++ad
                                          return
                                      }  
                                      else
                                      {
                                          nlog ('Removed physical directory with its props: "' + ("C:\inetpub\" + $_) + '"')
                                      }

                                      if(Get-DnsServerZone -name $sdir)
                                      {
                                          Remove-DnsServerZone -Name $sdir -Force
                                          nlog ('Removed primary DNS zone with its records: "' + $sdir + '"')
                                      }
                                      else
                                      {
                                          nlog ('Unable to remove primary DNS zone "' + $sdir + '"; Zone probably already removed under current task or never existed.')
                                      }

                                  }
    
    Remove-Item -Path $conf_file
   
    nlog "Done."

status $err
