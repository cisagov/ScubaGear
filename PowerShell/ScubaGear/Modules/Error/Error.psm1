using module '..\ScubaConfig\ScubaConfig.psm1'

function Resolve-Error ($E) #($ErrorRecord=$Error[0]) #$ErrorRecord.InvocationInfo.PositionMessage #$_
{
    $E | Format-List * -Force
    $E.InvocationInfo |Format-List *
    $Exception = $E.Exception
    if ((Get-Member -InputObject $E -Name ScriptStackTrace) -ne $null)
    {
        Write-Warning $E.ScriptStackTrace
    }

    else
    {
        Get-PSCallStack | Select -Skip 0 | % {
        Write-Warning $E.Command $E.Location $(if ($E.Arguments.Length -le 80) { $E.Arguments })
        }
    }

    for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
    {
        "-" * 80
        $Exception |Format-List * -Force
    }
}

