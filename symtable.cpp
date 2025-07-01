#include "symtable.h"
extern int yylineno;
SymTable::SymTable(const string& scope)
    : scopeName(scope), parentScope(nullptr) {}

SymTable::~SymTable() {
    for (auto& entry : symbols) {
        delete entry.second;
    }
    for (auto* child : childScopes) {
        delete child;
    }
}

void SymTable::insertVariable(const string& varName, const string& varType) {
    if (symbols.find(varName) != symbols.end()) {
        cout << "[Linia "<<yylineno<<"] Eroare: variabila " << varName 
             << " este deja definită în scope-ul " << scopeName << ".\n";
        return;
    }
    symbols[varName] = new VarInfo(varName, varType);
}

void SymTable::insertFunction(const string& fnName, const string& retType, const vector<string>& params) {
    if (symbols.find(fnName) != symbols.end()) {
        cout << "[Linia "<<yylineno<<"] Eroare: Funcția " << fnName 
             << " există deja în scope-ul " << scopeName << ".\n";
        return;
    }
    symbols[fnName] = new FnInfo(fnName, retType, params);
}

void SymTable::insertClass(const string& className) {
    if (symbols.find(className) != symbols.end()) {
        cout << "[Linia "<<yylineno<<"] Eroare: Clasa " << className 
             << " există deja în scope-ul " << scopeName << ".\n";
        return;
    }
    symbols[className] = new ClsInfo(className);
}

void SymTable::insertInstruction(const string& instrName) {
    if (symbols.find(instrName) != symbols.end()) {
        cout << "[Linia "<<yylineno<<"] Eroare: Instrucțiunea '" << instrName 
             << "' există deja în scope-ul " << scopeName << ".\n";
        return;
    }
    symbols[instrName] = new InstrInfo(instrName);
}

void SymTable::insertVector(const string& vecName, const string& vecType, const size_t& size) {
    if (symbols.find(vecName) != symbols.end()) {
        cout << "Eroare: vectorul " << vecName 
             << " este deja declarat în scope-ul " << scopeName << ".\n";
        return;
    }
    symbols[vecName] = new VecInfo(vecName, vecType, size);
}

void SymTable::updateVariableValue(const string& varName, const string& newValue) {
    SymbolInfo* si = searchSymbol(varName);
    if (!si) {
        cout << "[Linia "<<yylineno<<"] Eroare: Variabila " << varName << " nu a fost găsită.\n";
        return;
    }
    if (VarInfo* varPtr = dynamic_cast<VarInfo*>(si)) {
        varPtr->value = newValue;
        
    } else {
        cout << "[Linia "<<yylineno<<"] Eroare: " << varName << " nu este o variabilă.\n";
    }
}

void SymTable::updateVectorItem(const string& vecName, int index, const string& newValue) {
    SymbolInfo* si = searchSymbol(vecName);
    if (!si) {
        cout << "[Linia "<<yylineno<<"] Eroare: Vectorul " << vecName 
             << " nu a fost găsit.\n";
        return;
    }
    if (VecInfo* vecPtr = dynamic_cast<VecInfo*>(si)) {
        if (index < 0 || static_cast<size_t>(index) >= vecPtr->size) {
            cout << "[Linia "<<yylineno<<"] Eroare: Indexul " << index 
                 << " este în afara limitelor pentru vectorul " << vecName << ".\n";
            return;
        }
        vecPtr->values[index] = newValue;
        cout << "Elementul de la poziția " << index 
             << " din vectorul " << vecName << " a fost setat la " << newValue << ".\n";
    } else {
        cout << "[Linia "<<yylineno<<"] Eroare: " << vecName << " nu este un vector.\n";
    }
}

SymTable* SymTable::createSubScope(const string& newScope) {
    SymTable* child = new SymTable(newScope);
    child->parentScope = this;
    childScopes.push_back(child);
    return child;
}

SymTable* SymTable::returnToParentScope() {
    return parentScope;
}

void SymTable::displaySymbols() {
    cout << "=== Tabel de simboluri pentru scope-ul: " << scopeName << " ===\n";
    cout << left 
         << setw(15) << "Nume"
         << setw(15) << "Tip"
         << setw(15) << "Categorie"
         << setw(20) << "Valoare/Extra" 
         << '\n';
    cout << string(70, '-') << '\n';

    for (const auto& kv : symbols) {
        SymbolInfo* info = kv.second;

        cout << left 
             << setw(15) << info->name
             << setw(15) << info->type
             << setw(15) << info->category;

        if (auto* var = dynamic_cast<VarInfo*>(info)) {
            
            cout << setw(20) << var->value;
        }
        else if (auto* fn = dynamic_cast<FnInfo*>(info)) {
            
            cout << setw(20) << ("-"); 
        }
        else if (auto* vec = dynamic_cast<VecInfo*>(info)) {
            
            string infoVal = "size=" + to_string(vec->size);
            
            cout << setw(20) << infoVal;
        }
        else if (auto* cls = dynamic_cast<ClsInfo*>(info)) {
       
            cout << setw(20) << "-";
        }
        else if (auto* instr = dynamic_cast<InstrInfo*>(info)) {
            
            cout << setw(20) << "-";
        }
        else {
            
            cout << setw(20) << "-";
        }
        cout << '\n';
    }

    
    for (auto* child : childScopes) {
        child->displaySymbols();
    }
}


void SymTable::dumpSymbolsToFile(const string& filename) {
    ofstream outFile(filename, ios::trunc);
    if (!outFile.is_open()) {
        cerr << "Eroare la deschiderea fișierului " << filename 
             << " pentru scriere.\n";
        return;
    }
    dumpSymbolsToFileRecursive(outFile);
    outFile.close();
}

void SymTable::dumpSymbolsToFileRecursive(ofstream& outFile) {
    outFile << "=== Symbol Table for scope: " << scopeName << " ===\n";
    outFile << left 
            << setw(15) << "Nume"
            << setw(15) << "Tip"
            << setw(15) << "Categorie"
            << setw(20) << "Valoare/Extra"
            << '\n';
    outFile << string(70, '-') << '\n';

    for (const auto& kv : symbols) {
        SymbolInfo* info = kv.second;
        outFile << left
                << setw(15) << info->name
                << setw(15) << info->type
                << setw(15) << info->category;

        if (auto* var = dynamic_cast<VarInfo*>(info)) {
            outFile << setw(20) << var->value;
        }
        else if (auto* fn = dynamic_cast<FnInfo*>(info)) {
            outFile << setw(20) << ("params=" + to_string(fn->parameters.size()));
        }
        else if (auto* vec = dynamic_cast<VecInfo*>(info)) {
            string infoVal = "size=" + to_string(vec->size);
            outFile << setw(20) << infoVal;
        }
        else if (auto* cls = dynamic_cast<ClsInfo*>(info)) {
            outFile << setw(20) << "-";
        }
        else {
            outFile << setw(20) << "-";
        }
        outFile << '\n';
    }

    for (auto* child : childScopes) {
        child->dumpSymbolsToFileRecursive(outFile);
    }
}

SymbolInfo* SymTable::searchSymbol(const string& symbolName) {
    if (symbols.find(symbolName) != symbols.end()) {
        return symbols[symbolName];
    }
    if (parentScope) {
        return parentScope->searchSymbol(symbolName);
    }
    return nullptr;
}

string SymTable::inferType(const string& symbolName) {
    if (symbols.find(symbolName) != symbols.end()) {
        return symbols[symbolName]->type;
    }
    if (parentScope) {
        return parentScope->inferType(symbolName);
    }
    
    return nullptr;
}

vector<string> SymTable::getFunctionParameters(const string& fnName) {
    if (symbols.find(fnName) != symbols.end()) {
        if (auto* func = dynamic_cast<FnInfo*>(symbols[fnName])) {
            return func->parameters;
        }
    }
    if (parentScope) {
        return parentScope->getFunctionParameters(fnName);
    }
    return {};
}
