param(
  [string]$WorkDir = "F:\tkz-elements-main\doc\latex-zh",
  [int]$Passes = 3
)
$env:TEXINPUTS = "F:\tkz-elements-main\latex-zh;"
$env:LUAINPUTS = "F:\tkz-elements-main\latex-zh;"
Push-Location $WorkDir
try {
  Write-Host "=== Pass 1 start: $(Get-Date -Format 'HH:mm:ss') ==="
  & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
  Write-Host "pass1 exit=$LASTEXITCODE  $(Get-Date -Format 'HH:mm:ss')"
  if (Test-Path -LiteralPath "TKZdoc-elements-main.idx") {
    & makeindex -q TKZdoc-elements-main.idx
    Write-Host "makeindex exit=$LASTEXITCODE"
  }
  for ($i = 2; $i -le $Passes; $i++) {
    Write-Host "=== Pass $i start: $(Get-Date -Format 'HH:mm:ss') ==="
    & lualatex -interaction=nonstopmode -file-line-error TKZdoc-elements-main.tex
    Write-Host "pass$i exit=$LASTEXITCODE  $(Get-Date -Format 'HH:mm:ss')"
  }
  Write-Host "=== ALL DONE $(Get-Date -Format 'HH:mm:ss') ==="
} finally {
  Pop-Location
}
