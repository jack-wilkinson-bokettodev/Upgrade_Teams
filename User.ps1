Clear-Host
$esc = [char]27
$oldProgressPreference = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'

$TeamsUserPackages = Get-AppxPackage -Name '*Teams*'
$ConsumerTeamsUserPackages = @($TeamsUserPackages | ? {$_.PackageFamilyName -EQ 'MicrosoftTeams_8wekyb3d8bbwe'})
$BusinessTeamsUserPackages = @($TeamsUserPackages | ? {$_.PackageFamilyName -EQ 'MSTeams_8wekyb3d8bbwe'})
$LegacyTeamsUserPackages = Get-ChildItem -Path 'Microsoft.PowerShell.Core\Registry::HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' -Depth 1 -EA 'SilentlyContinue' | Get-ItemProperty -Name 'DisplayName' -EA 'SilentlyContinue' | ? {($_.DisplayName -EQ 'Microsoft Teams classic') -OR ($_.DisplayName -EQ 'Microsoft Teams')}

if ($ConsumerTeamsUserPackages.Count -GT 0)
{
	[Console]::WriteLine("$esc[91mTeams (Home)$esc[96m detected!$esc[0m")
	[Console]::WriteLine("$esc[96mRemoving $esc[91mTeams (Home)$esc[0m")
	$ConsumerTeamsUserPackages | Remove-AppxPackage
}

if ($LegacyTeamsUserPackages.Count -GT 0)
{
	[Console]::WriteLine("$esc[91mTeams (Legacy)$esc[96m detected!$esc[0m")
	[Console]::WriteLine("$esc[96mRemoving $esc[91mTeams (Legacy)$esc[0m")
	$LegacyTeamsUserPackages | Get-ItemProperty -Name 'UninstallString' | Select -Exp 'UninstallString' | % {"cmd.exe /c start /wait `"`" ${_}"} | iex
}

if ($BusinessTeamsUserPackages.Count -GT 0)
{
	return 0
}

if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {$TempRoot = (Join-Path ${env:WinDir} 'temp'); [Console]::WriteLine("$esc[96mRunning as Adminstrator$esc[0m")} else {$TempRoot = ${env:temp}; [Console]::WriteLine("$esc[91mNot $esc[96mRunning as Administrator")}
$TempDir = New-Item -ItemType 'Container' -Path $TempRoot -Name "{$([GUID]::NewGuid().GUID)}" -Force
[Console]::WriteLine("$esc[96mWorking from `"$esc[92m$($TempDir.FullName)$esc[96m`"$esc[0m")

[Console]::WriteLine("$esc[96mDownloading $esc[92mNuGet CLI$esc[0m")
$NuGetExe = Join-Path $TempDir '/NuGet.exe'
curl.exe -L --url "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe" -o "${NuGetExe}"

[Console]::WriteLine("$esc[96mDownloading $esc[92mMicrosoft.UI.Xaml$esc[0m")
Start-Process -Wait -FilePath $NuGetExe -WorkingDirectory $TempDir -NoNewWindow -ArgumentList @('install','"Microsoft.UI.Xaml"','-DependencyVersion','"ignore"')
$UIXamlFolder = Resolve-Path -Path (Join-Path $TempDir './Microsoft.UI.Xaml.*.*.*')
if (!($UIXamlFolder)) {Write-Warning 'Unable to Download Microsoft.UI.Xaml';return $false}
$UIXamlAppXPath = Copy-Item -Path (Join-Path $UIXamlFolder '/tools/AppX/x64/Release/*.appx') -Destination $TempDir -PassThru

[Console]::WriteLine("$esc[96mInstalling $esc[92mMicrosoft.UI.Xaml.2.8$esc[0m")
Add-AppxPackage -Path $UIXamlAppXPath -EA 'SilentlyContinue'
[Console]::WriteLine("$esc[96mInstalling $esc[92mMicrosoft.VCLibs.x64.14.00.Desktop$esc[0m")
Add-AppxPackage -Path 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' -EA 'SilentlyContinue'
[Console]::WriteLine("$esc[96mInstalling $esc[92mEdge WebView2")
$p = Start-Process -PassThru -FilePath $EdgeWebViewPath -ArgumentList '/silent','/install' -Verb RunAs
$p.WaitForExit()
[Console]::WriteLine("$esc[96mInstalling $esc[92mDesktop App Installler$esc[0m")
Add-AppxPackage -Path 'https://aka.ms/getwinget' -EA 'SilentlyContinue'
[Console]::WriteLine("$esc[96mInstalling $esc[92mMicrosoft Teams $esc[96m($esc[91mNew$esc[96m)$esc[0m")
Add-AppxPackage -Path 'https://statics.teams.cdn.office.net/production-windows-x64/enterprise/webview2/lkg/MSTeams-x64.msix' -EA 'SilentlyContinue'

[Console]::WriteLine("$esc[96mRemoving $esc[92mNuGet CLI$esc[0m")
Remove-Item -Path $NuGetExe -Force
[Console]::WriteLine("$esc[96mRemoving $esc[92mMicrosoft.UI.Xaml $esc[96mPackage$esc[0m")
Remove-Item -Path $UIXamlFolder -Recurse -Force
[Console]::WriteLine("$esc[96mRemoving $esc[92mMicrosoft.UI.Xaml.2.8.appx$esc[0m")
Remove-Item -Path $UIXamlAppXPath -Force
[Console]::WriteLine("$esc[96mRemoving Working Directory$esc[0m")
$TempDir.Delete($true)

$ProgressPreference = $oldProgressPreference

[Console]::WriteLine("$esc[92mDone!$esc[0m")
return 0
# SIG # Begin signature block
# MIIpDAYJKoZIhvcNAQcCoIIo/TCCKPkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAkURZXxusIixEF
# CwufcapPwUuuBdFLrVm5pVcETz9JBKCCEf4wggVvMIIEV6ADAgECAhBI/JO0YFWU
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
# 21LfPnysbLoRkNfD3rPEql3a67zjXNS3MYIWZDCCFmACAQEwaDBUMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2AhA9xSGBnzvvMeeGkn/BnKvaMA0G
# CWCGSAFlAwQCAQUAoHwwEAYKKwYBBAGCNwIBDDECMAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZI
# hvcNAQkEMSIEIBLixjapwwRbgADuy2zGQsVzOFjjjX5ckJRISX27AUJuMA0GCSqG
# SIb3DQEBAQUABIICAJimdS7+jCRXsbDrnPLYflmaA9tNdnTeGxGnh/5cr8njdXx3
# BqXr3QKLj/3WArx/31RdP7671sA9lxc6lftS8HdrM/UKhzzhJ9bBrxlYwQKqHkwV
# 3pAVWvpCmX7E4TamS1eZdZ4LipW1yn1l9F8YPBGA7yoVCTp0YJ+YYh4vrBClmTE9
# /CoZjF5Ahc3Ytsorruk+NE7hYRi07FyJWDZ3DW+SUv0NBxcAbHqsSTcLkFSQYCuf
# Tmt3sCq3V+/614USBmOfbVMvrsnXmtU6Y8rJGB8xsWiN+Zw1g1umxBb9Lxt/4h6y
# kLyaEFn9tmbf3CPdaAclnFT60eYOVyvkf5IgohQ75UHETRCynrrdOYcLjdyJ0d4A
# w7mcV6/814duVZgSb3S6Lp/RVQAN+Hd2D4AjDs2a7cm/e9ZcWVr3sofVwXGpT8M3
# glwAHAchWjrLIUxea/JOyFLn+62NGs1DN93tsQcZK6EOpfZJcPz77w0v/hphmznj
# 8zROf4C2lqY0jvIjXUs/ZGeeVTh0AolQIXTQ14nsiky0emIyxgW8AVHMYoyIKodE
# x5FnnbNDxBY6nq69L78Vz4j7KMSKPqyAZdXmVmCNum4dSjGox8O9fqksTihxxuf2
# AqO+QNGoJEOYlH0gGfl3c0uSUBIX/ay7lnpsntudhuMyAbdC2nUiPYP8u96poYIT
# TzCCE0sGCisGAQQBgjcDAwExghM7MIITNwYJKoZIhvcNAQcCoIITKDCCEyQCAQMx
# DzANBglghkgBZQMEAgIFADCB8AYLKoZIhvcNAQkQAQSggeAEgd0wgdoCAQEGCisG
# AQQBsjECAQEwMTANBglghkgBZQMEAgEFAAQghFEH/ZNLB58km1tI71BYKEQ4AJI4
# XgPAUIDnDK+k2P0CFQDT9cPLJO2MyUqpM2vaypUBbCkWfhgPMjAyNDA1MzExMzI2
# NTZaoG6kbDBqMQswCQYDVQQGEwJHQjETMBEGA1UECBMKTWFuY2hlc3RlcjEYMBYG
# A1UEChMPU2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0aWdvIFJTQSBUaW1l
# IFN0YW1waW5nIFNpZ25lciAjNKCCDekwggb1MIIE3aADAgECAhA5TCXhfKBtJ6hl
# 4jvZHSLUMA0GCSqGSIb3DQEBDAUAMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJH
# cmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1Nl
# Y3RpZ28gTGltaXRlZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGlu
# ZyBDQTAeFw0yMzA1MDMwMDAwMDBaFw0zNDA4MDIyMzU5NTlaMGoxCzAJBgNVBAYT
# AkdCMRMwEQYDVQQIEwpNYW5jaGVzdGVyMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxLDAqBgNVBAMMI1NlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgU2lnbmVyICM0
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEApJMoUkvPJ4d2pCkcmTjA
# 5w7U0RzsaMsBZOSKzXewcWWCvJ/8i7u7lZj7JRGOWogJZhEUWLK6Ilvm9jLxXS3A
# eqIO4OBWZO2h5YEgciBkQWzHwwj6831d7yGawn7XLMO6EZge/NMgCEKzX79/iFgy
# qzCz2Ix6lkoZE1ys/Oer6RwWLrCwOJVKz4VQq2cDJaG7OOkPb6lampEoEzW5H/M9
# 4STIa7GZ6A3vu03lPYxUA5HQ/C3PVTM4egkcB9Ei4GOGp7790oNzEhSbmkwJRr00
# vOFLUHty4Fv9GbsfPGoZe267LUQqvjxMzKyKBJPGV4agczYrgZf6G5t+iIfYUnmJ
# /m53N9e7UJ/6GCVPE/JefKmxIFopq6NCh3fg9EwCSN1YpVOmo6DtGZZlFSnF7TMw
# JeaWg4Ga9mBmkFgHgM1Cdaz7tJHQxd0BQGq2qBDu9o16t551r9OlSxihDJ9XsF4l
# R5F0zXUS0Zxv5F4Nm+x1Ju7+0/WSL1KF6NpEUSqizADKh2ZDoxsA76K1lp1irScL
# 8htKycOUQjeIIISoh67DuiNye/hU7/hrJ7CF9adDhdgrOXTbWncC0aT69c2cPcwf
# rlHQe2zYHS0RQlNxdMLlNaotUhLZJc/w09CRQxLXMn2YbON3Qcj/HyRU726txj5V
# e/Fchzpk8WBLBU/vuS/sCRMCAwEAAaOCAYIwggF+MB8GA1UdIwQYMBaAFBqh+GEZ
# IA/DQXdFKI7RNV8GEgRVMB0GA1UdDgQWBBQDDzHIkSqTvWPz0V1NpDQP0pUBGDAO
# BgNVHQ8BAf8EBAMCBsAwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEF
# BQcDCDBKBgNVHSAEQzBBMDUGDCsGAQQBsjEBAgEDCDAlMCMGCCsGAQUFBwIBFhdo
# dHRwczovL3NlY3RpZ28uY29tL0NQUzAIBgZngQwBBAIwRAYDVR0fBD0wOzA5oDeg
# NYYzaHR0cDovL2NybC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0YW1waW5n
# Q0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA/BggrBgEFBQcwAoYzaHR0cDovL2NydC5z
# ZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0YW1waW5nQ0EuY3J0MCMGCCsGAQUF
# BzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEA
# TJtlWPrgec/vFcMybd4zket3WOLrvctKPHXefpRtwyLHBJXfZWlhEwz2DJ71iSBe
# wYfHAyTKx6XwJt/4+DFlDeDrbVFXpoyEUghGHCrC3vLaikXzvvf2LsR+7fjtaL96
# VkjpYeWaOXe8vrqRZIh1/12FFjQn0inL/+0t2v++kwzsbaINzMPxbr0hkRojAFKt
# l9RieCqEeajXPawhj3DDJHk6l/ENo6NbU9irALpY+zWAT18ocWwZXsKDcpCu4MbY
# 8pn76rSSZXwHfDVEHa1YGGti+95sxAqpbNMhRnDcL411TCPCQdB6ljvDS93NkiZ0
# dlw3oJoknk5fTtOPD+UTT1lEZUtDZM9I+GdnuU2/zA2xOjDQoT1IrXpl5Ozf4AHw
# sypKOazBpPmpfTXQMkCgsRkqGCGyyH0FcRpLJzaq4Jgcg3Xnx35LhEPNQ/uQl3Yq
# EqxAwXBbmQpA+oBtlGF7yG65yGdnJFxQjQEg3gf3AdT4LhHNnYPl+MolHEQ9J+Ww
# hkcqCxuEdn17aE+Nt/cTtO2gLe5zD9kQup2ZLHzXdR+PEMSU5n4k5ZVKiIwn1oVm
# HfmuZHaR6Ej+yFUK7SnDH944psAU+zI9+KmDYjbIw74Ahxyr+kpCHIkD3PVcfHDZ
# XXhO7p9eIOYJanwrCKNI9RX8BE/fzSEceuX1jhrUuUAwggbsMIIE1KADAgECAhAw
# D2+s3WaYdHypRjaneC25MA0GCSqGSIb3DQEBDAUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5IENpdHkxHjAcBgNV
# BAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMlVVNFUlRydXN0IFJT
# QSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xOTA1MDIwMDAwMDBaFw0zODAx
# MTgyMzU5NTlaMH0xCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNo
# ZXN0ZXIxEDAOBgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRl
# ZDElMCMGA1UEAxMcU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQTCCAiIwDQYJ
# KoZIhvcNAQEBBQADggIPADCCAgoCggIBAMgbAa/ZLH6ImX0BmD8gkL2cgCFUk7nP
# oD5T77NawHbWGgSlzkeDtevEzEk0y/NFZbn5p2QWJgn71TJSeS7JY8ITm7aGPwEF
# kmZvIavVcRB5h/RGKs3EWsnb111JTXJWD9zJ41OYOioe/M5YSdO/8zm7uaQjQqzQ
# FcN/nqJc1zjxFrJw06PE37PFcqwuCnf8DZRSt/wflXMkPQEovA8NT7ORAY5unSd1
# VdEXOzQhe5cBlK9/gM/REQpXhMl/VuC9RpyCvpSdv7QgsGB+uE31DT/b0OqFjIpW
# cdEtlEzIjDzTFKKcvSb/01Mgx2Bpm1gKVPQF5/0xrPnIhRfHuCkZpCkvRuPd25Ff
# nz82Pg4wZytGtzWvlr7aTGDMqLufDRTUGMQwmHSCIc9iVrUhcxIe/arKCFiHd6QV
# 6xlV/9A5VC0m7kUaOm/N14Tw1/AoxU9kgwLU++Le8bwCKPRt2ieKBtKWh97oaw7w
# W33pdmmTIBxKlyx3GSuTlZicl57rjsF4VsZEJd8GEpoGLZ8DXv2DolNnyrH6jaFk
# yYiSWcuoRsDJ8qb/fVfbEnb6ikEk1Bv8cqUUotStQxykSYtBORQDHin6G6UirqXD
# TYLQjdprt9v3GEBXc/Bxo/tKfUU2wfeNgvq5yQ1TgH36tjlYMu9vGFCJ10+dM70a
# tZ2h3pVBeqeDAgMBAAGjggFaMIIBVjAfBgNVHSMEGDAWgBRTeb9aqitKz1SA4dib
# wJ3ysgNmyzAdBgNVHQ4EFgQUGqH4YRkgD8NBd0UojtE1XwYSBFUwDgYDVR0PAQH/
# BAQDAgGGMBIGA1UdEwEB/wQIMAYBAf8CAQAwEwYDVR0lBAwwCgYIKwYBBQUHAwgw
# EQYDVR0gBAowCDAGBgRVHSAAMFAGA1UdHwRJMEcwRaBDoEGGP2h0dHA6Ly9jcmwu
# dXNlcnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FDZXJ0aWZpY2F0aW9uQXV0aG9yaXR5
# LmNybDB2BggrBgEFBQcBAQRqMGgwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQudXNl
# cnRydXN0LmNvbS9VU0VSVHJ1c3RSU0FBZGRUcnVzdENBLmNydDAlBggrBgEFBQcw
# AYYZaHR0cDovL29jc3AudXNlcnRydXN0LmNvbTANBgkqhkiG9w0BAQwFAAOCAgEA
# bVSBpTNdFuG1U4GRdd8DejILLSWEEbKw2yp9KgX1vDsn9FqguUlZkClsYcu1UNvi
# ffmfAO9Aw63T4uRW+VhBz/FC5RB9/7B0H4/GXAn5M17qoBwmWFzztBEP1dXD4rzV
# WHi/SHbhRGdtj7BDEA+N5Pk4Yr8TAcWFo0zFzLJTMJWk1vSWVgi4zVx/AZa+clJq
# O0I3fBZ4OZOTlJux3LJtQW1nzclvkD1/RXLBGyPWwlWEZuSzxWYG9vPWS16toytC
# iiGS/qhvWiVwYoFzY16gu9jc10rTPa+DBjgSHSSHLeT8AtY+dwS8BDa153fLnC6N
# Ixi5o8JHHfBd1qFzVwVomqfJN2Udvuq82EKDQwWli6YJ/9GhlKZOqj0J9QVst9Jk
# WtgqIsJLnfE5XkzeSD2bNJaaCV+O/fexUpHOP4n2HKG1qXUfcb9bQ11lPVCBbqvw
# 0NP8srMftpmWJvQ8eYtcZMzN7iea5aDADHKHwW5NWtMe6vBE5jJvHOsXTpTDeGUg
# Ow9Bqh/poUGd/rG4oGUqNODeqPk85sEwu8CgYyz8XBYAqNDEf+oRnR4GxqZtMl20
# OAkrSQeq/eww2vGnL8+3/frQo4TZJ577AWZ3uVYQ4SBuxq6x+ba6yDVdM3aO8Xwg
# DCp3rrWiAoa6Ke60WgCxjKvj+QrJVF3UuWp0nr1IrpgxggQsMIIEKAIBATCBkTB9
# MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYD
# VQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMT
# HFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0ECEDlMJeF8oG0nqGXiO9kdItQw
# DQYJYIZIAWUDBAICBQCgggFrMBoGCSqGSIb3DQEJAzENBgsqhkiG9w0BCRABBDAc
# BgkqhkiG9w0BCQUxDxcNMjQwNTMxMTMyNjU2WjA/BgkqhkiG9w0BCQQxMgQwUUo9
# kgQJhlrWy97bakbM1nnyuhudvrgMP2L7hzW82bsAQxyAvMGNZR692a7/M4E5MIHt
# BgsqhkiG9w0BCRACDDGB3TCB2jCB1zAWBBSuYq91Cgy9R9ZGH3Vo4ryM58pPlDCB
# vAQUAtZbleKDcMFXAJX6iPkj3ZN/rY8wgaMwgY6kgYswgYgxCzAJBgNVBAYTAlVT
# MRMwEQYDVQQIEwpOZXcgSmVyc2V5MRQwEgYDVQQHEwtKZXJzZXkgQ2l0eTEeMBwG
# A1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMS4wLAYDVQQDEyVVU0VSVHJ1c3Qg
# UlNBIENlcnRpZmljYXRpb24gQXV0aG9yaXR5AhAwD2+s3WaYdHypRjaneC25MA0G
# CSqGSIb3DQEBAQUABIICAG6w0H8CDczSWas3nzx2h3ldBt92nxLdADnPg9P+qeQ8
# aSTeUQ3JpYTmvbNHp7u5Y4LPrXCfBrZKxyW+loBHkOKfLwxo898L7fY78HtDBNkp
# HRIN0S9gOqUVUQ9TmqiwS2uG4UmT+5WYxTOHQz3ZRE6sqR7GnVj+RHKWNVJejCy1
# vtAF2Ph6beyy6AJ2+XVG6kWbNaJU5/SIS6UA9E8nNaSMGMzbPtKnryKme+X+8yfu
# JrSjtyCakOj9pE2aP72+IQzFr1NXoSe4QOYiEzJU77iqC3XHmjNNHt3rqp+u3phW
# YhGA2wq+3JitBvz8AOYFERwLIfrguK1iWj7Mui0zXduvNhtQ1qL1NfqzCt8foM3p
# KpxlkZzFAdTSKBgUs/qz0Ths1vYvzyMPCixFmd5QAevcY+ZvzMgZ1jx31qmBXZoR
# T4hviw+9qwGeZl8UqfF1jHiNeaQg1A6qDtoBspHuQnDYKSTUHiK4BbsxF8cl2K0U
# pRZp4bQDp75cOb9/1JTQIOcB5ELXM0o4ckSEIsZ4zT9lh8c2y9cch7YvVXGGkYHM
# tMxll23UUBTmuQurJN7CT8QZnXv/yPw/yfCRDMvzS7sS7LdZHriC2TDSvkH1kUV3
# Z/dv5cMeQy0Qsk+6ZaY4EdqlfxYb2TGsHjv7SfT2SpCsRR8jt/JnbVAlC3I3uWsZ
# SIG # End signature block
