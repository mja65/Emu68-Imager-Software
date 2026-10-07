function Test-ArchiveFileType {
	param (
		[Parameter(Mandatory = $true)]
		[string]$Path
	)

	if (-not [System.IO.File]::Exists($Path)) {
		return $false
	}

	$Extension = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
	if ($Extension -notin @('.lha', '.lzx', '.zip')) {
		return $true
	}

	$Header = New-Object byte[] 7
	$Stream = [System.IO.File]::OpenRead($Path)
	try {
		$BytesRead = $Stream.Read($Header, 0, $Header.Length)
	}
	finally {
		$Stream.Dispose()
	}

	switch ($Extension) {
		'.lha' {
			if ($BytesRead -lt 7) {
				return $false
			}
			$Method = [System.Text.Encoding]::ASCII.GetString($Header, 2, 5)
			return $Method -cmatch '^-(lh[0-7d]|lz[45s]|pm[02])-$'
		}
		'.lzx' {
			return $BytesRead -ge 3 -and [System.Text.Encoding]::ASCII.GetString($Header, 0, 3) -ceq 'LZX'
		}
		'.zip' {
			if ($BytesRead -lt 4 -or $Header[0] -ne 0x50 -or $Header[1] -ne 0x4b) {
				return $false
			}
			return ($Header[2] -eq 0x03 -and $Header[3] -eq 0x04) -or
				   ($Header[2] -eq 0x05 -and $Header[3] -eq 0x06) -or
				   ($Header[2] -eq 0x07 -and $Header[3] -eq 0x08)
		}
	}
}
