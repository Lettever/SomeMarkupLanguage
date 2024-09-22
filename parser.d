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
}
private enum TokenTypeMap = [
    '+': TokenType.Plus,
    '-': TokenType.Minus,
    '.': TokenType.Dot,
    '=': TokenType.Equals,
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
import std.stdio;
import std.conv;
import std.ascii;
import std.algorithm;

void main() {
	string test = `a = 10 b= 123c="abc" d.e-f."g.h"=true truef false null nullfalse`;
	writeln(test);
	auto b = lex(test);
	b.each!writeln;
}
/*
    TODO:
        add suport for hexadecimal, octal and binary numbers
        when parsing string handles special characters and raw strings
*/
Token[] lex(string str) {
    ulong i = 0, len = str.length;
    Token[] tokens = [];
    static immutable keywords = ["true", "false", "null"];
    void addTokenAndAdvance(TokenType type, string text) {
        tokens ~= Token(type, text);
        i += text.length;
    }
    
    while (i < len) {
        char ch = str[i];
        if (ch in TokenTypeMap) {
            addTokenAndAdvance(TokenTypeMap[ch], ch.to!(string));
        } else if (ch.isAlpha()) {
            ulong j = i + 1;
            while (j < len && (str[j].isAlphaNum() || str[j] == '_' || str[j] == '-')) {
                j++;
            }
            auto str2 = str[i .. j];
            addTokenAndAdvance(TokenTypeMapKeyword.get(str2, TokenType.Identifier), str2);
            i = j;
        } else if (ch.isDigit()) {
            ulong j = i + 1;
            while(j < len && str[j].isDigit()) {
                j++;
            }
            addTokenAndAdvance(TokenType.Number, str[i .. j]);
        } else if (ch == '"') {
            ulong j = i + 1;
            while(j < len && (str[j] != '"')) {
                j++;
            }
            j++;
            addTokenAndAdvance(TokenType.String, str[i .. j]);
        } else if (ch.isWhite()) {
            i++;
        } else {
            writefln("i: %s, ch: %s", i, ch);
            i++;
        }
    }
    return tokens;
}
bool matchesAtIndex(string main_str, string other_str, ulong i) {
    if (i + other_str.length > main_str.length) {
        return false;
    }
    return other_str == main_str[i .. i + other_str.length];
}
/*
<ident> = [a-zA-Z][a-zA-Z0-9_\-]*
*/
string foo(string main_str, ulong i) {
    auto strs = ["false", "true", "null"];
    foreach(x; strs) {
        if (matchesAtIndex(main_str, x, i)) {
            return x;
        }
    }
    return "";
}
