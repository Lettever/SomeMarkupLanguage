import std.stdio;
import std.algorithm;
import std.conv;
import std.ascii;
import std.typecons;
import std.array;

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
alias TokenArray = Token[];

void main() {
	string test = `a = 11 b= 123 c="abc" d.e-f."g.h"=true truef false null
    nullfalse[false{null true}]"abc" 0x10 0o1 8 0o17 0b10101 0 `;
	writeln(test);
	Nullable!TokenArray b = lex(test);
	if (b.isNull()) {
        writeln("lexing failed");
        return;
	}
    auto b1 = b.get();
	// b1.each!writeln;
    writefln("|     %s", isTokenArrayValid(b1));
    b1 = removeWhiteSpace(b1);
    b1.each!writeln;
}
/*
    After every number there cant be a number, an identifier or a strng
    TODO:
        add suport for hexadecimal, octal and binary numbers
        when parsing string handles special characters and non-raw strings
        right now it only handles raw strings
        do better error handling
*/
Nullable!TokenArray lex(string str) {
    uint i = 0, len = str.length, line = 1;
    Token[] tokens = [];
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
            Nullable!string parsedString = parseString(str, i);
            if (parsedString.isNull()) {
                return Nullable!TokenArray.init;
            }
            addTokenAndAdvance(TokenType.String, parsedString.get());
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
    return nullable(tokens);
}
bool matchesAtIndex(string haystack, string needle, uint i) {
    if (i + needle.length > haystack.length) {
        return false;
    }
    return needle == haystack[i .. i + needle.length];
}
string parseIdentifier(string str, uint i) {
    uint j = i + 1, len = str.length;
    while (j < len && (str[j].isAlphaNum() || str[j] == '_' || str[j] == '-')) {
        j += 1;
    }
    return str[i .. j];
}
string parseNumber(string str, uint i) {
    uint j = i + 1, len = str.length;
    if (str[i] == '0') {
        if (i + 1 >= len) {
            return "0";
        } else if (str[j].toLower() == 'x') {
            j += 1;
            while(j < len && str[j].isHexDigit()) {
                j += 1;
            }
            return str[i .. j];
        } else if (str[j].toLower() == 'o') {
            j += 1;
            while(j < len && str[j].isOctalDigit()) {
                j += 1;
            }
            return str[i .. j];
        } else if (str[j].toLower() == 'b') {
            j += 1;
            while(j < len && str[j].isBinaryDigit()) {
                j += 1;
            }
            return str[i .. j];
        }
    } else {
        while(j < len && str[j].isDigit()) {
            j += 1;
        }
        return str[i .. j];
    }
    return str[i .. j];
}
Nullable!string parseString(string str, uint i) {
    uint j = i + 1, len = str.length;
    while(j < len && (str[j] != '"')) {
        j += 1;
    }
    if (j == len) {
        return Nullable!string.init;
    }
    j += 1;
    return nullable(str[i .. j]);
}
bool isBinaryDigit(dchar c) {
    return '0' <= c && c <= '1';
}
bool isTokenArrayValid(TokenArray tokens) {
    char[] parenthesesStack = [];
    for (int i = 0; i < tokens.length; i++) {
        auto token = tokens[i];
        auto tokenType = token.type;
        if (tokenType == TokenType.LeftBrace) { 
            parenthesesStack ~= '{';
        } else if (tokenType == TokenType.RightBrace) { 
            if (parenthesesStack.length == 0 || parenthesesStack[$ - 1] != '{') {
                return false;
            }
            parenthesesStack = parenthesesStack[0 .. $ - 1];
        } else if (tokenType == TokenType.LeftBracket) {
            parenthesesStack ~= '[';
        } else if (tokenType == TokenType.RightBracket) {
            if (parenthesesStack.length == 0 || parenthesesStack[$ - 1] != '[') {
                writeln(TokenType.RightBracket, " ", parenthesesStack);
                return false;
            }
            parenthesesStack = parenthesesStack[0 .. $ - 1];
        } else if (tokenType == TokenType.Number) {
            if (i + 1 < tokens.length) {
                auto nextTokenType = tokens[i + 1].type;
                bool nextTokenIsInvalid = (
                    nextTokenType == TokenType.Number ||
                    nextTokenType == TokenType.Identifier ||
                    nextTokenType == TokenType.String
                );
                if (nextTokenIsInvalid) {
                    return false;
                }
            }
        }
    }
    return true;
}
TokenArray removeWhiteSpace(TokenArray tokens) {
    return tokens.filter!((x) => x.type != TokenType.WhiteSpace).array();
}