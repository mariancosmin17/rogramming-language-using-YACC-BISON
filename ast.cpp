#include "ast.h"
#include <iostream>
#include <cstdlib>   
#include <cstring>   
#include <cstdio>    

std::pair<std::string, std::string> ASTNode::evaluate() 
{
    
    if (!left && !right) 
    {
        if (nodeType == "INT_LIT") {
            return {"int", val};
        } 
        if (nodeType == "FLOAT_LIT") {
            return {"float", val};
        } 
        if (nodeType == "BOOL_LIT") {
            return {"bool", val};
        }
        if (nodeType == "CHAR_LIT") {
            return {"char", val};
        }
        if (nodeType == "STRING_LIT") {
            return {"string", val};
        }
        if (nodeType == "ID") {
            
            return {"int", "0"};
        }

        
        return {"invalida", "0"};
    }

    
    std::pair<std::string, std::string> L = left->evaluate();
    std::pair<std::string, std::string> R = (right ? right->evaluate()
                                                   : std::make_pair("", ""));

 
    auto isInt = [](const std::string &t){ return t == "int"; };
    auto isFloat = [](const std::string &t){ return t == "float"; };
    auto isBool = [](const std::string &t){ return t == "bool"; };

    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        if ( (isInt(L.first) && isInt(R.first)) ) 
        {
            // ambele int
            int lv = std::atoi(L.second.c_str());
            int rv = std::atoi(R.second.c_str());
            int result = 0;
            if (op == "+")      result = lv + rv;
            else if (op == "-") result = lv - rv;
            else if (op == "*") result = lv * rv;
            else if (op == "/") {
                if (rv == 0) {
                    return {"error", "Impartire la zero"};
                }
                result = lv / rv; // div int
            }
            return {"int", std::to_string(result)};
        }
        else if ( (isFloat(L.first) && isFloat(R.first)) )
        {
            // ambele float
            double lv = std::atof(L.second.c_str());
            double rv = std::atof(R.second.c_str());
            double result = 0.0;
            if (op == "+")      result = lv + rv;
            else if (op == "-") result = lv - rv;
            else if (op == "*") result = lv * rv;
            else if (op == "/") {
                if (rv == 0.0) {
                    return {"error", "Impartire la zero"};
                }
                result = lv / rv;
            }
            
            // convertim la string
            char buf[64];
            std::snprintf(buf, sizeof(buf), "%g", result);
            return {"float", std::string(buf)};
        }
        else {
          
            return {"error", "Operatie aritmetica incompatibila intre " + L.first + " si " + R.first};
        }
    }

    else if (op == "&&" || op == "||") 
    {

        if (!isBool(L.first) || !isBool(R.first)) {
            return {"error", "Operator logic " + op + " cerut intre tipuri non-bool"};
        }
        
        bool lb = (L.second == "true");
        bool rb = (R.second == "true");
        bool rez = false;
        if (op == "&&") rez = lb && rb;
        else            rez = lb || rb;

        return {"bool", rez ? "true" : "false"};
    }
    else if (op == "!")
    {

        if (!isBool(L.first)) {
            return {"error", "Operator '!' cerut pe un tip non-bool"};
        }
        bool lb = (L.second == "true");
        bool rez = !lb;
        return {"bool", rez ? "true":"false"};
    }

    else if (op == "<"  || op == ">"  || op == "==" || 
             op == "!=" || op == "<=" || op == ">=")
    {

        bool areBothInt = (isInt(L.first) && isInt(R.first));
        bool areBothFloat = (isFloat(L.first) && isFloat(R.first));

        if (!areBothInt && !areBothFloat) {
            return {"error", "Operator de comparatie '" + op + 
                    "' intre tipuri incompatibile: " + L.first + ", " + R.first};
        }

        // Daca sunt int:
        if (areBothInt) {
            int lv = std::atoi(L.second.c_str());
            int rv = std::atoi(R.second.c_str());
            bool rez = false;
            if (op == "<")       rez = (lv < rv);
            else if (op == ">")  rez = (lv > rv);
            else if (op == "==") rez = (lv == rv);
            else if (op == "!=") rez = (lv != rv);
            else if (op == "<=") rez = (lv <= rv);
            else if (op == ">=") rez = (lv >= rv);

            return {"bool", rez ? "true" : "false"};
        }
        else {
            // ambele float
            double lv = std::atof(L.second.c_str());
            double rv = std::atof(R.second.c_str());
            bool rez = false;
            if (op == "<")       rez = (lv < rv);
            else if (op == ">")  rez = (lv > rv);
            else if (op == "==") rez = (lv == rv);
            else if (op == "!=") rez = (lv != rv);
            else if (op == "<=") rez = (lv <= rv);
            else if (op == ">=") rez = (lv >= rv);

            return {"bool", rez ? "true" : "false"};
        }
    }

    return {"invalida", "0"};
}
