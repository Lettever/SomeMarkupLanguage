A markup language that i am creating for fun

After every number, string, or identifier, there must be either a whitespace, a closing bracket, a closing brace, or the end of the file

===


start = WhiteSpace | value

value = number | string | "{" (key "=" value)* "}" | "[" value* "]"

number = "[-+]"? numberLiteral

key = (string | identifier) ('.' (string | identifier))*