import std.stdio;
import std.algorithm;
import std.conv;
import std.ascii;
import std.typecons;
import std.array;
import std.json;
import std.file;

enum TokenType {
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
    EOF,
    
    Illegal,
}

static immutable TokenTypeMap = [
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
    int row, col;
    
    string getSpan() {
        if (type == TokenType.String) {
            return span[1 .. $ - 1];
        }
        return span;
    }
    
    void print() {
        writeln("Type = ", type);
        writeln("Span = ", span);
        writeln("Row = ", row);
        writeln("Col = ", col);
        writeln();
    }
}
alias TokenArray = Token[];

void main() {
    string filePath = "./test.lml";
    string test = readText(filePath);
    Nullable!TokenArray tokens = Lexer.lex(test);
	if (tokens.isNull()) {
        writeln("lexing failed");
        return;
	}
	//return;
	// tokens.get().each!(x => x.print());
    writeln(isValid(tokens.get()));
    Nullable!JSONValue parsed = Parser.toJson(tokens.get().removeWhiteSpace(), false);
    if (parsed.isNull()) {
        writeln("Parsing failed");
        return;
    }
    writeln(parsed.get().toPrettyString());
}

TokenArray removeWhiteSpace(TokenArray tokens) => tokens.filter!((x) => x.type != TokenType.WhiteSpace).array();

bool isValid(TokenArray tokens) {
    for (int i = 0; i < tokens.length - 1; i++) {
        auto token = tokens[i], nextToken = tokens[i + 1];
        if (token.type == nextToken.type && token.type == TokenType.Number) {
            writeln("Bad at:");
            token.print();
            nextToken.print();
            return false;
        }
    }
    return true;
}

bool canAppend(TokenArray tokens, TokenType type) {
    if (tokens.length == 0) return true;
    if (type != TokenType.WhiteSpace) return true;
    return tokens[$ - 1].type != TokenType.WhiteSpace;
}

struct Lexer {
    string str;
    uint i;
    string[] errors;
    int row = 1, col = 1;
    
    static Nullable!TokenArray lex(string str) => Lexer(str, 0).impl();
    
    private Nullable!Token makeAndAdvance(TokenType type, string span) {
        i += span.length;
        return nullable(Token(type, span, row, col));
    }
    
    private Nullable!Token next() {
        if (i >= str.length) return makeAndAdvance(TokenType.EOF, "");
        char ch = str[i];
        if (ch in TokenTypeMap) {
            auto t = makeAndAdvance(TokenTypeMap[ch], ch.to!(string));
            col += 1;
            return t;
        }
        if (ch.isAlpha()) {
            string parsedIdentifier = parseIdentifier();
            auto type = TokenTypeMapKeyword.get(parsedIdentifier, TokenType.Identifier);
            auto t = makeAndAdvance(type, parsedIdentifier);
            col += parsedIdentifier.length;
            return t;
        }
        if (ch.isDigit()) {
            Nullable!string parsedNumber = parseNumber();
            if (parsedNumber.isNull()) {
                writeln("Invalid number at ", row, " ", col);
                return Nullable!Token.init;
            }
            auto t = makeAndAdvance(TokenType.Number, parsedNumber.get());
            col += parsedNumber.get().length;
            return t;
        }
        if (ch == '"' || ch == '\'') {
            int rowTemp = row, colTemp = col;
            Nullable!string parsedString = parseString(ch, rowTemp, colTemp);
            if (parsedString.isNull()) {
                writeln("Invalid string at ", this.i);
                return Nullable!Token.init;
            }
            auto t = makeAndAdvance(TokenType.String, parsedString.get());
            row = rowTemp;
            col = colTemp;
            return t;
        }
        if (ch.isWhite()) {
            auto t = makeAndAdvance(TokenType.WhiteSpace, " ");
            col += 1;
            if (ch == '\n') {
                row += 1;
                col = 1;
            }
            return t;
        }
        writefln("i: %s, ch: %s", i, ch);
        i += 1;
        return next();
    }
    
    private Nullable!TokenArray impl() {
        TokenArray tokens = [];
        for (Nullable!Token token = next();; token = next()) {
            if (token.isNull()) {
                writeln("Lexing failed fuck you");
                return Nullable!TokenArray.init;
            }
            
            Token t = token.get();
            if (t.type == TokenType.EOF) break;
            if (!canAppend(tokens, t.type)) continue;
            tokens ~= t;
        }
        return nullable(tokens);
        // TokenArray tokens = [];
        // while (true) {
        //     auto token = next();
        //     if (token.isNull()) {
        //         writeln("Lexing failed");
        //         return Nullable!TokenArray.init;
        //     }
        //     if (token.get().type == TokenType.EOF) break;
        //     if (!canAppend(tokens, token.get().type)) continue;
        //     tokens ~= token.get();
        // }
        // return nullable(tokens);
    }
    
    private string parseIdentifier() {
        uint j = advanceWhile(str, i + 1, (x) => isAlphaNum(x) || x == '_' || x == '-');
        return str[i .. j];
    }
    
    private Nullable!string parseNumber() {
        if (str[i] == '0' && str.getC(i + 1, '\0') != '.') {
            return parseSpecialNumber();
        }
        
        uint j = parseIntegerPart(i);
        if (str.getC(j, '\0') == '.') {
            if (!str.getC(j + 1, '\0').isDigit()) return Nullable!string.init;
            j = parseDecimalPart(j);
        }
        if (str.getC(j, '\0').toLower() == 'e') {
            dchar c = str.getC(j + 1, '\0');
            if (!c.isDigit() && c != '-' && c != '+') return Nullable!string.init;
            j = parseExponentPart(j);
        }
        return nullable(str[i .. j]);
    }

    private uint parseIntegerPart(uint i) {
        return advanceWhile(str, i + 1, &isDigit);
    }
    private uint parseDecimalPart(uint i) {
        return advanceWhile(str, i + 1, &isDigit);
    }
    private uint parseExponentPart(uint i) {
        if (str[i + 1] == '+' || str[i + 1] == '-') i += 1;
        return advanceWhile(str, i + 1, &isDigit);
    }
    private Nullable!string parseSpecialNumber() {
        auto m = [
            'x': &isHexDigit,
            'o': &isOctalDigit,
            'b': &isBinaryDigit,
        ];
        if (i == str.length - 1) return nullable("0");
        auto n = str[i + 1];

        if(n in m) {
            uint j = advanceWhile(str, i + 2, m[n]);
            if (i + 2 == j) return Nullable!string.init;
            return nullable(str[i .. j]);
        }
        return nullable("0");
    }
    
    private Nullable!string parseString(char delim, ref int rowTemp, ref int colTemp) {
        ulong len = str.length;
        uint j = i + 1;
        
        while (j < len) {
            char ch = str[j];
            colTemp += 1;
            if (ch == '\n') {
                rowTemp += 1;
                colTemp = 1;
            }
            else if (ch == '\\' && j + 1 < len && str[j + 1] == delim) {
                j += 2;
                continue;
            }
            else if (ch == delim) break;
            j += 1;
        }
        j += 1;
        
        if (j > len) return Nullable!string.init;
        return nullable(str[i .. j]);
    }
}

bool isBinaryDigit(dchar c) {
    return '0' <= c && c <= '1';
}

uint advanceWhile(string str, uint i, bool function (dchar) fp) {
	ulong len = str.length;
	while (i < len && fp(str[i])) i += 1;
	return i;
}

dchar getC(string str, uint i, dchar ch) {
    if (i >= str.length) {
        return ch;
    }
    return str[i];
}

struct Parser {
    TokenArray tokens;
    uint i;
    bool info;
    string[] errors;
    
    private bool matches(TokenType[] types) {
        auto token = tokens[i];
        foreach(type; types) {
            if (token.type == type) {
                i += 1;
                return true;
            }
        }
        return false;
    }
    private JSONValue parseNumber() {
        if (info) { writeln("parsing number at ", i); }
        // number = -? numberLiteral
        int sign = 1;
        if (matches([TokenType.Minus])) {
            sign = -1;
        }
        auto number = tokens[i].getSpan();
        i += 1;
        if (number.length < 2) {
            return JSONValue(sign * number.to!(int));
        }
        switch (number[1].toLower()) {
        case 'x': return JSONValue(sign * number[2 .. $].to!(int)(16));
        case 'o': return JSONValue(sign * number[2 .. $].to!(int)(8));
        case 'b': return JSONValue(sign * number[2 .. $].to!(int)(2));
        default:
            if (number.canFind('.') || number.canFind('e') || number.canFind('E')) {
                return JSONValue(sign * number.to!(double));
            }
            return JSONValue(sign * number.to!(int));
        }
    }
    private Nullable!JSONValue parseValue() {
        if(info) { writeln("parsing value at ", i); }
        // value = number | string | dict | array
        auto token = tokens[i];
        if (matches([TokenType.True])) {
            return nullable(JSONValue(true));
        }
        if (matches([TokenType.False])) {
            return nullable(JSONValue(false));
        }
        if (matches([TokenType.Null])) {
            return nullable(JSONValue(null));
        }
        if (matches([TokenType.Minus, TokenType.Number])) {
            i -= 1;
            return nullable(parseNumber());
        }
        if (matches([TokenType.String])) {
            return nullable(JSONValue(token.getSpan()));
        }
        if (matches([TokenType.LeftBrace])) {
            auto dict = parseDict();
            if (dict.isNull()) {
                return Nullable!JSONValue.init;
            }
            return dict;
        }
        if (matches([TokenType.LeftBracket])) {
            auto arr = parseArray();
            if (arr.isNull()) {
                return Nullable!JSONValue.init;
            }
            return arr;
        }
        writeln("idk what (", token, ") is");
        return Nullable!JSONValue.init;
    }
    private Nullable!(string[]) parseKey() {
        // key = (string | identifier) ('.'? (string | identifier))*
        if (info) { writeln("parsing key at ", i); }
        string key = "";
        string[] res = [];
        if (!matches([TokenType.String, TokenType.Identifier])) {
            writeln("not a string or ident");
            return Nullable!(string[]).init;
        }
        key ~= tokens[i - 1].getSpan();
        while (matches([TokenType.Dot, TokenType.String, TokenType.Identifier])) {
            if (tokens[i - 1].type == TokenType.Dot) {
                res ~= key;
                key = "";
            } else {
                key ~= tokens[i - 1].getSpan();
            }
        }
        if (key.length != 0) {
            res ~= key;
        }
        // if the last token is a dot, it means the last key does not exist
        if (tokens[i - 1].type == TokenType.Dot) {
            return Nullable!(string[]).init;
        } 
        return nullable(res);
    }
    private Nullable!JSONValue parseDict() {
        if (info) { writeln("parsing dict at ", i); }
        // "{" (key "=" value)* "}"
        auto dict = JSONValue((JSONValue[string]).init);
        
        while (i < tokens.length && !matches([TokenType.RightBrace])) {
            auto key = parseKey();
            if (key.isNull()) {
                writeln("key is null");
                return Nullable!JSONValue.init;
            }
            if (!matches([TokenType.Equals])) {
                writeln("missing equals");
                writeln(i);
                return Nullable!JSONValue.init;
            }
            auto val = parseValue();
            if (val.isNull()) {
                writeln("val is null");
                return Nullable!JSONValue.init;
            }
            auto keys = key.get();
            dict = foo(dict, keys, val.get());
        }

        i -= 1;
        if (!matches([TokenType.RightBrace])) {
            return Nullable!JSONValue.init;
        }

        return nullable(dict);
    }
    private Nullable!JSONValue parseArray() {
        if (info) { writeln("parsing array at ", i); }
        // "[" value* "]"
        JSONValue arr = JSONValue(JSONValue[].init);
        //arr.array = [];

        while (i < tokens.length && !matches([TokenType.RightBracket])) {
            auto val = parseValue();
            if (val.isNull()) {
                return Nullable!JSONValue.init;
            }
            arr.array() ~= val.get();
        }
        i -= 1;
        if (!matches([TokenType.RightBracket])) {
            return Nullable!JSONValue.init;
        }
        return nullable(arr);
    }
    
    static Nullable!JSONValue toJson(TokenArray tokens, bool info = false) {
        auto foo = Parser(tokens, 0, info);
        if (tokens.length == 0) {
            return nullable(JSONValue());
        }
        return foo.parseValue();
    }
}


JSONValue foo(JSONValue json, string[] keys, JSONValue val) {
	if (keys.length == 0) {
		return val;
	}
	if (keys[0] !in json) {
		json[keys[0]] = JSONValue.emptyObject;
	}
	json[keys[0]] = foo(json[keys[0]], keys[1 .. $], val);
	return json;
}
