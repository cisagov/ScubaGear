package utils.policy
import future.keywords

# Checks if set/array is null or empty
IsEmptyContainer(null) := true

IsEmptyContainer(container) := true if {
    Temp := {Item | some Item in container}
    count(Temp) == 0
} else := false

# Check if "All" is in the array
IsAllUsers(null) := false

IsAllUsers(array) := true if {
    not IsEmptyContainer(array)
    "All" in array
} else := false

# Check if string is in array
Contains(null, _) := false

Contains(array, item) := true if {
    not IsEmptyContainer(array)
    item in array
} else := false

# Returns size of set/array
Count(null) := 0

Count(Container) := count(Container) if {
    not IsEmptyContainer(Container)
} else := 0
