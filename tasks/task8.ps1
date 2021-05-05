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

#HTTPS configuration and certificate management (triggered by preseed only)

log '[Task 8]: SSL configurator:'

$conf_file= (Get-ChildItem "sum_$conf").Name




    nlog ('Self sgining certificates for sites of "' + (($conf_file) -replace "sum_","") + '" file:')
    (Get-Content -Path $conf_file |Select-String "[a-z] [1-9]{1,4}" |Tee-Object -Variable sdir) -replace " [0-9]{1,4}",""            `
      |ForEach-Object -Process {
                                                                                                    
                                   New-SelfSignedCertificate -DnsName $_ -KeyAlgorithm RSA -KeyLength 2048 -Type SSLServerAuthentication `
                                                             -KeyUsage DigitalSignature, DataEncipherment -KeyExportPolicy Exportable    `
                                                             -TextExtension "2.5.29.37={text}1.3.6.1.5.5.7.3.1"                          `
                                                             -Subject "CN=$_,OU=Team Alpha,O=MTZ,L=Gotham City,S=The Capitol,C=Mordor"   `
                                                             -Signer  "Cert:\LocalMachine\My\AD84B6120395E756C295C0047CBAEB9C6FDBEFC5"   `
                                                             -CertStoreLocation "Cert:\LocalMachine\MY"                                  `
                                                             -NotBefore (Get-Date).AddYears(-100) -NotAfter (Get-Date).AddYears(100)     `
                                                             |Select-Object -ExpandProperty Thumbprint |Tee-Object -Variable thumb
                                                                                                    
                                                             if($?)
                                                             {
                                                                 nlog ("Successfully self signed a certificate for $_ with thumbprint of $thumb") 
                                                             }
                                                             else
                                                             {
                                                                 nlog("Failed to self sign a certificate for $_ ")
                                                             }

                                   Export-Certificate        -cert (Get-ChildItem -Path "Cert:\LocalMachine\MY\$thumb")                  `
                                                             -FilePath ".\$_.cer" -Type CERT                                             
                                                              certutil.exe -encode "$_.cer" "$_.pem"

                                                              if($?)
                                                              {
                                                                  nlog ("Successfully exported certificate. Re-encoded certificate as base64 and saved as $_.pem.") 
                                                              }
                                                              elseif (Get-ChildItem "$_.cer")
                                                              {
                                                                  log("Warning: failed exporting certificate.")
                                                                  $wrn++
                                                              }
                                                              else
                                                              {
                                                                  log("Warning: certificate exported successfully, but failed re-encoding as base64 and create $_.pem.")
                                                                  nlog "Removing exported certificate file."
                                                                  Remove-Item -Path ".\$_.cer"
                                                                  $wrn++
                                                              }
                                   
                                   
                                   if(Get-WebBinding -Name "$sdir" -Port 80)
                                   {
                                       New-WebBinding -name "$sdir" -IPAddress "*" -Port 443 -Protocol https -HostHeader "$_" -SslFlags 1 
                                       Get-WebBinding -name "$sdir" -port 80 | Remove-WebBinding
                                   } 
                                   else
                                   {
                                       New-WebBinding -name "$sdir" -IPAddress "*" -port ("$sdir" -replace ".* ","") -Protocol https -HostHeader "$_" -SslFlags 1
                                       Get-WebBinding -name "$sdir" -port ("$sdir" -replace ".* ","") |Remove-WebBinding
                                   }                                                              
                               }

 
    nlog "Done."

status $err