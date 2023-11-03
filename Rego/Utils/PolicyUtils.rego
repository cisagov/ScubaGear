package utils.policy
import future.keywords

IsEmptyContainer(null) := true

IsEmptyContainer(container) := true if {
    Temp := {Item | some Item in container}
    count(Temp) == 0
} else := false

IsAllUsers(null) := false

IsAllUsers(array) := true if {
    not IsEmptyContainer(array)
    "All" in array
} else := false

Contains(null, _) := false

Contains(array, item) := true if {
    not IsEmptyContainer(array)
    item in array
} else := false

Count(null) := 0

Count(Container) := count(Container) if {
    not IsEmptyContainer(Container)
} else := 0
