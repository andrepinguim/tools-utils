# Send mail message
$SMTPServer = ""
$Port = "" # 587

$Username = ""
$Password = ConvertTo-SecureString "" -AsPlainText -Force
$Credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)

$From = "no-reply@example.com"
$To = "mail@example.com"
$Subject = "Teste de envio de e-mail"
$Body = "Este é um teste de envio de e-mail usando PowerShell"

Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -Credential $Credentials -Port $Port -UseSsl
