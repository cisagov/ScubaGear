# This trivial PS file is for unit testing.
# It intentionally violates PSSA rules.

# Unnecessary Use of Backticks
$myVariable = `
  "Hello World"
# Using Aliases Instead of Full Cmdlet Names
ls | ? {$_.Name -like "*txt"}
