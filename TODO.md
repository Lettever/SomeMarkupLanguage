when parsing string handles special characters and non-raw strings
right now it only handles raw strings
keep track of the collum and line do better error handling
only need to update lines when str[i].isWhite() and when parsing strings

test the parsing function
the parse key function should return an array of string so that a.b = 10 == { "a": { "b": 10 } }