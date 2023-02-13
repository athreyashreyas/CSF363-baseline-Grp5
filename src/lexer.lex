%option noyywrap

%{
#include "parser.hh"
#include <string>
#include <map>
#include <unordered_set>
using namespace std;

map <string, string> m;

extern int yyerror(std::string msg);

string getvalue(string key) {
    unordered_set<string> visited;
    visited.clear();
    
    while(m.count(key) > 0 && m[key] != "") {
        if (visited.count(key)) {
            yyerror("circular dependency detected, please define macros again");
            return 0;
        }
        
        visited.insert(key);
        key = m[key];
    }
    
    return key;
}
%}

%%

"#def "     {
    int c;
    int flag = 0; 
    string key = "", value = "";
    
    while((c = yyinput()) != 0) {
        if (flag == 0 && c == '\n') {
            break;
        }
        else if (flag == 0 && c == ' ') {
            flag = 1;
            continue;
        } else if (flag == 1) { 
            if (c == '\\') { 
                flag = 2;
                continue;
            }
            else if (c == '\n') { 
                break;
            }
        } else if (flag == 2) { 
            flag = 1;
        }
        
        if (flag == 0) 
            key += c;
        else 
            value += c;
    }
    
    if (value == "")
        m[key] = "1";
    else 
        m[key] = value;
}
"#undef "   {
    int c; 
    string key = "";
    
    // read key
    while((c = yyinput()) != 0 && c != '\n') 
        key += c; 
            
    m[key] = "";
}

"+"       { return TPLUS; }
"-"       { return TDASH; }
"*"       { return TSTAR; }
"/"       { return TSLASH; }
";"       { return TSCOL; }
"("       { return TLPAREN; }
")"       { return TRPAREN; }
"="       { return TEQUAL; }
"dbg"     { return TDBG; }
"let"     { return TLET; }
[0-9]+    { yylval.lexeme = std::string(yytext); return TINT_LIT; }
[a-zA-Z]+ {
    
    string sub = getvalue(std::string(yytext));
    
    if (sub != std::string(yytext)) { // if substitution is done
        if(sub.length() <= strlen(yytext)) { 
            int len = sub.length() - 1;
            for (int i = strlen(yytext) - 1; i >= 0; i--) {
                if(i > len) 
                    unput(' ');
                else 
                    unput(sub[i]);
            }
        }
        else {
            for (int i = sub.length() - 1; i >= 0; i--) {
                unput(sub[i]);
            }
        }
    } else { 
        yylval.lexeme = sub;
        return TIDENT;
    }
}
[ \t\n]   { /* skip */ }
"//"(.)*      { /*skip*/ }
"/*"(.)*"*/" {/* skip */}
.         { yyerror("unknown char"); }

%%

std::string token_to_string(int token, const char *lexeme) {
    std::string s;
    switch (token) {
        case TPLUS: s = "TPLUS"; break;
        case TDASH: s = "TDASH"; break;
        case TSTAR: s = "TSTAR"; break;
        case TSLASH: s = "TSLASH"; break;
        case TSCOL: s = "TSCOL"; break;
        case TLPAREN: s = "TLPAREN"; break;
        case TRPAREN: s = "TRPAREN"; break;
        case TEQUAL: s = "TEQUAL"; break;
        
        case TDBG: s = "TDBG"; break;
        case TLET: s = "TLET"; break;
        
        case TINT_LIT: s = "TINT_LIT"; s.append("  ").append(lexeme); break;
        case TIDENT: s = "TIDENT"; s.append("  ").append(lexeme); break;
    }
    
    
    return s;
}
