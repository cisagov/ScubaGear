# METADATA
# description: Utility functions for working with Rego unit tests
# authors:
#   - Anders Eknert <anders@eknert.com>
#
package test.assert

import rego.v1

# METADATA
# description: Assert expected is equal to result
Equals(expected, result) if {
    expected == result
    # regal ignore: print-or-trace-call
    print("PASS: expected equals '", expected, "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected equals '", expected, "', got '", result, "'\n")
}

# METADATA
# description: Assert expected is not equal to result
NotEquals(expected, result) if {
    expected != result
    # regal ignore: print-or-trace-call
    print("PASS: expected not equals '", expected, "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected not equals '", expected, "', got '", result, "'\n")
}

# METADATA
# description: Assert all items in coll are equal to value
AllEquals(coll, value) if {
    every item in coll {
        item == value
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected all items to have value '", _AppendComma(value), "'\n")
} else := false if {
    exceptions := [item | some item in coll; item != value]
    # regal ignore: print-or-trace-call
    print("FAIL: expected all items to have value '", _AppendComma(value), "', failed for '", exceptions, "'\n")
}

# METADATA
# description: Assert no items in coll are equal to value
NoneEquals(coll, value) if {
    every item in coll {
        item != value
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected no items to have value '", _AppendComma(value), "'\n")
} else := false if {
    exceptions := [item | some item in coll; item == value]
    # regal ignore: print-or-trace-call
    print("FAIL: expected no items to have value '", _AppendComma(value), "', failed for '", exceptions, "'\n")
}

# METADATA
# description: Assert item is in coll
Has(item, coll) if {
    item in coll
    # regal ignore: print-or-trace-call
    print("PASS: expected", type_name(item), _QuoteStr(item), "in", type_name(coll), "\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected", type_name(item), _QuoteStr(item), "in", type_name(coll), "got '", coll, "'\n")
}

# METADATA
# description: Assert item is not in coll
NotHas(item, coll) if {
    not item in coll
    # regal ignore: print-or-trace-call
    print("PASS: did not expect", type_name(item), _QuoteStr(item), "in", type_name(coll), "\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: did not expect", type_name(item), _QuoteStr(item), "in", type_name(coll), "got '", coll, "'\n")
}

# METADATA
# description: Assert provided collection is empty
Empty(coll) if {
    count(coll) == 0
    # regal ignore: print-or-trace-call
    print("PASS: expected empty", type_name(coll), "\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected empty", type_name(coll), "got '", coll, "'\n")
}

# METADATA
# description: Assert provided collection is not empty
NotEmpty(coll) if {
    count(coll) != 0
    # regal ignore: print-or-trace-call
    print("PASS: expected not empty", type_name(coll))
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected not empty", type_name(coll))
}

# METADATA
# description: Assert string starts with search
StartsWith(str, search) if {
    startswith(str, search)
    # regal ignore: print-or-trace-call
    print("PASS: expected '", _QuoteStr(str), "' to start with '", _QuoteStr(search), "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected '", _QuoteStr(str), "' to start with '", _QuoteStr(search), "'\n")
}

# METADATA
# description: Assert string ends with search
EndsWith(str, search) if {
    endswith(str, search)
    # regal ignore: print-or-trace-call
    print("PASS: expected '", _QuoteStr(str), "' to end with '", _QuoteStr(search), "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected '", _QuoteStr(str), "' to end with '", _QuoteStr(search), "'\n")
}

# METADATA
# description: Assert string starts with search
DoesContains(str, search) if {
    contains(str, search)
    # regal ignore: print-or-trace-call
    print("PASS: expected '", _QuoteStr(str), "' to contain '", _QuoteStr(search), "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected '", _QuoteStr(str), "' to contain '", _QuoteStr(search), "'\n")
}

# METADATA
# description: Assert string ends with search
NotContains(str, search) if {
    not contains(str, search)
    # regal ignore: print-or-trace-call
    print("PASS: expected '", _QuoteStr(str), "' to not contain '", _QuoteStr(search), "'\n")
} else := false if {
    # regal ignore: print-or-trace-call
    print("FAIL: expected '", _QuoteStr(str), "' to not contain '", _QuoteStr(search), "'\n")
}

# METADATA
# description: Assert all strings in coll starts with search
AllStartsWith(coll, search) if {
    every str in coll {
        startswith(str, search)
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected all strings to start with '", _AppendComma(search), "'\n")
} else := false if {
    exceptions := [str | some str in coll; not startswith(str, search)]
    # regal ignore: print-or-trace-call
    print("FAIL: expected all strings to start with '", _AppendComma(search), "' failed for '", exceptions, "'\n")
}

# METADATA
# description: Assert all strings in coll ends with search
AllEndsWith(coll, search) if {
    every str in coll {
        endswith(str, search)
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected all strings to end with '", _AppendComma(search), "'\n")
} else := false if {
    exceptions := [str | some str in coll; not endswith(str, search)]
    # regal ignore: print-or-trace-call
    print("FAIL: expected all strings to end with '", _AppendComma(search), "' failed for '", exceptions, "'\n")
}

# METADATA
# description: Assert no strings in coll starts with search
NoneStartsWith(coll, search) if {
    every str in coll {
        not startswith(str, search)
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected no strings to start with '", _AppendComma(search), "'\n")
} else := false if {
    exceptions := [str | some str in coll; startswith(str, search)]
    # regal ignore: print-or-trace-call
    print("FAIL: expected no strings to start with '", _AppendComma(search), "' failed for '", exceptions, "'\n")
}

# METADATA
# description: Assert no strings in coll ends with search
NoneEndsWith(coll, search) if {
    every str in coll {
        not endswith(str, search)
    }
    # regal ignore: print-or-trace-call
    print("PASS: expected no strings to end with '", _AppendComma(search), "'\n")
} else := false if {
    exceptions := [str | some str in coll; endswith(str, search)]
    # regal ignore: print-or-trace-call
    print("FAIL: expected no strings to end with '", _AppendComma(search), "' failed for '", exceptions, "'\n")
}

# METADATA
# description: Fail with provided message
# regal ignore: print-or-trace-call
Fail(msg) := [][0] if print(msg)

_QuoteStr(x) := concat("", [`"`, x, `"`]) if is_string(x)

_QuoteStr(x) := x if not is_string(x)

_AppendComma(str) := sprintf("%v,", [_QuoteStr(str)])