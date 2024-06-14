function Get-Planet ([string]$Name = '*') {
    $planets = @(
        @{ Name = 'Mercury' }
        @{ Name = 'Venus'   }
        @{ Name = 'Earth'   }
        @{ Name = 'Mars'    }
        @{ Name = 'Jupiter' }
        @{ Name = 'Saturn'  }
        @{ Name = 'Uranus'  }
        @{ Name = 'Neptune' }
    ) | ForEach-Object { [PSCustomObject] $_ }

    $planets | Where-Object { $_.Name -like $Name }
}

Export-ModuleMember -Function @(
   'Get-Planet'
)