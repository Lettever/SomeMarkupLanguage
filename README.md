A markup language that i am creating for fun
===
<p>start = WhiteSpace | value</p>
<p>value = number | string | "{" (key "=" value)* "}" | "[" value* "]"</p>
<p>number = "[-+]"? numberLiteral</p>
<p>key = (string | identifier) ('.' (string | identifier))*</p>
