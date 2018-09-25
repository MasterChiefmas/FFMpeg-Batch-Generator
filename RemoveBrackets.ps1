Function RemoveBrackets(){
    get-childitem | ForEach-Object {
        Write-Host "Checking $_"
        If ($_.Name -Match "\["){
            Write-Host -ForegroundColor Yellow "Removing left bracket from $_.name"
            Move-Item -LiteralPath $_.name $_.name.Replace("[","(")
        }
    }

    get-childitem | ForEach-Object {
        Write-Host "Checking $_"
        If ($_.Name -Match "\]"){
            Write-Host -ForegroundColor Yellow "Removing right bracket from $_.name"
            Move-Item -LiteralPath $_.name $_.name.Replace("]",")")
        }
    }
}