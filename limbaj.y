%{
#include <iostream>
#include <string>
#include <cstring>  
#include <sstream>  
#include <vector>   
#include "symtable.h"
#include "ast.h"

extern int yylineno;

using namespace std;

extern FILE* yyin;
extern int yylex();
extern int yyparse();
void yyerror(const char *s);

SymTable globalTable("global");
SymTable* currentSymTable = &globalTable;

int errorCount = 0;


static char* concatCSV(const char* left, const char* right)
{
    if (!left || strlen(left) == 0) {
        return strdup(right);
    }
    if (!right || strlen(right) == 0) {
        return strdup(left);
    }
    size_t size = strlen(left) + 1 + strlen(right) + 1; 
    char* result = (char*) malloc(size);
    snprintf(result, size, "%s,%s", left, right);
    return result;
}


static vector<string> splitCSV(const char* csv)
{
    vector<string> tokens;
    if (!csv || !*csv) {
        return tokens;
    }
    string str(csv);
    istringstream iss(str);
    string token;
    while (getline(iss, token, ',')) {
        tokens.push_back(token);
    }
    return tokens;
}
%}

%union {
   class ASTNode* anode;
   int ival;       
   float fval;     
   char cval;      
   char* sval;     
}


%type <sval> type
%type <sval> arg_list arg_list_nonempty
%type <sval> expression term factor
%type <sval> bool_expr comparison_expr

%type <anode> expression_ast term_ast factor_ast bool_expression_ast comparison_expression_ast


%token <ival> INT
%token <fval> FLOAT
%token <cval> CHAR
%token <sval> STRING
%token <sval> ID


%token CLASS IF ELSE WHILE FOR RETURN VOID NEW PRINT TYPEOF
%token TRUE FALSE
%token BEGIN_CLASSES END_CLASSES BEGIN_GLOBALS END_GLOBALS BEGIN_FUNCTIONS END_FUNCTIONS BEGIN_MAIN END_MAIN

%token INT_TYPE FLOAT_TYPE CHAR_TYPE STRING_TYPE BOOL_TYPE

%token EGAL PVIRGULA VIRGULA
%token ACOLADAS ACOLADAD PARANTEZAS PARANTEZAD
%token PLUS MINUS STAR SLASH
%token PRINTAST

%token OR AND NOT
%token EQ NEQ LT GT LE GE
%token PUNCT

%right NOT
%left AND
%left OR
%nonassoc EQ NEQ LT GT LE GE
%left '+' '-'
%left '*' '/' '%'

%start program

%%

program:
    BEGIN_CLASSES class_section END_CLASSES
    BEGIN_GLOBALS global_section END_GLOBALS
    BEGIN_FUNCTIONS function_section END_FUNCTIONS
    main_section
    {
        if (errorCount == 0) {
            cout << "[Linia " << yylineno << "] Program parsed successfully!\n";
        }
        cout << "\n=== Symbol Table (cu scopuri) ===\n";
        globalTable.displaySymbols();
        globalTable.dumpSymbolsToFile("syminfo.txt");
    }
    ;


class_section:
      /* empty */
    | class_section class_def
    ;

class_def:
    CLASS ID 
    {
      SymTable* classScope = currentSymTable->createSubScope($<sval>2);
      currentSymTable->insertClass($<sval>2);
      currentSymTable = classScope;
    }
    ACOLADAS class_continut ACOLADAD
    {
      currentSymTable = currentSymTable->returnToParentScope();
      free($<sval>2);
    }
  ;

class_continut:
      /* empty */
    | class_continut class_member
    ;

class_member:
   var_decl
  | type ID 
    {
       SymTable* methodScope = currentSymTable->createSubScope($<sval>2);
       currentSymTable->insertFunction($<sval>2, $<sval>1, {});
       currentSymTable = methodScope;
    }
    PARANTEZAS param_list PARANTEZAD ACOLADAS function_body ACOLADAD
    {
       currentSymTable = currentSymTable->returnToParentScope();
       free($<sval>2);
    }
  | VOID ID 
    {
       SymTable* methodScope = currentSymTable->createSubScope($<sval>2);
       currentSymTable->insertFunction($<sval>2, "void", {});
       currentSymTable = methodScope;
    }
    PARANTEZAS param_list PARANTEZAD ACOLADAS function_body ACOLADAD
    {
       currentSymTable = currentSymTable->returnToParentScope();
       free($<sval>2);
    }
  ;


global_section:
      /* empty */
    | global_section global_var_decl
    ;

global_var_decl:
    type ID PVIRGULA
    {
       currentSymTable->insertVariable($<sval>2, $<sval>1);
       free($<sval>2);
    }
  | type ID EGAL bool_expr PVIRGULA
    {
      currentSymTable->insertVariable($<sval>2, $<sval>1);
      SymbolInfo* si = currentSymTable->searchSymbol($<sval>2);
      if (si && si->type != $<sval>4) {
         cerr << "[Linia " << yylineno << "] [Global] Type mismatch: var '" << $<sval>2
              << "' e " << si->type << " dar expr e " << $<sval>4 << endl;
      } else {
         cout << "[Linia " << yylineno << "] Valoarea variabilei " << $<sval>2
              << " a fost modificata la init_value.\n";
         currentSymTable->updateVariableValue($<sval>2, "init_value");
      }
      free($<sval>2);
    }
  | type ID '[' INT ']' PVIRGULA
    {
       currentSymTable->insertVector($<sval>2, $<sval>1, $<ival>4);
       free($<sval>2);
    }
  | type ID '[' INT ']' EGAL '{' arg_list '}' PVIRGULA
    {
       currentSymTable->insertVector($<sval>2, $<sval>1, $<ival>4);
       free($<sval>2);
    }
  ;


function_section:
      /* empty */
    | function_section functie
    ;

functie:
    type ID 
    {
       SymTable* funcScope = currentSymTable->createSubScope($<sval>2);
       currentSymTable->insertFunction($<sval>2, $<sval>1, {});
       currentSymTable = funcScope;
    }
    PARANTEZAS param_list PARANTEZAD ACOLADAS function_body ACOLADAD
    {
       currentSymTable = currentSymTable->returnToParentScope();
       free($<sval>2);
    }
  | VOID ID 
    {
       SymTable* funcScope = currentSymTable->createSubScope($<sval>2);
       currentSymTable->insertFunction($<sval>2, "void", {});
       currentSymTable = funcScope;
    }
    PARANTEZAS param_list PARANTEZAD ACOLADAS function_body ACOLADAD
    {
       currentSymTable = currentSymTable->returnToParentScope();
       free($<sval>2);
    }
  ;


main_section:
    BEGIN_MAIN
    {
       SymTable* mainScope = currentSymTable->createSubScope("main");
       currentSymTable->insertFunction("main", "int", {});
       currentSymTable = mainScope;
    }
    function_body
    END_MAIN
    {
       currentSymTable = currentSymTable->returnToParentScope();
    }
    ;


function_body:
      /* empty */
    | function_body line
    ;

line:
    var_decl
  | class_var_decl  
  | assign
  | RETURN expression PVIRGULA
  | instructiune
  | func_call PVIRGULA
  | ID PUNCT ID PARANTEZAS arg_list PARANTEZAD PVIRGULA
  | ID PVIRGULA
  | error PVIRGULA 
    {
       yyerror(" Linie invalida. Continuam parsing-ul...");
    }
  ;


var_decl:
    type ID PVIRGULA
    {
      currentSymTable->insertVariable($<sval>2, $<sval>1);
      free($<sval>2);
    }
  | type ID EGAL bool_expr PVIRGULA
    {
      currentSymTable->insertVariable($<sval>2, $<sval>1);
      SymbolInfo* si = currentSymTable->searchSymbol($<sval>2);
      if (si && si->type != $<sval>4) {
         cerr << "[Linia " << yylineno << "] [Local] Type mismatch: var '" << $<sval>2
              << "' e " << si->type
              << " dar expr e " << $<sval>4 << endl;
      } else {
         cout << "[Linia " << yylineno << "] Valoarea variabilei " << $<sval>2
              << " a fost modificata la some_value.\n";
         currentSymTable->updateVariableValue($<sval>2, "some_value");
      }
      free($<sval>2);
    }
  | type ID '[' INT ']' PVIRGULA
    {
      currentSymTable->insertVector($<sval>2, $<sval>1, $<ival>4);
      free($<sval>2);
    }
  | type ID '[' INT ']' EGAL '{' arg_list '}' PVIRGULA
    {
      currentSymTable->insertVector($<sval>2, $<sval>1, $<ival>4);
      free($<sval>2);
    }
  ;

class_var_decl:
    ID ID PVIRGULA
    {
      currentSymTable->insertVariable($<sval>2, $<sval>1);
      free($<sval>1); 
      free($<sval>2);
    }
  ;


assign:
    ID EGAL bool_expr PVIRGULA
    {
      SymbolInfo* si = currentSymTable->searchSymbol($<sval>1);
      if (!si) {
         cerr << "[Linia " << yylineno << "] Semantic error: var '" << $<sval>1
              << "' nu a fost definit.\n";
      }
      else if (si->category != "variable") {
         cerr << "[Linia " << yylineno << "] Semantic error: '" << $<sval>1
              << "' nu e variabila.\n";
      }
      else {
         if (si->type != $<sval>3) {
            cerr << "[Linia " << yylineno << "] [Assign] Type mismatch: '" << $<sval>1
                 << "' e " << si->type
                 << ", dar expr e " << $<sval>3 << endl;
         } else {
            cout << "[Linia " << yylineno << "] Valoarea variabilei " << $<sval>1 
                 << " a fost modificata la new_value.\n";
            currentSymTable->updateVariableValue($<sval>1, "new_value");
         }
      }
      free($<sval>1);
    }
  | ID '[' expression ']' EGAL expression PVIRGULA
    {
      SymbolInfo* found = currentSymTable->searchSymbol($<sval>1);
      if (!found) {
         cerr << "[Linia " << yylineno << "] Semantic error: Vectorul '" << $<sval>1
              << "' nu e definit.\n";
      }
      else if (VecInfo* vec = dynamic_cast<VecInfo*>(found)) {
         if (vec->type != $<sval>6) {
            cerr << "[Linia " << yylineno << "] [Assign] Type mismatch: " << $<sval>1 
                 << " e vector<" << vec->type
                 << "> dar expr e " << $<sval>6 << endl;
         } else {
            cout << "[Linia " << yylineno << "] Element din vectorul " << $<sval>1
                 << " a fost modificat la some_expr_value.\n";
            currentSymTable->updateVectorItem($<sval>1, 0, "some_expr_value");
         }
      }
      else {
         cerr << "[Linia " << yylineno << "] Semantic error: '" << $<sval>1
              << "' nu e vector.\n";
      }
      free($<sval>1);
    }
  ;


instructiune:
    IF PARANTEZAS bool_expr PARANTEZAD
    {
      currentSymTable->insertInstruction("if");
      SymTable* ifScope = currentSymTable->createSubScope("if-scope");
      currentSymTable = ifScope;
    }
    ACOLADAS function_body ACOLADAD
    {
      currentSymTable = currentSymTable->returnToParentScope();
    }
    opt_else

  | WHILE PARANTEZAS bool_expr PARANTEZAD
    {
      currentSymTable->insertInstruction("while");
      SymTable* whileScope = currentSymTable->createSubScope("while-scope");
      currentSymTable = whileScope;
    }
    ACOLADAS function_body ACOLADAD
    {
      currentSymTable = currentSymTable->returnToParentScope();
    }

  | FOR PARANTEZAS 
    {
      currentSymTable->insertInstruction("for");
      SymTable* forScope = currentSymTable->createSubScope("for-scope");
      currentSymTable = forScope;
    }
    for_initialization bool_expr PVIRGULA for_update PARANTEZAD ACOLADAS function_body ACOLADAD
    {
      currentSymTable = currentSymTable->returnToParentScope();
    }
  ;

for_initialization:
    assign
  | var_decl
  ;

for_update:
    ID EGAL expression
  | /* empty */
  ;

/* else */
opt_else:
      /* empty */
    | ELSE 
      {
        currentSymTable->insertInstruction("else");
        SymTable* elseScope =
            currentSymTable->returnToParentScope()->createSubScope("else-scope");
        currentSymTable = elseScope;
      }
      ACOLADAS function_body ACOLADAD
      {
        currentSymTable = currentSymTable->returnToParentScope();
      }
  ;


func_call:
   TYPEOF PARANTEZAS bool_expr PARANTEZAD
  {
     cout << "[Linia " << yylineno << "] Tipul expresiei este " << $<sval>3 << "\n";
  }
  | PRINT PARANTEZAS bool_expression_ast PARANTEZAD
    {
      ASTNode* root = $3;
      auto rez = root->evaluate(); 
      cout << "[Linia " << yylineno << "] [AST] Value=" << rez.second 
           << " , Type=" << rez.first << endl;
      delete root;  
    }
  | ID PARANTEZAS arg_list PARANTEZAD
    {
      SymbolInfo* found = currentSymTable->searchSymbol($<sval>1);
      if (!found) {
         cerr << "[Linia " << yylineno << "] Semantic error: Functia '" 
              << $<sval>1 << "' nu a fost definita anterior.\n";
      }
      else if (FnInfo* fn = dynamic_cast<FnInfo*>(found)) {
         vector<string> actualTypes = splitCSV($<sval>3);
         vector<string>& expectedTypes = fn->parameters;
         for (size_t i = 0; i < expectedTypes.size(); i++) {
           if (i >= actualTypes.size()) break;
           if (actualTypes[i] != expectedTypes[i]) {
             cerr << "[Linia " << yylineno 
                  << "] Semantic error: Parametrul #" << (i+1)
                  << " pentru '" << $<sval>1
                  << "' trebuie sa fie '" << expectedTypes[i]
                  << "', dar s-a gasit '" << actualTypes[i] << "'.\n";
           }
         }
      }
      else {
         cerr << "[Linia " << yylineno << "] Semantic error: '" << $<sval>1
              << "' nu este o functie.\n";
      }
      free($<sval>1);
      free($<sval>3);
    }
  ;


param_list:
      /* empty */
    | param_list_nonempty
    ;

param_list_nonempty:
    param
  | param_list_nonempty VIRGULA param
  ;

param:
    type ID
    {
      currentSymTable->insertVariable($<sval>2, $<sval>1);
      free($<sval>2);
    }
  ;


type:
    INT_TYPE    { $$ = (char*)"int"; }
  | FLOAT_TYPE  { $$ = (char*)"float"; }
  | CHAR_TYPE   { $$ = (char*)"char"; }
  | STRING_TYPE { $$ = (char*)"string"; }
  | BOOL_TYPE   { $$ = (char*)"bool"; }
  ;


bool_expr:
    bool_expr OR bool_expr
    {
      if (strcmp($<sval>1,"bool")==0 && strcmp($<sval>3,"bool")==0) {
         $$ = (char*)"bool";
      } else {
         cerr << "[Linia " << yylineno << "] Type mismatch la '||': " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      }
    }
  | bool_expr AND bool_expr
    {
      if (strcmp($<sval>1,"bool")==0 && strcmp($<sval>3,"bool")==0) {
         $$ = (char*)"bool";
      } else {
         cerr << "[Linia " << yylineno << "] Type mismatch la '&&': " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      }
    }
  | NOT bool_expr
    {
      if (strcmp($<sval>2,"bool")==0) {
         $$ = (char*)"bool";
      } else {
         cerr << "[Linia " << yylineno << "] Type mismatch la '!': " 
              << $<sval>2 << endl;
         $$ = (char*)"invalida";
      }
    }
  | TRUE    { $$ = (char*)"bool"; }
  | FALSE   { $$ = (char*)"bool"; }
  | comparison_expr { $$ = $<sval>1; }
  ;


comparison_expr:
    bool_expr EQ bool_expr
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare: " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | bool_expr NEQ bool_expr
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare: " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | expression LT expression
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare (LT) " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | expression GT expression
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare (GT) " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | expression LE expression
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare (<=) " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | expression GE expression
    {
      if (strcmp($<sval>1,"invalida")==0 || strcmp($<sval>3,"invalida")==0) {
         $$ = (char*)"invalida";
      }
      else if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Cannot compare (>=) " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }
  | expression
    { $$ = $<sval>1; }
  ;


expression:
    expression PLUS term
    {
      if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Type mismatch la +: " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = $<sval>1;
      }
    }
  | expression MINUS term
    {
      if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Type mismatch la -: "
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = $<sval>1;
      }
    }
  | term
    { $$ = $<sval>1; }
  ;


term:
    term STAR factor
    {
      if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Type mismatch la *: " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = $<sval>1;
      }
    }
  | term SLASH factor
    {
      if (strcmp($<sval>1,$<sval>3)!=0) {
         cerr << "[Linia " << yylineno << "] Type mismatch la /: " 
              << $<sval>1 << " vs " << $<sval>3 << endl;
         $$ = (char*)"invalida";
      } else {
         $$ = $<sval>1;
      }
    }
  | factor
    { $$ = $<sval>1; }
  ;


factor:
    INT
    {
      $$ = (char*)"int";
    }
  | FLOAT
    {
      $$ = (char*)"float";
    }
  | CHAR
    {
      $$ = (char*)"char";
    }
  | STRING
    {
      $$ = (char*)"string";
    }
  | ID
    {
      SymbolInfo* si = currentSymTable->searchSymbol($<sval>1);
      if (!si) {
         cerr << "[Linia " << yylineno << "] Semantic error: '" 
              << $<sval>1 << "' nedefinita.\n";
         $$ = (char*)"invalida";
      } else {
         $$ = (char*) strdup(si->type.c_str());
      }
      free($<sval>1);
    }

  | ID '[' expression ']'
    {
      SymbolInfo* found = currentSymTable->searchSymbol($<sval>1);
      if (!found) {
         cerr << "[Linia " << yylineno << "] Semantic error: Vector '" 
              << $<sval>1 << "' nu e definit.\n";
         $$ = (char*)"invalida";
      }
      else if (VecInfo* v = dynamic_cast<VecInfo*>(found)) {
         $$ = (char*) strdup(v->type.c_str());
      } else {
         cerr << "[Linia " << yylineno << "] Semantic error: '" 
              << $<sval>1 << "' nu e vector.\n";
         $$ = (char*)"invalida";
      }
      free($<sval>1);
    }

  | ID PARANTEZAS arg_list PARANTEZAD
    {
      SymbolInfo* found = currentSymTable->searchSymbol($<sval>1);
      if (!found) {
         cerr << "[Linia " << yylineno << "] Semantic error: Functia '" 
              << $<sval>1 << "' nu e definita.\n";
         $$ = (char*)"invalida";
      }
      else if (FnInfo* fn = dynamic_cast<FnInfo*>(found)) {
         $$ = (char*) strdup(fn->type.c_str());
      }
      else {
         cerr << "[Linia " << yylineno << "] Semantic error: '" 
              << $<sval>1 << "' nu e functie.\n";
         $$ = (char*)"invalida";
      }
      free($<sval>1);
      free($<sval>3);
    }


  | ID PUNCT ID PARANTEZAS arg_list PARANTEZAD  
    {
      SymbolInfo* siObj = currentSymTable->searchSymbol($<sval>1);
      if (!siObj) {
         cerr << "[Linia " << yylineno << "] Semantic error: Obiect '" 
              << $<sval>1 << "' nu e definit.\n";
      }
       
      
      SymbolInfo* siMethod = currentSymTable->searchSymbol($<sval>3);
      if (!siMethod) {
         cerr << "[Linia " << yylineno << "] Semantic error: Metoda '" 
              << $<sval>3 << "' nu e definita.\n";
         $$ = (char*)"invalida";
      }
      else if (FnInfo* fn = dynamic_cast<FnInfo*>(siMethod)) {
         $$ = (char*) strdup(fn->type.c_str());
      }
      else {
         cerr << "[Linia " << yylineno << "] Semantic error: '" 
              << $<sval>3 << "' nu e functie (metoda).\n";
         $$ = (char*)"invalida";
      }
      free($<sval>1);
      free($<sval>3);
      free($<sval>5);
    }

  | PARANTEZAS bool_expr PARANTEZAD
    {
      if (strcmp($<sval>2,"invalida")==0) {
         $$ = (char*)"invalida";
      } else {
         $$ = (char*)"bool";
      }
    }

 
  | NEW type PARANTEZAS arg_list PARANTEZAD
    {
      $$ = (char*)"object";
      free($<sval>4);
    }
  |ID PUNCT ID  
  ;


arg_list:
      /* empty */
    {
      $$ = strdup("");
    }
  | arg_list_nonempty
    {
      $$ = $<sval>1;
    }
  ;

arg_list_nonempty:
    bool_expr
    {
      $$ = strdup($<sval>1);
    }
  | arg_list_nonempty VIRGULA bool_expr
    {
      char* tmp = concatCSV($<sval>1, $<sval>3);
      free($<sval>1);
      $$ = tmp;
    }
  ;
  
bool_expression_ast:
      bool_expression_ast OR bool_expression_ast
    {
      
      $$ = new ASTNode("OP","||",$1,$3);
    }
  | bool_expression_ast AND bool_expression_ast
    {
      
      $$ = new ASTNode("OP","&&",$1,$3);
    }
  | NOT bool_expression_ast
    {
      
      $$ = new ASTNode("OP","!",$2,nullptr);
    }
  | TRUE
    {
      
      $$ = new ASTNode("BOOL_LIT","true");
    }
  | FALSE
    {
      $$ = new ASTNode("BOOL_LIT","false");
    }
  | comparison_expression_ast
    {
      
      $$ = $1;
    }
  ;
  
  comparison_expression_ast:
      expression_ast EQ expression_ast
    {

      $$ = new ASTNode("OP","==",$1,$3);
    }
  | expression_ast NEQ expression_ast
    {
      $$ = new ASTNode("OP","!=",$1,$3);
    }
  | expression_ast LT expression_ast
    {
      $$ = new ASTNode("OP","<",$1,$3);
    }
  | expression_ast GT expression_ast
    {
      $$ = new ASTNode("OP",">",$1,$3);
    }
  | expression_ast LE expression_ast
    {
      $$ = new ASTNode("OP","<=",$1,$3);
    }
  | expression_ast GE expression_ast
    {
      $$ = new ASTNode("OP",">=",$1,$3);
    }

  | expression_ast
    {
      $$ = $1;
    }
  ;
    
  
expression_ast:
      expression_ast PLUS term_ast
    {
     
      $$ = new ASTNode("OP", "+", $1, $3);
    }
  | expression_ast MINUS term_ast
    {
      $$ = new ASTNode("OP", "-", $1, $3);
    }
  | term_ast
    {
      $$ = $1;
    }
  ;

term_ast:
      term_ast STAR factor_ast
    {
      $$ = new ASTNode("OP","*",$1,$3);
    }
  | term_ast SLASH factor_ast
    {
      $$ = new ASTNode("OP","/",$1,$3);
    }
  | factor_ast
    {
      $$ = $1;
    }
  ;
 
factor_ast:
      INT
    {
      char buf[32]; 
      snprintf(buf,sizeof(buf),"%d",$1);
      $$ = new ASTNode("INT_LIT", buf);
    }
  | FLOAT
    {
      char buf[64]; 
      snprintf(buf,sizeof(buf),"%g",$1);
      $$ = new ASTNode("FLOAT_LIT", buf);
    }
  | CHAR
    {
      
      char tmp[2] = {0,0};
      tmp[0] = $1;  
      $$ = new ASTNode("CHAR_LIT", tmp);
    }
  | STRING
    {
      
      $$ = new ASTNode("STRING_LIT",$<sval>1);
      free($<sval>1);
    }
  | ID
    {
      $$ = new ASTNode("ID",$<sval>1);
      free($<sval>1);
    }
  | PARANTEZAS bool_expression_ast PARANTEZAD
    {
      $$ = $2;
    }
  
   ;
%%

void yyerror(const char *s) {

    cerr << "[Linia " << yylineno << "] Error: " << s << endl;
    errorCount++;
}

int main(int argc, char** argv) {
    if (argc > 1) {
        yyin = fopen(argv[1], "r");
    }
    if (yyparse() == 0) {
        printf("Succes\n");
    } else {
        printf("Eroare de sintaxa\n");
    }
    return 0;
}
