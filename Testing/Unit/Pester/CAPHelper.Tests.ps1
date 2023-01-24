BeforeAll {
    $ClassPath = "$($PSScriptRoot)/../../../PowerShell/ScubaGear/Modules/Providers/ProviderHelpers/"
    Import-Module $ClassPath/AADConditionalAccessHelper.psm1
    $CapHelper = Get-CapTracker
    $CapHelper | Out-Null # Pointless line that makes the PS linter happy
}

Describe "GetIncludedUsers" {
    It "returns 'None' when no users are included" {
        $Cap = Get-Content "CapSnippets/Users_sample01.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "None"
	}

    It "handles including single users" {
        $Cap = Get-Content "CapSnippets/Users_sample02.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user"
	}

    It "handles including multiple users" {
        $Cap = Get-Content "CapSnippets/Users_sample03.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific users"
	}

    It "handles including single groups" {
        $Cap = Get-Content "CapSnippets/Users_sample04.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific group"
	}

    It "handles including multiple groups" {
        $Cap = Get-Content "CapSnippets/Users_sample05.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific groups"
	}

    It "handles including single roles" {
        $Cap = Get-Content "CapSnippets/Users_sample06.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific role"
	}

    It "handles including multiple roles" {
        $Cap = Get-Content "CapSnippets/Users_sample07.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific roles"
	}

    It "handles including users, groups, and roles simultaneously" {
        $Cap = Get-Content "CapSnippets/Users_sample08.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user, 2 specific roles, 3 specific groups"
	}

    It "returns 'All' when all users are included" {
        $Cap = Get-Content "CapSnippets/Users_sample09.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "All"
	}

    It "handles including single type of external user" {
        $Cap = Get-Content "CapSnippets/Users_sample10.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "Local guest users"
	}

    It "handles including all types of guest users" {
        $Cap = Get-Content "CapSnippets/Users_sample11.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "B2B collaboration guest users, B2B collaboration member users, B2B direct connect users, Local guest users, Service provider users, Other external users"
	}
}

Describe "GetExcludedUsers" {
    It "returns 'None' when no users are included" {
        $Cap = Get-Content "CapSnippets/Users_sample01.json" | ConvertFrom-Json
        $UsersExcluded = $($CapHelper.GetIncludedUsers($Cap)) -Join ", "
        $UsersExcluded | Should -Be "None"
	}

    It "handles excluding single users" {
        $Cap = Get-Content "CapSnippets/Users_sample02.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user"
	}

    It "handles excluding multiple users" {
        $Cap = Get-Content "CapSnippets/Users_sample03.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific users"
	}

    It "handles excluding single groups" {
        $Cap = Get-Content "CapSnippets/Users_sample04.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific group"
	}

    It "handles excluding multiple groups" {
        $Cap = Get-Content "CapSnippets/Users_sample05.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific groups"
	}

    It "handles excluding single roles" {
        $Cap = Get-Content "CapSnippets/Users_sample06.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific role"
	}

    It "handles excluding multiple roles" {
        $Cap = Get-Content "CapSnippets/Users_sample07.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "2 specific roles"
	}

    It "handles excluding users, groups, and roles simultaneously" {
        $Cap = Get-Content "CapSnippets/Users_sample08.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "1 specific user, 2 specific roles, 3 specific groups"
	}

    It "handles excluding all types of external users" {
        $Cap = Get-Content "CapSnippets/Users_sample09.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "B2B collaboration guest users, B2B collaboration member users, B2B direct connect users, Local guest users, Service provider users, Other external users"
	}

    It "handles excluding a single type of external user" {
        $Cap = Get-Content "CapSnippets/Users_sample10.json" | ConvertFrom-Json
        $UsersIncluded = $($CapHelper.GetExcludedUsers($Cap)) -Join ", "
        $UsersIncluded | Should -Be "Service provider users"
	}
}

Describe "GetApplications" {
    It "handles including all apps" {
        $Cap = Get-Content "CapSnippets/Apps_sample01.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: All"
        $Apps[2] | Should -Be "Apps excluded: None"
	}

    It "handles including/excluding no apps" {
        $Cap = Get-Content "CapSnippets/Apps_sample02.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: None"
        $Apps[2] | Should -Be "Apps excluded: None"
	}

    It "handles including/excluding single specific apps" {
        $Cap = Get-Content "CapSnippets/Apps_sample03.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: 1 specific app"
        $Apps[2] | Should -Be "Apps excluded: 1 specific app"
	}

    It "handles including/excluding multiple specific apps" {
        $Cap = Get-Content "CapSnippets/Apps_sample04.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: apps"
        $Apps[1] | Should -Be "Apps included: 3 specific apps"
        $Apps[2] | Should -Be "Apps excluded: 2 specific apps"
	}

    It "handles registering a device" {
        $Cap = Get-Content "CapSnippets/Apps_sample05.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: actions"
        $Apps[1] | Should -Be "User action: Register or join devices"
	}

    It "handles registering security info" {
        $Cap = Get-Content "CapSnippets/Apps_sample06.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps[0] | Should -Be "Policy applies to: actions"
        $Apps[1] | Should -Be "User action: Register security info"
	}

    It "handles registering security info" {
        $Cap = Get-Content "CapSnippets/Apps_sample07.json" | ConvertFrom-Json
        $Apps = $($CapHelper.GetApplications($Cap))
        $Apps | Should -Be "Policy applies to: 2 authentication contexts"
	}
}

Describe "GetConditions" {
    It "handles user risk levels" {
        $Cap = Get-Content "CapSnippets/Conditions_sample01.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "User risk levels: high, medium, low"
	}

    It "handles sign-in risk levels" {
        $Cap = Get-Content "CapSnippets/Conditions_sample02.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Sign-in risk levels: low"
	}

    It "handles including all device platforms" {
        $Cap = Get-Content "CapSnippets/Conditions_sample03.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Device platforms included: all"
        $Conditions[1] | Should -Be "Device platforms excluded: none"
    }

    It "handles including/excluding specific device platforms" {
        $Cap = Get-Content "CapSnippets/Conditions_sample04.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Device platforms included: android"
        $Conditions[1] | Should -Be "Device platforms excluded: iOS, macOS, linux"
    }

    It "handles including all locations" {
        $Cap = Get-Content "CapSnippets/Conditions_sample05.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all locations"
        $Conditions[1] | Should -Be "Locations excluded: none"
    }

    It "handles excluding trusted locations" {
        $Cap = Get-Content "CapSnippets/Conditions_sample06.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all locations"
        $Conditions[1] | Should -Be "Locations excluded: all trusted locations"
    }

    It "handles including/excluding single custom locations" {
        $Cap = Get-Content "CapSnippets/Conditions_sample07.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: 1 specific location"
        $Conditions[1] | Should -Be "Locations excluded: 1 specific location"
    }

    It "handles including/excluding multiple custom locations" {
        $Cap = Get-Content "CapSnippets/Conditions_sample08.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: 2 specific locations"
        $Conditions[1] | Should -Be "Locations excluded: 3 specific locations"
    }

    It "handles including trusted locations" {
        $Cap = Get-Content "CapSnippets/Conditions_sample09.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "Locations included: all trusted locations"
        $Conditions[1] | Should -Be "Locations excluded: none"
    }

    It "handles including all client apps" {
        $Cap = Get-Content "CapSnippets/Conditions_sample09.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[2] | Should -Be "Client apps included: all"
    }

    It "handles including specific client apps" {
        $Cap = Get-Content "CapSnippets/Conditions_sample10.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions | Should -Be "Client apps included: Exchange ActiveSync Clients, Browser, Mobile apps and desktop clients, Other clients"
    }

    It "handles custom client app filter in include mode" {
        $Cap = Get-Content "CapSnippets/Conditions_sample11.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[1] | Should -Be "Custom device filter in include mode active"
    }

    It "handles custom client app filter in exclude mode" {
        $Cap = Get-Content "CapSnippets/Conditions_sample12.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[1] | Should -Be "Custom device filter in exclude mode active"
    }

    It "handles many conditions simultaneously" {
        $Cap = Get-Content "CapSnippets/Conditions_sample13.json" | ConvertFrom-Json
        $Conditions = $($CapHelper.GetConditions($Cap))
        $Conditions[0] | Should -Be "User risk levels: low"
        $Conditions[1] | Should -Be "Sign-in risk levels: high"
        $Conditions[2] | Should -Be "Device platforms included: all"
        $Conditions[3] | Should -Be "Device platforms excluded: android, iOS, macOS, linux"
        $Conditions[4] | Should -Be "Locations included: all trusted locations"
        $Conditions[5] | Should -Be "Locations excluded: none"
        $Conditions[6] | Should -Be "Client apps included: Exchange ActiveSync Clients"
        $Conditions[7] | Should -Be "Custom device filter in exclude mode active"
    }
}

Describe "GetAccessControls" {

}

Describe "GetSessionControls" {

}

Describe "ExportCapPolicies" {

}

# TODO Test what happens when there are missing values / simulate API changes