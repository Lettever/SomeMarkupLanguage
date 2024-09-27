#[derive(Debug, Clone)]
enum Token {
    Plus,
    Minus,
    Dot,
    Equals,
    
    True,
    False,
    Null,
    
    String(String),
    Integer(i64),
    Float(f64),
    Identifier(String),
    
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    
    WhiteSpace,
}

fn main() {
    println!("hello");
    let foo = Token::Float(10.123);
    let bar = Token::String("abc".into());
    println!("{:?}", &foo);
    println!("{:?}", &bar);
    println!("");
    let a = lex("a-_ bc+-+-*({[]})".into());
    println!("Result: {:?}", a);
}

fn char_to_token(ch: &char) -> Option<Token> {
    return match ch {
        '+' => Some(Token::Plus),
        '-' => Some(Token::Minus),
        '.' => Some(Token::Dot),
        '=' => Some(Token::Equals),
        '[' => Some(Token::LeftBracket),
        ']' => Some(Token::RightBracket),
        '{' => Some(Token::LeftBrace),
        '}' => Some(Token::RightBrace),
        _ => None,
    }
}
fn string_to_token(string: &str) -> Option<Token> {
    return match string {
        "true" => Some(Token::True),
        "false" => Some(Token::False),
        "null" => Some(Token::Null),
        _ => None,
    }
}
fn lex(string: String) -> Option<Vec<Token>> {
    println!("{}", string);
    let chars: Vec<_> = string.chars().collect();
    let mut tokens: Vec<Token> = Vec::new();
    let mut i = 0;
    let len = chars.len();
/*    String(String),
    Integer(i64),
    Float(f64),
    Identifier(String), */
    while i < len {
        let ch = chars[i];
        if let Some(ch1) = char_to_token(&ch) {
            tokens.push(ch1);
            i += 1;
        } else if ch.is_alphabetic() {
            let mut j = i + 1;
            while chars[j].is_alphanumeric() || chars[j] == '_' || chars[j] == '-' {
                j += 1;
            }
            
            let string_slice = chars[i .. j].iter().collect::<String>();
            let token = string_to_token(string_slice.as_str()).unwrap_or(Token::Identifier(string_slice));
            tokens.push(token);
            i = j;
        } else {
            i += 1;
        }
    }
    return Some(tokens);
}
/*
Nullable!TokenArray lex(string str) {
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
*/
/*
#[derive(Debug, Clone)]
enum Token {
    Plus,
    Minus,
    Dot,
    Equals,
    True,
    False,
    Null,
    String(String),
    Integer(i64),
    Float(f64),
    Identifier(String),
    LeftBrace,
    RightBrace,
    LeftBracket,
    RightBracket,
    WhiteSpace,
}

fn main() {
    println!("hello");
    let foo = Token::Float(10.123);
    let bar = Token::String("abc".to_string());
    println!("{:?}", &foo);
    println!("{:?}", &bar);
    println!("");
    let a = lex("a bc+-+-*({[]})".to_string());
    println!("Result: {:?}", a);
}

fn char_to_token(ch: char) -> Option<Token> {
    match ch {
        '+' => Some(Token::Plus),
        '-' => Some(Token::Minus),
        '.' => Some(Token::Dot),
        '=' => Some(Token::Equals),
        '[' => Some(Token::LeftBracket),
        ']' => Some(Token::RightBracket),
        '{' => Some(Token::LeftBrace),
        '}' => Some(Token::RightBrace),
        _ => None,
    }
}

fn string_to_token(string: &str) -> Option<Token> {
    match string {
        "true" => Some(Token::True),
        "false" => Some(Token::False),
        "null" => Some(Token::Null),
        _ => None,
    }
}

fn lex(input: String) -> Option<Vec<Token>> {
    let chars: Vec<char> = input.chars().collect();
    let mut tokens: Vec<Token> = Vec::new();
    let mut position: usize = 0;
    
    while position < chars.len() {
        let ch = chars[position];
        if let Some(token) = char_to_token(ch) {
            tokens.push(token.clone());
            position += 1;
        } else if ch.is_whitespace() {
            position += 1;
        } else {
            break;
        }
    }
    
    // Handle remaining characters
    if position < chars.len() {
        let mut current_char = chars[position];
        while position + 1 < chars.len() && current_char == ' ' {
            current_char = chars[position + 1];
            position += 1;
        }
        
        match current_char {
            '0'..='9' | '.' => {
                let mut number = String::new();
                while position < chars.len() && (current_char >= '0' && current_char <= '9' || current_char == '.') {
                    number.push(current_char);
                    position += 1;
                    if position < chars.len() {
                        current_char = chars[position];
                    }
                }
                if !number.is_empty() {
                    tokens.push(Token::Integer(number.parse::<i64>().unwrap()));
                }
            },
            _ => {
                let mut identifier = String::new();
                while position < chars.len() && (current_char.is_alphabetic() || current_char == '_') {
                    identifier.push(current_char);
                    position += 1;
                    if position < chars.len() {
                        current_char = chars[position];
                    }
                }
                if !identifier.is_empty() {
                    tokens.push(Token::Identifier(identifier));
                }
            },
        }
    }
    
    Some(tokens)
}

*/