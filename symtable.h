#ifndef SYMTABLE_H
#define SYMTABLE_H

#include <string>
#include <vector>
#include <unordered_map>
#include <iostream>
#include <fstream>
#include <iomanip>

extern int yylineno;

using namespace std;

struct SymbolInfo 
{
    string name;
    string type;
    string category;
    virtual ~SymbolInfo() = default;
};

struct VarInfo : SymbolInfo 
{
    string value;
    VarInfo(const string& n, const string& t) 
    {
        name = n;
        type = t;
        category = "variable";
    }
};

struct FnInfo : SymbolInfo 
{
    vector<string> parameters;
    FnInfo(const string& n, const string& returnT, const vector<string>& params) 
    {
        name = n;
        type = returnT;
        parameters = params;
        category = "function";
    }
};

struct VecInfo : SymbolInfo 
{
    size_t size;
    vector<string> values;
    VecInfo(const string& n, const string& t, size_t s): size(s), values(s, "0") 
    {
        name = n;
        type = t;
        category = "vector";
    }
};

struct ClsInfo : SymbolInfo 
{
    ClsInfo(const string& n)
    {
        name = n;
        type = "NULL";
        category = "class";
        
    }
};


struct InstrInfo : SymbolInfo
{
    InstrInfo(const string& instrName)
    {
        name = instrName;
        type = "NULL";   
        category = "instruction"; 
    }
};

class SymTable 
{
private:
    string scopeName;
    unordered_map<string, SymbolInfo*> symbols;
    SymTable* parentScope;
    vector<SymTable*> childScopes;

public:
    SymTable(const string& scope);
    ~SymTable();

    void insertVariable(const string& varName, const string& varType);
    void insertFunction(const string& fnName, const string& retType, const vector<string>& params);
    void insertClass(const string& className);
    void insertVector(const string& vecName, const string& vecType, const size_t& size);

    void insertInstruction(const string& instrName);

    void updateVariableValue(const string& varName, const string& newValue);
    void updateVectorItem(const string& vecName, int index, const string& newValue);

    SymTable* createSubScope(const string& newScope);
    SymTable* returnToParentScope();

    void displaySymbols();
    void dumpSymbolsToFile(const string& filename);
    void dumpSymbolsToFileRecursive(ofstream& outFile);

    SymbolInfo* searchSymbol(const string& symbolName);
    string inferType(const string& symbolName);
    vector<string> getFunctionParameters(const string& fnName);
};

#endif
