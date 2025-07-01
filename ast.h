#ifndef AST_H
#define AST_H

#include <string>
#include <utility>  
#include <cstdio>   
#include <cstdlib>
#include <stdexcept> 


class ASTNode {
public:
    
    std::string nodeType; 
    
    std::string op;       

    std::string val;     
    
    ASTNode* left;
    ASTNode* right;

    
    ASTNode(const std::string &nType, const std::string &value)
      : nodeType(nType), op(""), val(value), left(nullptr), right(nullptr) {}

    ASTNode(const std::string &nType, const std::string &oper, ASTNode* l, ASTNode* r)
      : nodeType(nType), op(oper), left(l), right(r) {}

    ~ASTNode() {
        delete left;
        delete right;
    }

    std::pair<std::string, std::string> evaluate();
};

#endif 
