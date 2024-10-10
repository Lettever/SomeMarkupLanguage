A markup language that i am creating for fun

===

start = value

value = number | string | "{" (key "=" value)* "}" | "[" value* "]"

number = "[-+]"? numberLiteral

key = (string | identifier) ('.' (string | identifier))*