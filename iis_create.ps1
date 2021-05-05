#Environment setup
#--------------------------------------------------------------------
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()   #Session stopwatch
cd "C:\Users\Administrator\Desktop"                       #Set static working directory
$loip = (Get-NetIPAddress -InterfaceIndex 2).IPAddress    #Get executing machine IP
$logfile = "C:\users\Administrator\desktop\ilogger.log"   #Create and set log file name and location
$global:wrn_c = 0   #Create and set warning count to 0
$err = 0            #Create and set error flag to false
#----


#Event logging
#--------------------------------------------------------------------

#Main event logger 
function log($logstr) 
{
	$timestamp = (Get-Date -format hh:mm:ss-tt) + "|"
	$timestamp + " " + $logstr |Out-File -FilePath $logfile -Append
}	
#----

#Sub-event logger
function nlog($logstr)
{
    "             " + $logstr |Out-File -FilePath $logfile -Append
}
#----


#Build session result handler
#--------------------------------------------------------------------

#Add prop to sum file
function add_prop($iis_prop)
{
	 process {$_ |Out-File -FilePath $iis_sumfile -Append}
}
#----

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
#----

#Session end func
function ends
{
    log "--------------------------------"
    log "IIS management util: end."
    $stopwatch.Stop()
    nlog ('Session execution time: ' + $stopwatch.Elapsed.ToString('mm\:ss\:fff'))   
}	
#----


#Script functionality 
#--------------------------------------------------------------------

#Begin new session

Write-Output "-----------------------------------------------" |out-file -FilePath $logfile -Append
log "IIS management util: begin:`n"
#----


#Configuration & task files locator (task 0)

log '[Task 0]: Locating config and task_sel file(s)'

if((get-childitem "conf*" |measure-object).Count|tee-object -variable conf_count) 
{
	$conf_file=Get-ChildItem "conf*" |Select-Object -expandproperty name
	
    for($i=0; $i -lt $conf_count; $i++) 
	{
		nlog ("[Hit!] File found: " + '"' + $conf_file[$i] + '"')

        if($seed=(get-childitem -Path ('task_sel_' + $conf_file[$i]))) 
        {
            $task=Get-Content $seed
            nlog ('[Preconfiguration]: Will execute tasks ' + (Invoke-Expression $task) + ' for selected conf.' )
        }
        else
        {
            nlog '[Preconfiguration]: No task_sel file detected - executing all tasks for selected conf.'
        }
        
	}
}	
else
{
	log "Error: no config file detected!"
    $err = 1
}	
status $err
#----

#Begin running tasks


for($i=0; $i -lt $conf_count; $i++) 
{
	log ("Running tasks for " + '"' + $conf_file[$i] + '"')

    if($seed=(get-childitem -Path ('task_sel_' + $conf_file[$i]))) 
    { 
        $task=Invoke-Expression (Get-Content $seed)
        $task |ForEach-Object -Process {
                                           $task_sel= ('.\task'+$_+'.ps1'+' -conf $conf_file[$i]')
                                           Invoke-Expression $task_sel            
                                       }
    }
    else
    {
        nlog 'No task_sel file detected - executing all tasks for selected conf.'

        #Run full task list if no task_sel file detected

        #----

        #Conf file parser

        .\task1.ps1 -conf $conf_file[$i]

        #----

        #DNS zone and record configuration

        .\task2.ps1 -conf $conf_file[$i]

        #----

        #Web services configuration

        .\task3.ps1 -conf $conf_file[$i]

        #----

        #Site configuration

        .\task4.ps1 -conf $conf_file[$i]
 
        #----

        #Site revomal tool (triggered by task_sel only)

        # .\task5.ps1 -conf $conf_file[$i]

        #----

        #Distribute files in virtual dirs (triggered by task_sel or 'GET' and 'DELETE' methods declared in conf file)

        .\task6.ps1 -conf $conf_file[$i]

        #----

        #XML/JSON file generator (triggered by task_sel or when no files provided whilst 'GET' and 'DELETE' methods declared) 

        .\task7.ps1 -conf $conf_file[$i]

        #----

        #HTTPS configuration and certificate management (triggered by task_sel only)

        #.\task8.ps1 -conf $conf_file[$i]
        
    }
        
}

ends