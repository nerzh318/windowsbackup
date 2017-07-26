$date = Get-Date
$fdate = $((Get-Date).ToString('yyyy-MM-dd'))


function Get-FTPFile ($Source,$Target,$UserName,$Password) 
{ 
 
# Create a FTPWebRequest object to handle the connection to the ftp server 
$ftprequest = [System.Net.FtpWebRequest]::create($Source) 
 
# set the request's network credentials for an authenticated connection 
$ftprequest.Credentials = New-Object System.Net.NetworkCredential($username,$password) 
 
$ftprequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile 
$ftprequest.UseBinary = $true 
$ftprequest.KeepAlive = $false 
$ftprequest.UsePassive = $true
# send the ftp request to the server 
$ftpresponse = $ftprequest.GetResponse() 
 
# get a download stream from the server response 
$responsestream = $ftpresponse.GetResponseStream() 
 
# create the target file on the local system and the download buffer 
$targetfile = New-Object IO.FileStream ($Target,[IO.FileMode]::Create) 
[byte[]]$readbuffer = New-Object byte[] 1024 
 
# loop through the download stream and send the data to the target file 
do{ 
    $readlength = $responsestream.Read($readbuffer,0,1024) 
    $targetfile.Write($readbuffer,0,$readlength) 
} 
while ($readlength -ne 0) 
 
$targetfile.close() 
} 
 
#localfolder
$sourceuri = "ftp://myserver/backup/net/net.zip" 
$targetpath = "Z:\localfolder\net\net" + $fdate +".zip"
$user = "username" 
$pass = "password" 

Get-FTPFile $sourceuri $targetpath $user $pass 

$limit = (Get-Date).AddDays(-15)
echo "Deleting older archive"
Get-ChildItem -Path Z:\localfolder\net\ -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force

echo "Sending mail"

$SMTPServer = "smtp.1und1.de"
$SMTPPort = "587"
$Username = "user@mydomain.com"
$Password = Get-Content "D:\Security\password.txt"
$to = "user@mydomain.com"

$style = "<style> 
			body {font-family: Century Gothic; font-size: 10pt;} 
			TABLE{border: 2px solid black; border-collapse: collapse;} 
			TH{border: 2px solid black; background: #4246CA; padding: 15px;} 
			TD{border: 2px solid black; padding: 15px;} 
		</style>"

Function Get-FormattedNumber($size)
{
  IF($size -ge 1GB)
   {
      "{0:n2}" -f  ($size / 1GB) + "GB"
   }
 ELSEIF($size -ge 1MB)
    {
      "{0:n2}" -f  ($size / 1MB) + "MB"
    }
 ELSE
    {
      "{0:n2}" -f  ($size / 1KB) + "KB"
    }
}
		
$i = (Get-CHildItem Z:\localfolder\net\ | Measure-Object).Count;
$arch = Get-ChildItem Z:\localfolder\net\ | where {! $_.PSIsContainer}| Select-Object Name, {Get-FormattedNumber($_.Length)}, Lastwritetime | ConvertTo-Html -head $style
$subject = "[Backup MYSERVER - name] backup type, File number: $i for localfolder"
$body = $arch


$message = New-Object System.Net.Mail.MailMessage
$message.subject = $subject
$message.body = $body
$message.IsBodyHTML = $true
$message.to.add($to)
$message.from = $username

$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $true
$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password);
$smtp.send($message)

echo "End of backup, check your mail"

