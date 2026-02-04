#############################################################################
# ByteMorph v2.0 @AΣΞΞΠ
#############################################################################
Function sBanner() {
Write-Host -ForegroundColor Cyan @"
		██████  ██    ██ ████████ ███████  ███╗   ███╗ ██████╗ ██████╗ ██████╗ ██╗  ██╗
		██   ██  ██  ██     ██    ██       ████╗ ████║██╔═══██╗██╔══██╗██╔══██╗██║  ██║
		██████    ████      ██    █████    ██╔████╔██║██║   ██║██████╔╝██████╔╝███████║
		██   ██    ██       ██    ██       ██║╚██╔╝██║██║   ██║██╔══██║██╔═══╝ ██╔══██║
		██████     ██       ██    ███████  ██║ ╚═╝ ██║╚██████╔╝██║  ██║██║     ██║  ██║
						   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝
"@

}

function getBaseToken($PSWD){
 $hasher = [System.Security.Cryptography.HashAlgorithm]::Create('sha512')
 $hash = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PSWD))
 $hashString = [System.BitConverter]::ToString($hash)
 $PSWD=$hashString.Replace('-', '')
 $PSWD=[convert]::ToBase64String([System.Text.encoding]::UTF8.GetBytes($PSWD))
 $PSWD=[convert]::ToBase64String([System.Text.encoding]::UTF8.GetBytes($PSWD))
  
 $PSWD = $PSWD.ToCharArray() | select -Unique
 $PSWD = "$PSWD".Replace(" ","")
 $PSWD = "$PSWD".Replace("=","")
 $SrcA  = $Src
 $SrcB  = $Src.ToCharArray()

 for ($var = 0; $var -lt $PSWD.length; $var++) {
   $SrcB[$var] = $PSWD[$var]
   $SrcD = $PSWD[$var]
   $SrcA = $SrcA.Replace("$SrcD","")
  }
 
 $j=0
 for ($var = $var; $var -lt 62; $var++) {
   $SrcB[$var] = $SrcA[$j]
   $j++
  }
 $SrcB = "$SrcB".Replace(" ","")

 return "$SrcB"
}

function Replace-TextChars {
    param(
        [string]$sText,
        [string]$sToken,
		[string]$dToken)

    $map = @{}
    $mapE = @{}
    for ($i = 0; $i -lt $sToken.Length; $i++) {
        $map[[byte][char]$sToken[$i]] = [byte][char]$dToken[$i]
		}

    [byte[]]$bytes = [System.Text.Encoding]::UTF8.GetBytes($sText)

	$mapE = ($bytes | ForEach-Object { if ($map.ContainsKey($_)) { $map[$_] } else { $_ } })
	$mapE = [System.Text.Encoding]::UTF8.GetString($mapE)

	Write-Host "   $mapE" -ForegroundColor Cyan
}

function Replace-BinaryChars {
	param([string]$InputFile,
		[string]$OutputFile,
		[string]$SourceChars,
		[string]$DestChars)

	if ($sFORCE -ne "-f"){
		if (Test-Path $OutputFile) { 
			Write-Host "   E: $OutputFile - dest file exist! use -f to overwrite." -ForegroundColor Red;exit 1 }
	}

    $map = @{}
    $mapE = @{}
    for ($i = 0; $i -lt $SourceChars.Length; $i++) {
        $map[[byte][char]$SourceChars[$i]] = [byte][char]$DestChars[$i]
		}

    [byte[]]$bytes = [System.IO.File]::ReadAllBytes($InputFile)

	$mapE = ($bytes | ForEach-Object { if ($map.ContainsKey($_)) { $map[$_] } else { $_ } })

	[System.IO.File]::WriteAllBytes($OutputFile, ($mapE -ne $null ? $mapE : @()))
	#Write-Host "   I: $OutputFile - file eNcrypted!" -ForegroundColor Cyan
	Write-Host "   I: DoNe!" -ForegroundColor Cyan
}

Function Fn_eMsg() {
	Write-Host ""
	Write-Host -ForegroundColor Cyan "*****************************************************"
	Write-Host -ForegroundColor Cyan " - Args: [-f] [-debug] e/d file/folder"
	Write-Host -ForegroundColor Cyan "*****************************************************"
	Write-Host ""
}

function Fn_eAllFiles() {
	Write-Host " - Please enter Password to eNcrypt: " -ForegroundColor Blue -NoNewline
	$PSWD=Read-Host -AsSecureString
	$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))
	$dst = getBaseToken($PSWD);

	Write-Host " - Please enter Password HINT: " -ForegroundColor Blue -NoNewline
	$sHINT=Read-Host
	echo ""
	if ($sHINT -match '[\\/:*?"<>|]') { Write-Host "   E: Hint should not contain any of \ / : * ? "" < > |" -ForegroundColor Red;exit 1 }
	if ($sHINT.Length -eq 0) { $sHINT="_" }
	else { $sHINT = "_"+$sHINT+"_"}

	if ($sDEBUG -eq "-debug"){
		Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
		Write-Host "   D: token: $src" -ForegroundColor Cyan
		Write-Host "   D: token: $dst" -ForegroundColor Cyan
		echo "" }

	$iDATE=date -Format yyyyMMdd_HHmmss
	$iDATE="_"+$iDATE
	$dDir=(Get-Item $sDir).Name
	$dDir=$dDir+$iDATE
	$dDir=(Get-Item $sDir).Parent.FullName+"\"+$dDir+"\"

	Get-ChildItem -Recurse -Force $sDir | where { ! $_.PSIsContainer } | foreach {
		$sPath=($_.Directory.FullName)
		$sFName=($_.FullName)
		$sBName=(Get-Item $_.FullName).BaseName
		$sMD=(Get-FileHash -Path $sFName -Algorithm MD5).Hash
		$sMD = $sHINT+$sMD
		
		$dFName=($_.Name).Replace($sBName,$sBName+$sMD)
		$dFName="$sPath\$dFName"
		$dFName=$dFName.Replace($sDir,$dDir)
		New-Item -ItemType Directory -Force -Path (Split-Path $dFName) | Out-Null

		Write-Host "   I: eNcrypting $sFName" -ForegroundColor Cyan
		Replace-BinaryChars -InputFile "$sFName" -OutputFile "$dFName" -SourceChars $src -DestChars $dst
		echo ""
		}
}

function Fn_dAllFiles() {
	Write-Host " - Please enter Password to dEcrypt: " -ForegroundColor Blue -NoNewline
	$PSWD=Read-Host -AsSecureString
	echo ""
	$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))
	$dst = getBaseToken($PSWD);

	if ($sDEBUG -eq "-debug"){
		Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
		Write-Host "   D: token: $src" -ForegroundColor Cyan
		Write-Host "   D: token: $dst" -ForegroundColor Cyan
		echo "" }

	$dDir=(Get-Item $sDir).Parent.FullName+"\"+(Get-Item $sDir).Name+"_dEcrypt\"

	Get-ChildItem -Recurse -Force $sDir | where { ! $_.PSIsContainer } | foreach {
		$sPath=($_.Directory.FullName)
		$sFName=($_.FullName)
		$sBName=(Get-Item $_.FullName).BaseName
		
		$dFName=($_.Name).Replace($sBName,$sBName)
		$dFName="$sPath\$dFName"

		$dFName=$dFName.Replace($sDir,$dDir)
		New-Item -ItemType Directory -Force -Path (Split-Path $dFName) | Out-Null

		Write-Host "   I: dEcrypting $sFName" -ForegroundColor Cyan
		Replace-BinaryChars -InputFile "$sFName" -OutputFile "$dFName" -SourceChars $dst -DestChars $src

		if ($sBName -match '_[A-Fa-f0-9]{32}$') { $sMD5=$sBName.Substring($sBName.Length - 32) }
			else {$sMD5=$null}

		if ($sMD5 -ne $null) {
				$oData=(Get-FileHash -Path $dFName -Algorithm MD5).Hash
				if ( $oData -eq $sMD5 ) { Write-Host "   I: MD5 checksum validated!" -ForegroundColor Cyan; echo ""}
				else { Write-Host "   E: MD5 checksum validation failed!" -ForegroundColor Red; echo "" }
		}
		else { Write-Host "   W: MD5 checksum validation skipped!" -ForegroundColor DarkYellow; echo ""}
	}

}



if ($args.Count -gt 4) { Fn_eMsg; exit 1 }
for ($i = 0; $i -lt $args.Count; $i++) {
	if ($args[$i] -contains "-debug") { $sDEBUG=$args[$i] }
		elseif ($args[$i] -contains "-f") { $sFORCE=$args[$i] }
			elseif ($args[$i] -contains "e" -or $args[$i] -contains "d") { $sEncDec=$args[$i] }
				elseif ($args[$i] -notmatch '^-') {$sName=$args[$i] }
		}
if ($sName -eq $null) { Fn_eMsg; exit 1 }

sBanner
$src = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

if (Test-Path $sName -PathType Container){
	Write-Host " - Folder detected! " -ForegroundColor Cyan
	$sDir=$sName
	$sDir = (Resolve-Path "$sDir").Path
	switch( $sEncDec) {
		e {Fn_eAllFiles}
		d {Fn_dAllFiles}
		default { Fn_eMsg;exit 1}
	}
} elseif (Test-Path $sName -PathType Leaf) {
	Write-Host " - File detected! " -ForegroundColor Cyan
	$sDir=$sName
	$sDir = (Resolve-Path "$sDir").Path
	switch( $sEncDec) {
		e {	Write-Host " - Please enter Password to eNcrypt: " -ForegroundColor Blue -NoNewline
			$PSWD=Read-Host -AsSecureString
			$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))

			Write-Host " - Please enter Password HINT: " -ForegroundColor Blue -NoNewline
			$sHINT=Read-Host
			echo ""
			if ($sHINT -match '[\\/:*?"<>|]') { Write-Host "   E: Hint should not contain any of \ / : * ? "" < > |" -ForegroundColor Red;exit 1 }
			if ($sHINT.Length -eq 0) { $sHINT="_" }
			else { $sHINT = "_"+$sHINT+"_"}

			$sDirBase = (Get-Item "$sDir").BaseName
			$sMD5=(Get-FileHash -Path $sDir -Algorithm MD5).Hash
			$sMD5=$sDirBase+$sHINT+$sMD5
			$dDir=(Get-Item $sDir).Name.Replace($sDirBase,$sMD5)
			$dDir = (Get-Item $sDir).DirectoryName+"\"+$dDir

			Write-Host "   I: eNcrypting $sDir" -ForegroundColor Cyan
		
			$dst = getBaseToken($PSWD);
			if ($sDEBUG -eq "-debug"){
				Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
				Write-Host "   D: token: $src" -ForegroundColor Cyan
				Write-Host "   D: token: $dst" -ForegroundColor Cyan
				echo "" }
			Replace-BinaryChars -InputFile "$sDir" -OutputFile "$dDir" -SourceChars $src -DestChars $dst
			}
		d {	$sDirBase = (Get-Item "$sDir").BaseName
			if ($sDirBase -match '_[A-Fa-f0-9]{32}$') { $sMD5=$sDirBase.Substring($sDirBase.Length - 32) }
				else {$sMD5=$null}

			$dDir=(Get-Item $sDir).Name.Replace($sDirBase,$sDirBase+"_dEcrtypt")
			$dDir = (Get-Item $sDir).DirectoryName+"\"+$dDir

			Write-Host " - Please enter Password to dEcrypt: " -ForegroundColor Blue -NoNewline
			$PSWD=Read-Host -AsSecureString
			echo ""
			$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))

			$dst = getBaseToken($PSWD);
			if ($sDEBUG -eq "-debug"){
				Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
				Write-Host "   D: token: $src" -ForegroundColor Cyan
				Write-Host "   D: token: $dst" -ForegroundColor Cyan
				echo "" }
			Write-Host "   I: dEcrypting $sDir" -ForegroundColor Cyan
			Replace-BinaryChars -InputFile "$sDir" -OutputFile "$dDir" -SourceChars $dst -DestChars $src
			
			if ($sMD5 -ne $null) { $oData=(Get-FileHash -Path $dDir -Algorithm MD5).Hash
				if ( $oData -eq $sMD5 ) { Write-Host "   I: MD5 checksum validated!" -ForegroundColor Cyan; echo "" }
				else { Write-Host "   E: MD5 checksum validation failed!" -ForegroundColor Red; echo "" }
				}
			else { Write-Host "   W: MD5 checksum validation skipped!" -ForegroundColor DarkYellow; echo ""}
			}
	    default { Fn_eMsg;exit 1}
	}
 } else {	# no file or folder. treat $sName as string.
		switch( $sEncDec) {
		e {	Write-Host " - Please enter Password to eNcrypt: " -ForegroundColor Blue -NoNewline
			$PSWD=Read-Host -AsSecureString
			$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))
			$dst = getBaseToken($PSWD);
			if ($sDEBUG -eq "-debug"){
				Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
				Write-Host "   D: token: $src" -ForegroundColor Cyan
				Write-Host "   D: token: $dst" -ForegroundColor Cyan
				echo "" }
			Replace-TextChars $sName $src $dst }
		d {	Write-Host " - Please enter Password to dEcrypt: " -ForegroundColor Blue -NoNewline
			$PSWD=Read-Host -AsSecureString
			echo ""
			$PSWD=[Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($PSWD))
			$dst = getBaseToken($PSWD);
			if ($sDEBUG -eq "-debug"){
				Write-Host "   D: paswd: $PSWD" -ForegroundColor Cyan
				Write-Host "   D: token: $src" -ForegroundColor Cyan
				Write-Host "   D: token: $dst" -ForegroundColor Cyan
				echo "" }
			Replace-TextChars $sName $dst $src }
		default { Fn_eMsg;exit 1} }
}








exit 0
##########################################################################
#########################################################################
$dg_A=@"
██████  ██    ██ ████████ ███████  ███╗   ███╗ ██████╗ ██████╗ ██████╗ ██╗  ██╗
██   ██  ██  ██     ██    ██       ████╗ ████║██╔═══██╗██╔══██╗██╔══██╗██║  ██║
██████    ████      ██    █████    ██╔████╔██║██║   ██║██████╔╝██████╔╝███████║
██   ██    ██       ██    ██       ██║╚██╔╝██║██║   ██║██╔══██║██╔═══╝ ██╔══██║
██████     ██       ██    ███████  ██║ ╚═╝ ██║╚██████╔╝██║  ██║██║     ██║  ██║
                                   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝
"@

Write-Host @"                                         
 ____   __     __  _______  ______    __  __    ____    ____    ____    _    _ 
|  _ \  \ \   / / |__   __||  ____|  |  \/  |  / __ \  |  _ \  |  _ \  | |  | | 
| |_) |  \ \_/ /     | |   | |__     | \  / | | |  | | | |_) | | |_) | | |__| | 
|  _ <    \   /      | |   |  __|    | |\/| | | |  | | |  __/  |  __/  |  __  | 
| |_) |    | |       | |   | |____   | |  | | | |__| | | |\ \  | |     | |  | | 
|____/     |_|       |_|   |______|  |_|  |_|  \____/  |_| \_\ |_|     |_|  |_| 
"@                                                                     


Write-Host -ForegroundColor Cyan @"                                         

██████  ██    ██ ████████ ███████     ███    ███  ██████  ██████  ██████  ██   ██
██   ██  ██  ██     ██    ██          ████  ████ ██    ██ ██   ██ ██   ██ ██   ██
██████    ████      ██    █████       ██ ████ ██ ██    ██ ██████  ██████  ███████
██   ██    ██       ██    ██          ██  ██  ██ ██    ██ ██   ██ ██      ██   ██
██████     ██       ██    ███████     ██      ██  ██████  ██   ██ ██      ██   ██

"@




Write-Host -ForegroundColor Cyan @"                                         

██████  ██    ██ ████████ ███████  ███╗   ███╗ ██████╗ ██████╗ ██████╗ ██╗  ██╗
██   ██  ██  ██     ██    ██       ████╗ ████║██╔═══██╗██╔══██╗██╔══██╗██║  ██║
██████    ████      ██    █████    ██╔████╔██║██║   ██║██████╔╝██████╔╝███████║
██   ██    ██       ██    ██       ██║╚██╔╝██║██║   ██║██╔══██║██╔═══╝ ██╔══██║
██████     ██       ██    ███████  ██║ ╚═╝ ██║╚██████╔╝██║  ██║██║     ██║  ██║
                                   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝
"@

