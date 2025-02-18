%{
#include "interpreter.tab.h"
#include <stdio.h>
#include <stdlib.h>

int colNo = 0;
int lineNo = 1; 
%}

%option noyywrap

%%  

"int"                           { colNo += yyleng; return TOK_INT; }
"float"                         { colNo += yyleng; return TOK_FLOAT; }
"double"                        { colNo += yyleng; return TOK_DOUBLE; }
"(int)"                         { colNo += yyleng; return TOK_CAST_INT; }
"(float)"                       { colNo += yyleng; return TOK_CAST_FLOAT; }
"(double)"                      { colNo += yyleng; return TOK_CAST_DOUBLE; }
"main"                          { colNo += yyleng; return TOK_MAIN; }
"if"                            { colNo += yyleng; return TOK_IF; }
"else"                          { colNo += yyleng; return TOK_ELSE; }
"while"                         { colNo += yyleng; return TOK_WHILE; }
"execute"                       { colNo += yyleng; return TOK_EXECUTE; }
"read"                          { colNo += yyleng; return TOK_READ; }
"print"                         { colNo += yyleng; return TOK_PRINT; }
"call"                          { colNo += yyleng; return TOK_CALL; }
"function"                      { colNo += yyleng; return TOK_FUNC; }
"return"                        { colNo += yyleng; return TOK_RETURN; }
"begin"                         { colNo += yyleng; return TOK_BEGIN; }
"end"                           { colNo += yyleng; return TOK_END; }
";;;"                           { colNo += yyleng; return TOK_PROGRAM_END; }
"+"                             { colNo++; return TOK_PLUS; }
"-"                             { colNo++; return TOK_MINUS; }
"*"                             { colNo++; return TOK_MULT; }
"/"                             { colNo++; return TOK_DIV; }
"="                             { colNo++; return TOK_ASSIGN; }
";"                             { colNo++; return TOK_SEP; }
"("                             { colNo++; return TOK_OPARAN; }
")"                             { colNo++; return TOK_CPARAN; }
"<"                             { colNo++; return TOK_LT; }
">"                             { colNo++; return TOK_GT; }
"=="                            { colNo++; return TOK_EQ; }
"!="                            { colNo++; return TOK_NEQ; }
"<="                            { colNo++; return TOK_LE; }
">="                            { colNo++; return TOK_GE; }
"{"                             { colNo++; return TOK_LACC; }
"}"                             { colNo++; return TOK_RACC; }

[a-zA-Z_][a-zA-Z0-9_]*          { colNo += yyleng; yylval.sval = strdup(yytext); return TOK_ID; }
[0-9]+                          { colNo += yyleng; yylval.ival = atoi(yytext); return TOK_INT_VAL; }
[0-9]+"."[0-9]+"f"              { colNo += yyleng; yylval.fval = atof(yytext); return TOK_FLOAT_VAL; }
[0-9]+"."[0-9]+                 { colNo += yyleng; yylval.dval = atof(yytext); return TOK_DOUBLE_VAL; }
"//"[^\n]*                      { colNo += yyleng; return TOK_COMMENT; }
\/\*[^*]*\*+([^/*][^*]*\*+)*\/  { colNo += yyleng; return TOK_COMMENT; }
\"[^\"]*\"                      { colNo += yyleng; yylval.sval = strdup(yytext); return TOK_STRING; }

[ \t]                           { colNo += yyleng; }
\n                              { colNo = 0; lineNo++; }
.                               { colNo++; return TOK_ERROR;}

%%