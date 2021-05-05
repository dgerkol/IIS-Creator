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

#Add prop to sum file
function add_prop($iis_prop)
{
	 process {$_ |Out-File -FilePath $iis_sumfile -Append}
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

#Conf file parser

log '[Task 1]: Parsing config files:'

 
    #Creat config sum file
    $iis_sumfile = '\users\Administrator\desktop\sum_' + $conf
    nlog ("File: " + '"' + $conf + '"')
    #-----

  
    #Parse request methods 
    if(Get-Content -Path $conf |Select-String "method enum")
    {
        ((Get-Content -Path $conf |Select-String "method enum") -replace " ","" -replace "methodenum""", "" -split """""" -replace """","") |add_prop
    }
    else
    {
        log ('Warning: no methods declared in "' + $conf + '" - skipping config file.')
        $wrn_c++
        Remove-Item -Path $iis_sumfile
        continue
    }#-----   
    

    
    #Parse server hosts and ports
    if(Get-Content -Path $conf |Select-String "host enum")
    {
        $tmp=((Get-Content -Path $conf |Select-String "host enum") -replace " ","" -replace "hostenum""", "" -split """""" -replace """","")
        ($tmp  |select-string ":[0-9]{1,}") -replace ":"," " |add_prop
        $stmp= (($tmp  |select-string -NotMatch ".*:") -replace " " ,"")

        if($stmp)
        {
            for($j=0; $j -lt ($stmp |Measure-Object).Count; $j++)
            {
                log ("Warning: host """ + $stmp[$j] + '"' + " does not contain a specified port - binding port 80 to host.")
                $wrn_c++
                ($stmp[$j] + " 80") |add_prop
            }
            $host_count = (($tmp  |select-string ":[0-9]{1,}") -replace ":"," " |Measure-Object).Count + ($stmp |Measure-Object).Count |add_prop
        }
        else
        {
            $host_count = (($tmp  |select-string ":[0-9]{1,}") -replace ":"," " |Measure-Object).Count |add_prop
        }
    }
    else
    {
        log ('Warning: no hosts declared in "' + $conf + '" - skipping config file.')
        $wrn_c++
        Remove-Item -Path $iis_sumfile
        continue 
    }#-----
    

    
    #Parse virtual dirs
    if(Get-Content -Path $conf |Select-String "url enum")
    {
        ((Get-Content -Path $conf |Select-String "url enum") -replace " ","" -replace "urlenum""", "" -split """""" -replace """","") |add_prop
    }
    else
    {
        log ('Warning: no urls declared in "' + $conf + '" - skipping config file.')
        $wrn_c++
        Remove-Item -Path $iis_sumfile
        continue
    }#-----
    

    
    #Parse content types
    if(Get-Content $conf |Select-String "content-type")
    {
        ((Get-Content $conf |Select-String "content-type") -replace "(content-type (regex|enum))( )","" -split "/" -notmatch '^".*' -replace "\(.*","" -replace '".*',"") `
          |Sort-Object -Unique |ForEach-Object -Process {
                                                            ("type " + $_) |add_prop
                                                        }
    }
    else
    {
        log 'Warning: no content-types declared in config - omitting [Task 6] & [Task 7] from list (if existed)'
        $wrn_c++
        $task=($task |Select-String "[0-5]|[8-9]")
    }#-----
   

    nlog "Done."

status $err