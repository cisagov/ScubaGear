package policy.utils
import future.keywords

IsEmptyContainer(null) := true
IsEmptyContainer(container) := true if {
    Temp := {Item | Item := container[_]}
    count(Temp) == 0
}

IsAllUsers(null) := false
IsAllUsers(array) := true if {
    not IsEmptyContainer(array)
    "All" in array
} else := false {true}

Contains(null, _) := false
Contains(array, item) := true if {
    not IsEmptyContainer(array)
    item in array
} else := false {
    true
}

Count(null) := 0
Count(container) := Result if {
    not IsEmptyContainer(container)
    Result := count(container)
} else := 0 {
    true
}
