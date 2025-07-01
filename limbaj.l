%{
#include "limbaj.tab.h"
#include <string>
#include <cstring>
#include "ast.h"
#include "symtable.h"
%}

%option noyywrap
%option yylineno

DIGIT       [0-9]
ID          [a-zA-Z_][a-zA-Z0-9_]*

%%

"int"             { return INT_TYPE; }
"float"           { return FLOAT_TYPE; }
"char"            { return CHAR_TYPE; }
"bool"            { return BOOL_TYPE; }
"string"          { return STRING_TYPE; }


"class"           { return CLASS; }
"true"            { return TRUE; }
"false"           { return FALSE; }
"new"             { return NEW; }
"if"              { return IF; }
"else"            { return ELSE; }
"while"           { return WHILE; }
"for"             { return FOR; }
"return"          { return RETURN; }
"void"            { return VOID; }
"Print"           { return PRINT; }
"TypeOf"          { return TYPEOF; }


"begin_classes"   { return BEGIN_CLASSES; }
"end_classes"     { return END_CLASSES; }
"begin_globals"   { return BEGIN_GLOBALS; }
"end_globals"     { return END_GLOBALS; }
"begin_functions" { return BEGIN_FUNCTIONS; }
"end_functions"   { return END_FUNCTIONS; }
"begin_main"      { return BEGIN_MAIN; }
"end_main"        { return END_MAIN; }


"{"        { return ACOLADAS; }
"}"        { return ACOLADAD; }
"("        { return PARANTEZAS; }
")"        { return PARANTEZAD; }
"["        { return '['; }
"]"        { return ']'; }
","        { return VIRGULA; }
";"        { return PVIRGULA; }
"="        { return EGAL; }
"."        { return PUNCT; }


"=="       { return EQ; }
"!="       { return NEQ; }
"<"        { return LT; }
">"        { return GT; }
"<="       { return LE; }
">="       { return GE; }
"&&"       { return AND; }
"||"       { return OR; }
"!"        { return NOT; }


"+"        { return PLUS; }
"-"        { return MINUS; }
"*"        { return STAR; }
"/"        { return SLASH; }
"%"        { return '%'; }


\"([^\"\n]|\\.)*\" {
    std::string str(yytext);
    str.erase(0, 1);              
    str.erase(str.size()-1, 1);   
    yylval.sval = strdup(str.c_str());
    return STRING;
}


'([^'\n]|\\.)' {
    std::string str(yytext);

    char c = str[1];  
    yylval.cval = c;
    return CHAR;
}


{ID} {
    yylval.sval = strdup(yytext);
    return ID;
}


{DIGIT}+ {
    yylval.ival = atoi(yytext);
    return INT;
}


{DIGIT}+"."{DIGIT}+ {
    yylval.fval = atof(yytext);
    return FLOAT;
}


[ \t\r\n]+  ;

.   { 
    printf("Eroare: Caracter necunoscut: %s\n", yytext); 
    yylval.sval = strdup(yytext);
    return -1;  
}

%%
