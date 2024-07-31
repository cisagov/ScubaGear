# Rego Cheat Sheet <!-- omit in toc -->

## Language Building Blocks

### Input

```Json
{
    "servers": [
        {"id": "app", "protocols": ["https", "ssh"], "ports": ["p1", "p2", "p3"]},
        {"id": "db", "protocols": ["mysql"], "ports": ["p3"]},
        {"id": "cache", "protocols": ["memcache"], "ports": ["p3"]},
        {"id": "ci", "protocols": ["http"], "ports": ["p1", "p2"]},
        {"id": "busybox", "protocols": ["telnet"], "ports": ["p1"]}
    ]
}
```

```Rego
    input.servers[0] == {"id": "app", "protocols": ["https", "ssh"], "ports": ["p1", "p2", "p3"]}
    input.servers[0].ports == ["p1", "p2", "p3"]
    input.servers[0].ports[1] == "p2"
```

### Variables

#### Scalar <!-- omit in toc -->

```Rego
Greeting := "Hello"
MaxHeight := 42
Pi := 3.14159
Allowed := true
Location := null
```

#### Composite <!-- omit in toc -->

##### Array

```Rego
Names := ["Jane", "Steve", "Harriet", "Rob"]
```

1. concat(delimiter, array)
2. reverse(array)
3. slice(array, start, stop)

##### Set

```Rego
Cuboid := {"width": 3, "height": 4, "depth": 5, "example_var": 6, "second ex": 7, "third.ex": 8}
```

1. &
2. intersection(set[set])
3. -
4. |
5. union(set[set])

### Comparisons

```Rego
Greeting := "Hello"
Allowed := true
Cuboid := {"width": 3, "height": 4, "depth": 5, "example_var": 6, "second ex": 7, "third.ex": 8}
Names := ["Jane", "Steve", "Harriet", "Rob"]

Greeting == "Hello"
Allowed
Allowed == true

Cuboid.width == 3
Cuboid.example_var == 6
Cuboid["second ex"] == 7
Cuboid["third.ex"] == 8
"Jane" in Names
Names[0] == "Jane"

Greeting != "Hello"
not Allowed
Allowed == false

not "Jane" in Names
not Names[0] == "Jane"

Cuboid.width > 3
Cuboid.width < 3
Cuboid.width >= 3
Cuboid.width <= 3
Cuboid.width != 3
```

### Keywords

1. in
2. not
3. if
4. else
5. contains
6. every
7. some
8. default
9. with

## Loops & Conditionals

### Loops

```Json
{
    "servers": [
        {"id": "app", "protocols": ["https", "ssh"], "ports": ["p1", "p2", "p3"]},
        {"id": "db", "protocols": ["mysql"], "ports": ["p3"]},
        {"id": "cache", "protocols": ["memcache"], "ports": ["p3"]},
        {"id": "ci", "protocols": ["http"], "ports": ["p1", "p2"]},
        {"id": "busybox", "protocols": ["telnet"], "ports": ["p1"]}
    ]
}
```

1. Wildcard

    ```Rego
        input.servers[_]
    ```

2. Some

    ```Rego
        some i
        input.servers[i]
    ```

3. Some in

    ```Rego
        some server in input.servers
    ```

### Rule Sets

```Rego
default ScalarRuleSet := false

ScalarRuleSet := true if {
    some server in input.servers
    "p1" in server.ports
}
```

```Rego
CompositeRuleSet contains server.id if {
    some server in input.servers
    "p1" in server.ports
}
```

### Comprehensions

```Rego
SetExample := {server.id | some server in input.servers; "p1" in server.ports}

ArrayExample := [server.id | some server in input.servers; "p1" in server.ports]
```

## Important Functions

01. count(composite)
02. max(composite)
03. min(composite)
04. product(composite)
05. sum(composite)
06. sort(composite)
07. abs(float)
08. ceil(float)
09. floor(float)
10. round(float)
11. range(min, max)
12. range_step(min, max, step)
13. contains(string, substring)
14. startswith(string, substring)
15. endswith(string, substring)
16. indexof(string, substring)
17. indexof_n(string, substring)
18. format_int(number, base)
19. lower(string)
20. upper(string)
21. replace(string, regex, new_substring)
22. split(string, delimiter)
23. reverse(string)
24. trim(string, delimiter)
25. trim_space(string)
