import std.stdio;
import std.algorithm;
import std.conv;
import std.ascii;
import std.typecons;
import std.array;
import std.json;

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
static immutable TokenTypeMap = [
    '+': TokenType.Plus,
    '-': TokenType.Minus,
    '.': TokenType.Dot,
    '=': TokenType.Equals,
    '[': TokenType.LeftBracket,
    ']': TokenType.RightBracket,
    '{': TokenType.LeftBrace,
    '}': TokenType.RightBrace,
];
static immutable TokenTypeMapKeyword = [
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
    nullfalse[false{null true}]"abc" 0x10 0o1 8 0o17 0b10101 10.2 0.10 0`;
    writeln(test);
    
    Nullable!TokenArray b = lex(test);
	if (b.isNull()) {
        writeln("lexing failed");
        return;
	}
    auto b1 = b.get();
    writeln(isTokenArrayValid(b1));
    readln();
	//b1 = removeWhiteSpace(b1);
    b1.each!writeln;
}
Nullable!TokenArray lex(string str) {
    uint i = 0;
	ulong len = str.length;
	Token[] tokens = [];
    void addTokenAndAdvance(TokenType type, string span) {
        tokens ~= Token(type, span);
        i += span.length;
    }
    
    while (i < len) {
        char ch = str[i];
        if (ch in TokenTypeMap) {
            addTokenAndAdvance(TokenTypeMap[ch], ch.to!(string));
        } else if (ch.isAlpha()) {
            string parsedIdentifier = parseIdentifier(str, i);
            addTokenAndAdvance(TokenTypeMapKeyword.get(parsedIdentifier, TokenType.Identifier), parsedIdentifier);
        } else if (ch.isDigit()) {
            Nullable!string parsedNumber = parseNumber(str, i);
            if (parsedNumber.isNull()) {
                return Nullable!TokenArray.init;
            }
            addTokenAndAdvance(TokenType.Number, parsedNumber.get());
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
    uint j =  advanceWhile(str, i + 1, (x) => isAlphaNum(x) || x == '_' || x == '-');
    return str[i .. j];
}
// str[i] == 0 && str[i + 1] != '.' -> parse special
// str[i] != 0 || str[i + 1] == '.' -> parse decimal

Nullable!string parseNumber(string str, uint i) {
    ulong len = str.length;
    if (str[i] == '0' && i + 1 < len && str[i + 1] != '.') {
        switch (str[i + 1].toLower()) {
        case 'x':
            uint j = advanceWhile(str, i + 2, &isHexDigit);
            return nullable(str[i .. j]);
        break;
        case 'o':
            uint j = advanceWhile(str, i + 2, &isOctalDigit);
            return nullable(str[i .. j]);
        break;
        case 'b':
            uint j = advanceWhile(str, i + 2, &isBinaryDigit);
            return nullable(str[i .. j]);
        break;
        default:
            return Nullable!string.init;
        }
    }
    uint j = advanceWhile(str, i + 1, &isDigit);
    if (str.getC(j, '\0') != '.') {
        return nullable(str[i .. j]);
    }
    if (!str.getC(j + 1, '\0').isDigit()) {
        return Nullable!string.init;
    }
    j = advanceWhile(str, j + 1, &isDigit);
    return nullable(str[i .. j]);
}

Nullable!string parseString(string str, uint i) {
    uint j = advanceWhile(str, i + 1, (x) => x != '"') + 1;
    ulong len = str.length;
    
    if (j > len) {
        return Nullable!string.init;
    }
    return nullable(str[i .. j]);
}
bool isBinaryDigit(dchar c) {
    return '0' <= c && c <= '1';
}

//After every number, string, or identifier
//there must be either a whitespace
//a closing bracket, a closing brace, or the end of the file

bool isLiteralOrIdentifier(Token token) {
    auto type = token.type;
    return (
        type == TokenType.Number ||
        type == TokenType.String ||
        type == TokenType.Identifier
    );
}
bool isTokenArrayValid(TokenArray tokens) {
    for (uint i = 0; i < tokens.length - 1; i++) {
        if (
            tokens[i].isLiteralOrIdentifier() &&
            tokens[i + 1].isLiteralOrIdentifier()
        ) {
            writeln(tokens[i], " ", tokens[i + 1]);

            return false;
        }
    }
    return true;
}

TokenArray removeWhiteSpace(TokenArray tokens) {
    return tokens.filter!((x) => x.type != TokenType.WhiteSpace).array();
}
JSONValue toJson(TokenArray tokens) {
    return JSONValue(10);
}
uint advanceWhile(string str, uint i, bool function (dchar) fp) {
	ulong len = str.length;
	while(i < len && fp(str[i])) {
        i += 1;
	}
	return i;
}

dchar getC(string str, uint i, dchar ch) {
    if (i >= str.length) {
        return ch;
    }
    return str[i];
}
