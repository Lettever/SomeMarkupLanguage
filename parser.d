import std.stdio;
import std.algorithm;
import std.conv;
import std.ascii;

enum TokenType {
    Plus,
    Minus,
    Dot,
    Equals,
    
    True,
    False,
    Null,
    
    String,
    Number,
    Identifier,
    
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    
    WhiteSpace,
}
private enum TokenTypeMap = [
    '+': TokenType.Plus,
    '-': TokenType.Minus,
    '.': TokenType.Dot,
    '=': TokenType.Equals,
    '[': TokenType.LeftBracket,
    ']': TokenType.RightBracket,
    '{': TokenType.LeftBrace,
    '}': TokenType.RightBrace,
];
private enum TokenTypeMapKeyword = [
    "true": TokenType.True,
    "false": TokenType.False,
    "null": TokenType.Null
];

struct Token {
    TokenType type;
    string span;
}

void main() {
	string test = `a = 10 b= 123c="abc" d.e-f."g.h"=true truef false null
    nullfalse[false{null]true}"abc"`;
	writeln(test);
	auto b = lex(test);
	
	//b.each!writeln;
}
/*
    TODO:
        add suport for hexadecimal, octal and binary numbers
        when parsing string handles special characters and non-raw strings
        right now it only handles raw strings
        parseString could fail if the string isnt closed
        do better error handling
*/
Token[] lex(string str) {
    ulong i = 0, len = str.length, line = 1;
    Token[] tokens = [];
    //static immutable keywords = ["true", "false", "null"];
    void addTokenAndAdvance(TokenType type, string text) {
        tokens ~= Token(type, text);
        i += text.length;
    }
    
    while (i < len) {
        char ch = str[i];
        if (ch in TokenTypeMap) {
            addTokenAndAdvance(TokenTypeMap[ch], ch.to!(string));
        } else if (ch.isAlpha()) {
            string parsedIdentifier = parseIdentifier(str, i);
            addTokenAndAdvance(TokenTypeMapKeyword.get(parsedIdentifier, TokenType.Identifier), parsedIdentifier);
        } else if (ch.isDigit()) {
            string parsedNumber = parseNumber(str, i);
            addTokenAndAdvance(TokenType.Number, parsedNumber);
        } else if (ch == '"') {
            string parsedString = parseString(str, i);
            addTokenAndAdvance(TokenType.String, parsedString);
        } else if (ch.isWhite()) {
            if (tokens.length > 0 && tokens[$ - 1].type != TokenType.WhiteSpace) {
                addTokenAndAdvance(TokenType.WhiteSpace, "");
            }
            if (ch == '\n') {
                line += 1;
            }
            i += 1;
        } else {
            writefln("i: %s, ch: %s", i, ch);
            i += 1;
        }
    }
    return tokens;
}
bool matchesAtIndex(string haystack, string needle, ulong i) {
    if (i + needle.length > haystack.length) {
        return false;
    }
    return needle == haystack[i .. i + needle.length];
}
string parseIdentifier(string str, ulong i) {
    ulong j = i + 1, len = str.length;
    while (j < len && (str[j].isAlphaNum() || str[j] == '_' || str[j] == '-')) {
        j += 1;
    }
    return str[i .. j];
}
string parseNumber(string str, ulong i) {
    ulong j = i + 1, len = str.length;
    while(j < len && str[j].isDigit()) {
        j += 1;
    }
    return str[i .. j];
    /*
    string s = "10F";
	auto a = parse!(int)(s, 16);
	writeln(a);
	writeln(s);
    */
}
string parseString(string str, ulong i) {
    ulong j = i + 1, len = str.length;
    while(j < len && (str[j] != '"')) {
        j += 1;
    }
    if (j == len) {
        writeln("unclosed string");
    }
    j += 1;
    return str[i .. j];
}
