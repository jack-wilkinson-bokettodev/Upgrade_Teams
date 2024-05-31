Clear-Host
$esc = [char]27
$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Appx' -Name 'AllowAllTrustedApps' -Value 1

$ProvisionedAppxPackages = Get-ProvisionedAppxPackage -Online
$ConsumerTeamsMachinePackages = @($ProvisionedAppxPackages | ? {$_.DisplayName -EQ 'MicrosoftTeams'})
$LegacyTeamsMachinePackages = @(Get-ChildItem -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\UserData\S-1-5-18\Products\' -Depth 0 -EA 'SilentlyContinue' | % {Get-ItemProperty -Path (Join-Path $_.PSPath '/InstallProperties') -EA 'SilentlyContinue'} | ? {$_.DisplayName -EQ 'Teams Machine-Wide Installer'})
$EdgeWebViewMachinePackages = @(Get-ChildItem -Path 'Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\' -Depth 0 -EA 'SilentlyContinue' | Get-ItemProperty -EA 'SilentlyContinue' | ? {$_.DisplayName -Match 'WebView2'})
$NewTeamsMachinePackages = @($ProvisionedAppxPackages | ? {$_.DisplayName -EQ 'MSTeams'})

if ($LegacyTeamsMachinePackages.Count -GT 0)
{
	$LegacyTeamsMachinePackages | Select -Exp 'UninstallString' | % {$_.Replace('/I{','/x --% {')} | % {"cmd.exe /c start /wait ${_} /qn"} | iex
}

if ($ConsumerTeamsMachinePackages.Count -GT 0)
{
	$ConsumerTeamsMachinePackages | Remove-ProvisionedAppxPackage -Online
}

if ($NewTeamsMachinePackages.Count -EQ 1)
{
	return 0
}

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {$TempRoot = (Join-Path ${env:WinDir} 'temp'); [Console]::WriteLine("$esc[96mRunning as Adminstrator$esc[0m")} else {$TempRoot = ${env:temp}; [Console]::WriteLine("$esc[91mNot $esc[96mRunning as Administrator")}
$TempDir = New-Item -ItemType 'Container' -Path $TempRoot -Name "{$([GUID]::NewGuid().GUID)}" -Force
[Console]::WriteLine("$esc[96mWorking from `"$esc[92m$($TempDir.FullName)$esc[96m`"$esc[0m")

Write-Verbose 'Downloading NuGet CLI'
$NuGetExe = Join-Path $TempDir '/NuGet.exe'
curl.exe -L --url "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -o "${NuGetExe}"

Write-Verbose 'Downloading Microsoft.UI.Xaml'
Start-Process -Wait -FilePath $NuGetExe -WorkingDirectory $TempDir -NoNewWindow -ArgumentList @('install','"Microsoft.UI.Xaml"','-DependencyVersion','"ignore"')
$UIXamlFolder = Resolve-Path -Path (Join-Path $TempDir './Microsoft.UI.Xaml.*.*.*')
if (!($UIXamlFolder)) {Write-Warning 'Unable to Download Microsoft.UI.Xaml';return $false}
$UIXamlAppXPath = Copy-Item -Path (Join-Path $UIXamlFolder '/tools/AppX/x64/Release/*.appx') -Destination $TempDir -PassThru

if ($EdgeWebViewMachinePackages.Count -EQ 0)
{
	Write-Verbose 'Downloading Edge WebView2'
	$EdgeWebViewPath = Join-Path $TempDir '/MicrosoftEdgeWebview2Setup.exe'
	curl.exe -L --url "https://go.microsoft.com/fwlink/p/?LinkId=2124703" -o "${EdgeWebViewPath}"

	Write-Verbose 'Installing Edge WebView2'
	$p = Start-Process -PassThru -FilePath $EdgeWebViewPath -ArgumentList '/silent','/install' -Verb RunAs
	$p.WaitForExit()
}

Write-Verbose 'Downloading VCLibs'
$VCLibsPath = Join-Path $TempDir '/Microsoft.VCLibs.x64.14.00.Desktop.appx'
curl.exe -L --url "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx" -o "${VCLibsPath}"

Write-Verbose 'Downloading Desktop App Installer'
$WinGetPath = Join-Path $TempDir '/WinGet.appx'
curl.exe -L --url "https://aka.ms/getwinget" -o "${WinGetPath}"

Write-Verbose 'Downloading Teams (New)'
$TeamsNewPath = Join-Path $TempDir '/MSTeams-x64.msix'
curl.exe -L --url "https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix" -o "${TeamsNewPath}"

$PPParams = @{'Online'=$true;'SkipLicense'=$true}
Add-ProvisionedAppxPackage @PPParams -PackagePath $UIXamlAppXPath
Add-ProvisionedAppxPackage @PPParams -PackagePath $VCLibsPath
Add-ProvisionedAppxPackage @PPParams -PackagePath $WinGetPath
Add-ProvisionedAppxPackage @PPParams -PackagePath $TeamsNewPath

Remove-Item -Force -Path $NuGetExe
Remove-Item -Force -Path $UIXamlAppXPath
Remove-Item -Force -Path $VCLibsPath
Remove-Item -Force -Path $WinGetPath
Remove-Item -Force -Path $TeamsNewPath
$TempDir.Delete($true)

$ProgressPreference = $oldProgressPreference

[Console]::WriteLine("$esc[92mDone!$esc[0m")
return 0
# SIG # Begin signature block
# MIIpCwYJKoZIhvcNAQcCoIIo/DCCKPgCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCRCS9TRIZyS6PM
# KbAZyxYbWI5HxE9xDpDqrGl/LmdmxKCCEf4wggVvMIIEV6ADAgECAhBI/JO0YFWU
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZpMIIE0aADAgECAhA9xSGBnzvvMeeGkn/BnKvaMA0GCSqG
# SIb3DQEBDAUAMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxKzApBgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYw
# HhcNMjMwNzA0MDAwMDAwWhcNMjYwNzAzMjM1OTU5WjBZMQswCQYDVQQGEwJHQjEY
# MBYGA1UECAwPTm90dGluZ2hhbXNoaXJlMRcwFQYDVQQKDA5KYWNrIFdpbGtpbnNv
# bjEXMBUGA1UEAwwOSmFjayBXaWxraW5zb24wggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQDLDHS+qV88xX2DelqyOcUen4ci4gEtjXq+2X0JWKu6FsQghexb
# 14kpgegg4S0AHK+GqM2Q+IBUzu/NIFO6+JOmRB9MP5t1nsLYEnkNe1YQiFFnoEWg
# nAyUZ7BmGM1QQIvq5A3XZ2AAa5MEKmfXd3ZfnjXSLWX8DWxelp2IUbUj7g/gcrCX
# iNDdhBGhvIXlvVmvDvihXnjWZvH4MrRkmLrDFLnetfWjZbjyWNFHbunhaNXraOK9
# xASmHE2PhBArEfIdAq/oGPJdDMyIB/HZBBckln1C9olytVX5oJaIBcEoBvwz5oUx
# k6xk44g+SUetgnyZJEJ35KdxnifhJd0fYe8Tq3fei64rqrNF0zqPQgYLn23Zt369
# 5H5eRprbPP6CKa+s4uBKnjSG1cdl86P2xnPqc0zm+fFAnwGbjawrfOR2j08b0pK2
# BbC0NHdLABToe41ijmC412qR4lzVtRgw0H2yT8S3BN7RXdx0Spz6dc9d+mQZwtm2
# l4NZ2otQETgdkKDwBp2lgppq0CZuZM3UQpzhFrbTrw7/qNTTuHuRQrtHhqFce04t
# C08qMgSV5ULJx4mNc9+0kk0hed/EbxA+luvLyibpZpcvpJUaC84IB2rxzT6sfIKK
# 4YDY3gObqvzhfItAqsqBk3oO2RK3l3MCtjXpzQO+Imk8s/xgWB0pw1Sq2wIDAQAB
# o4IBsDCCAawwHwYDVR0jBBgwFoAUDyrLIIcouOxvSK4rVKYpqhekzQwwHQYDVR0O
# BBYEFOimTyFCorDNcYbL/pKg1xm+CwbTMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMB
# Af8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMEoGA1UdIARDMEEwNQYMKwYBBAGy
# MQECAQMCMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgG
# BmeBDAEEATBJBgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLnNlY3RpZ28uY29t
# L1NlY3RpZ29QdWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNybDB5BggrBgEFBQcBAQRt
# MGswRAYIKwYBBQUHMAKGOGh0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nQ0FSMzYuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2Nz
# cC5zZWN0aWdvLmNvbTAlBgNVHREEHjAcgRpqYWNrLndpbGtpbnNvbkBib2tldHRv
# LmRldjANBgkqhkiG9w0BAQwFAAOCAYEALIZMmMNf6SsX3aQtijsgRgjxR+DOdXPS
# 1q2C68lG3xHtHFCgr43rK31/SKUZ8JKE+eQGUDS+evikNQ7DGiW9gQFojEUQ1dsj
# 8Bt/RcAiyJn6/MgYCoEXQBWZID1SaioJDAo4SAjEZ4JytS3tHjWeNa2zoBajWSPC
# 1ml1k9J/uythgkLLGbAJbHFyM3DQkB8WX+nljWjvcLxX7j/y2XMLbBJwSkQU9e3K
# 6Wod5YUV5FaE5SKXRt1G1h3Vb5nZ43G24y9Qxoafklq+KDoi4V/PRXwODGN8elOx
# +G3w0ReqRhTZqJ0Kz/aNPPgNfua4KXNzolb3NdynTC9bLji25p7zZF95O+uVkWFt
# KpJMsoxaCJYqkfjHXpNwBkqse4cHXeevw0Ah5ZGwjet7InNo4eqphR/UrkGcENp8
# zUeT9DFo0slUgC3TBm5jgPbz+AfvNjyJ81C+nGB6HDt1XICRLYuHzkw7Dho3WRfl
# 21LfPnysbLoRkNfD3rPEql3a67zjXNS3MYIWYzCCFl8CAQEwaDBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA9xSGBnzvvMeeGkn/BnKvaMA0G
# CWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIBY/JZkydoLB/3rsYYoRuur2CafUopkXHdRn6OmqTdxDMA0GCSqG
# SIb3DQEBAQUABIICAJXY7Gx7vX/y8WbiOvnZ9Ddwf1S3q6Skf/5RPt/Hj7VjEvvE
# Cogcc3XNX09hEwuoip4w4qq4tlw79xMU27iers+UrR4wG/7KZ+/w1a3bA2XuqEz1
# T95ICSwEaKXJknO7WQCLEOPfAVNbBmkN7FUt+i0LlXXue0wV0h+LxSOG+SpYWj4u
# /7gTsHUtlwO1/9paNe5gybManJwJfUDUWGnebtaNf35EZg+ljCTLrdqMOIOemwS7
# xPvgMn58xq30puJ5e4yUlVf3HDtQr+VVEEsDfrkABgi6ssNMBTMsrQv35JvFLqhv
# mjqWUEXJqJo9ojkGP7PCjaXoDCLYGrabR18Vm20Lg3f6aSuX26B7lineQcqhV89i
# 0y86AIN4nSr/Bp2dbl+u5K5be3lDfswirvyoWK6ClLgLIHKh59MD4zhG0zk4v2OR
# jdQi/v+xmnTCVkkVBSH94LvA+yrjwQFRZRB97DzvELeUKJuIWrTbI5Q/pGHhsMb3
# MKiaS20hvSX1Eqw5gM8yASE0lL1A1/0/9ujRd5q7alZqS+qk8VjCJjOrnJGd+Jwc
# HabBQjzjuqT4uYIU4Ybs2nkeaBN1yEs0oELr6PqbUUoEcja5lDfx/nj8FlGGtdv5
# KhQdd1LUUMCRM331eWnd0sFWxQaLvkdTVcFjNIGWghuZ0qFUsovOoBJmT8gMoYIT
# TjCCE0oGCisGAQQBgjcDAwExghM6MIITNgYJKoZIhvcNAQcCoIITJzCCEyMCAQMx
# DzANBglghkgBZQMEAgIFADCB7wYLKoZIhvcNAQkQAQSggd8EgdwwgdkCAQEGCisG
# AQQBsjECAQEwMTANBglghkgBZQMEAgEFAAQgrfSvfxhZz0eKdfhVUOr8Nks0x3f+
# sV99DKJQn4doQUACFCl6wpgPyaMbF7t111MblFO5KUC2GA8yMDI0MDUzMTEzMjY0
# MlqgbqRsMGoxCzAJBgNVBAYTAkdCMRMwEQYDVQQIEwpNYW5jaGVzdGVyMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLDAqBgNVBAMMI1NlY3RpZ28gUlNBIFRpbWUg
# U3RhbXBpbmcgU2lnbmVyICM0oIIN6TCCBvUwggTdoAMCAQICEDlMJeF8oG0nqGXi
# O9kdItQwDQYJKoZIhvcNAQEMBQAwfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdy
# ZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2Vj
# dGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5n
# IENBMB4XDTIzMDUwMzAwMDAwMFoXDTM0MDgwMjIzNTk1OVowajELMAkGA1UEBhMC
# R0IxEzARBgNVBAgTCk1hbmNoZXN0ZXIxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRl
# ZDEsMCoGA1UEAwwjU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBTaWduZXIgIzQw
# ggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQCkkyhSS88nh3akKRyZOMDn
# DtTRHOxoywFk5IrNd7BxZYK8n/yLu7uVmPslEY5aiAlmERRYsroiW+b2MvFdLcB6
# og7g4FZk7aHlgSByIGRBbMfDCPrzfV3vIZrCftcsw7oRmB780yAIQrNfv3+IWDKr
# MLPYjHqWShkTXKz856vpHBYusLA4lUrPhVCrZwMlobs46Q9vqVqakSgTNbkf8z3h
# JMhrsZnoDe+7TeU9jFQDkdD8Lc9VMzh6CRwH0SLgY4anvv3Sg3MSFJuaTAlGvTS8
# 4UtQe3LgW/0Zux88ahl7brstRCq+PEzMrIoEk8ZXhqBzNiuBl/obm36Ih9hSeYn+
# bnc317tQn/oYJU8T8l58qbEgWimro0KHd+D0TAJI3VilU6ajoO0ZlmUVKcXtMzAl
# 5paDgZr2YGaQWAeAzUJ1rPu0kdDF3QFAaraoEO72jXq3nnWv06VLGKEMn1ewXiVH
# kXTNdRLRnG/kXg2b7HUm7v7T9ZIvUoXo2kRRKqLMAMqHZkOjGwDvorWWnWKtJwvy
# G0rJw5RCN4gghKiHrsO6I3J7+FTv+GsnsIX1p0OF2Cs5dNtadwLRpPr1zZw9zB+u
# UdB7bNgdLRFCU3F0wuU1qi1SEtklz/DT0JFDEtcyfZhs43dByP8fJFTvbq3GPlV7
# 8VyHOmTxYEsFT++5L+wJEwIDAQABo4IBgjCCAX4wHwYDVR0jBBgwFoAUGqH4YRkg
# D8NBd0UojtE1XwYSBFUwHQYDVR0OBBYEFAMPMciRKpO9Y/PRXU2kNA/SlQEYMA4G
# A1UdDwEB/wQEAwIGwDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUF
# BwMIMEoGA1UdIARDMEEwNQYMKwYBBAGyMQECAQMIMCUwIwYIKwYBBQUHAgEWF2h0
# dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAEEAjBEBgNVHR8EPTA7MDmgN6A1
# hjNodHRwOi8vY3JsLnNlY3RpZ28uY29tL1NlY3RpZ29SU0FUaW1lU3RhbXBpbmdD
# QS5jcmwwdAYIKwYBBQUHAQEEaDBmMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnNl
# Y3RpZ28uY29tL1NlY3RpZ29SU0FUaW1lU3RhbXBpbmdDQS5jcnQwIwYIKwYBBQUH
# MAGGF2h0dHA6Ly9vY3NwLnNlY3RpZ28uY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBM
# m2VY+uB5z+8VwzJt3jOR63dY4uu9y0o8dd5+lG3DIscEld9laWETDPYMnvWJIF7B
# h8cDJMrHpfAm3/j4MWUN4OttUVemjIRSCEYcKsLe8tqKRfO+9/YuxH7t+O1ov3pW
# SOlh5Zo5d7y+upFkiHX/XYUWNCfSKcv/7S3a/76TDOxtog3Mw/FuvSGRGiMAUq2X
# 1GJ4KoR5qNc9rCGPcMMkeTqX8Q2jo1tT2KsAulj7NYBPXyhxbBlewoNykK7gxtjy
# mfvqtJJlfAd8NUQdrVgYa2L73mzECqls0yFGcNwvjXVMI8JB0HqWO8NL3c2SJnR2
# XDegmiSeTl9O048P5RNPWURlS0Nkz0j4Z2e5Tb/MDbE6MNChPUitemXk7N/gAfCz
# Kko5rMGk+al9NdAyQKCxGSoYIbLIfQVxGksnNqrgmByDdefHfkuEQ81D+5CXdioS
# rEDBcFuZCkD6gG2UYXvIbrnIZ2ckXFCNASDeB/cB1PguEc2dg+X4yiUcRD0n5bCG
# RyoLG4R2fXtoT4239xO07aAt7nMP2RC6nZksfNd1H48QxJTmfiTllUqIjCfWhWYd
# +a5kdpHoSP7IVQrtKcMf3jimwBT7Mj34qYNiNsjDvgCHHKv6SkIciQPc9Vx8cNld
# eE7un14g5glqfCsIo0j1FfwET9/NIRx65fWOGtS5QDCCBuwwggTUoAMCAQICEDAP
# b6zdZph0fKlGNqd4LbkwDQYJKoZIhvcNAQEMBQAwgYgxCzAJBgNVBAYTAlVTMRMw
# EQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwGA1UE
# ChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3QgUlNB
# IENlcnRpZmljYXRpb24gQXV0aG9yaXR5MB4XDTE5MDUwMjAwMDAwMFoXDTM4MDEx
# ODIzNTk1OVowfTELMAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hl
# c3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVk
# MSUwIwYDVQQDExxTZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBMIICIjANBgkq
# hkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAyBsBr9ksfoiZfQGYPyCQvZyAIVSTuc+g
# PlPvs1rAdtYaBKXOR4O168TMSTTL80VlufmnZBYmCfvVMlJ5LsljwhObtoY/AQWS
# Zm8hq9VxEHmH9EYqzcRaydvXXUlNclYP3MnjU5g6Kh78zlhJ07/zObu5pCNCrNAV
# w3+eolzXOPEWsnDTo8Tfs8VyrC4Kd/wNlFK3/B+VcyQ9ASi8Dw1Ps5EBjm6dJ3VV
# 0Rc7NCF7lwGUr3+Az9ERCleEyX9W4L1GnIK+lJ2/tCCwYH64TfUNP9vQ6oWMilZx
# 0S2UTMiMPNMUopy9Jv/TUyDHYGmbWApU9AXn/TGs+ciFF8e4KRmkKS9G493bkV+f
# PzY+DjBnK0a3Na+WvtpMYMyou58NFNQYxDCYdIIhz2JWtSFzEh79qsoIWId3pBXr
# GVX/0DlULSbuRRo6b83XhPDX8CjFT2SDAtT74t7xvAIo9G3aJ4oG0paH3uhrDvBb
# fel2aZMgHEqXLHcZK5OVmJyXnuuOwXhWxkQl3wYSmgYtnwNe/YOiU2fKsfqNoWTJ
# iJJZy6hGwMnypv99V9sSdvqKQSTUG/xypRSi1K1DHKRJi0E5FAMeKfobpSKupcNN
# gtCN2mu32/cYQFdz8HGj+0p9RTbB942C+rnJDVOAffq2OVgy728YUInXT50zvRq1
# naHelUF6p4MCAwEAAaOCAVowggFWMB8GA1UdIwQYMBaAFFN5v1qqK0rPVIDh2JvA
# nfKyA2bLMB0GA1UdDgQWBBQaofhhGSAPw0F3RSiO0TVfBhIEVTAOBgNVHQ8BAf8E
# BAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNVHSUEDDAKBggrBgEFBQcDCDAR
# BgNVHSAECjAIMAYGBFUdIAAwUAYDVR0fBEkwRzBFoEOgQYY/aHR0cDovL2NybC51
# c2VydHJ1c3QuY29tL1VTRVJUcnVzdFJTQUNlcnRpZmljYXRpb25BdXRob3JpdHku
# Y3JsMHYGCCsGAQUFBwEBBGowaDA/BggrBgEFBQcwAoYzaHR0cDovL2NydC51c2Vy
# dHJ1c3QuY29tL1VTRVJUcnVzdFJTQUFkZFRydXN0Q0EuY3J0MCUGCCsGAQUFBzAB
# hhlodHRwOi8vb2NzcC51c2VydHJ1c3QuY29tMA0GCSqGSIb3DQEBDAUAA4ICAQBt
# VIGlM10W4bVTgZF13wN6MgstJYQRsrDbKn0qBfW8Oyf0WqC5SVmQKWxhy7VQ2+J9
# +Z8A70DDrdPi5Fb5WEHP8ULlEH3/sHQfj8ZcCfkzXuqgHCZYXPO0EQ/V1cPivNVY
# eL9IduFEZ22PsEMQD43k+ThivxMBxYWjTMXMslMwlaTW9JZWCLjNXH8Blr5yUmo7
# Qjd8Fng5k5OUm7Hcsm1BbWfNyW+QPX9FcsEbI9bCVYRm5LPFZgb289ZLXq2jK0KK
# IZL+qG9aJXBigXNjXqC72NzXStM9r4MGOBIdJIct5PwC1j53BLwENrXnd8ucLo0j
# GLmjwkcd8F3WoXNXBWiap8k3ZR2+6rzYQoNDBaWLpgn/0aGUpk6qPQn1BWy30mRa
# 2Coiwkud8TleTN5IPZs0lpoJX47997FSkc4/ifYcobWpdR9xv1tDXWU9UIFuq/DQ
# 0/yysx+2mZYm9Dx5i1xkzM3uJ5rloMAMcofBbk1a0x7q8ETmMm8c6xdOlMN4ZSA7
# D0GqH+mhQZ3+sbigZSo04N6o+TzmwTC7wKBjLPxcFgCo0MR/6hGdHgbGpm0yXbQ4
# CStJB6r97DDa8acvz7f9+tCjhNknnvsBZne5VhDhIG7GrrH5trrINV0zdo7xfCAM
# KneutaIChrop7rRaALGMq+P5CslUXdS5anSevUiumDGCBCwwggQoAgEBMIGRMH0x
# CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
# BAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMc
# U2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIQOUwl4XygbSeoZeI72R0i1DAN
# BglghkgBZQMEAgIFAKCCAWswGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMBwG
# CSqGSIb3DQEJBTEPFw0yNDA1MzExMzI2NDJaMD8GCSqGSIb3DQEJBDEyBDA38vfu
# OHZPqxFCjS3xkXBkoJD8ml9BaFfkju+itLA1oObvlKn3x2t8juK86DvkhVcwge0G
# CyqGSIb3DQEJEAIMMYHdMIHaMIHXMBYEFK5ir3UKDL1H1kYfdWjivIznyk+UMIG8
# BBQC1luV4oNwwVcAlfqI+SPdk3+tjzCBozCBjqSBizCBiDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYD
# VQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBS
# U0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkCEDAPb6zdZph0fKlGNqd4LbkwDQYJ
# KoZIhvcNAQEBBQAEggIAPD8wYL8kcX9nMIjvguoJChRPYLjKX8D1VgZvwC/kmxhn
# WeSK9glfy3rhc2TSaxw0mtAiFq3wQKVl1zOBVwQzZK1OEYSAnNcCHeCkjhY+MIVJ
# 5YHG2EgLA4uGmuu24MCjJuDyrBf90yWRozTy8s/qVyfAJy804hdoTAVG7vfZZOP5
# 5juHZkxt4OkrtKqg5aGZDuFl1i5nA7BOhrB2scjSfmbZ96eb4WY5puUu0nQIJhdp
# bf2JrbRV8dEueBb4zpAwQvuYeMDyZXasa0fmB2kJqx+GoOz/OG2/LfWVzousZtEV
# PhlgH/2Z7GMNQ/ij12dsGELbtJ0d7xWsrXzz1xFlFlhJQ8lSFjDyx4BD+UXUpJcN
# J18cRu4LdDKX/KK7HDg+HcWu7frcUORChROehgqxgeATS1symMrK5RLjLbKXv29f
# cagYJ5PwB4zQ3toO3IZHAQsuegf4rdlkiVp9BE5GXw+cyGfHzapW6TTu8NHUEChP
# SsFr7wq1DE9H+0tbcjH0OHBD+ueJeSOLOv/JfYnWw7vTMTc7cLEvIHMZRM9I510I
# aPu48GPIyGQfIKemIlvMClH697oM8YLhrHwBtOnTQJ8LdBZiMvpacEkauFdGpXrJ
# vVkXhJ9RRcXR/wzuLQy8pVHT++9RJjRDKq7G3IkHFLgdShH5c5DH+KrVPyzNYRs=
# SIG # End signature block
