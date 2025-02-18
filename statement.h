#ifndef STATEMENT_H
#define STATEMENT_H

#include <string.h>
#include <stdlib.h>

extern int currentScope;
typedef enum {
    STMT_DECLARATION,
    STMT_ASSIGNMENT,
    STMT_IF,
    STMT_WHILE,
    STMT_PRINT,
    STMT_READ,
    STMT_FUNCTION_CALL,
    STMT_RETURN,
    STMT_COMMENT,
    STMT_BLOCK
} StatementType;



typedef enum{
    EXPR_LITERAL,
    EXPR_VARIABLE,
    EXPR_OPERATION
} ExpressionType;


typedef struct Expression {
    ExpressionType type;
    int casted;  // 
    int varType;          //Tipul variabilei (0 pentru int, 1 pentru float, 2 pentru double
    union {
        int ival;
        float fval;
        double dval;
    } value;
    char* varName;
    struct Expression* left;   
    struct Expression* right;  
    int oper;             
} Expression;

typedef struct{
    int type;
    union {
        int ival;
        float fval;
        double dval;
    } value;
}ExpressionResult;

typedef struct Condition {
    int isTrue;      // Rezultatul evaluării condiției (1 pentru adevărat, 0 pentru fals)
    Expression leftExpr;   // Expresia din stânga operatorului
    Expression rightExpr;  // Expresia din dreapta operatorului
    int oper;    // Operatorul de comparație (TOK_LT, TOK_GT, etc.)
} Condition;

struct Block;

typedef struct Statement {
    StatementType type;
    union {
        struct {  
            char* varName;
            int varType;
            Expression* initialValue;
        } declaration;
        
        struct {  
            char* varName;
            Expression* value;
        } assignment;
        
        struct {  
            Condition* condition;
            struct Block* thenBlock;
            struct Block* elseBlock;
        } ifStmt;
        
        struct {  
            Condition* condition;
            struct Block* body;
        } whileStmt;
        
        struct {  
            Expression* value;
        } print;
        
        struct {  
            char* varName;
        } read;
        
        struct {  
            char* funcName;
            ListNode* argList;
            int argCount;
        } functionCall;
        
        struct {  
            Expression* value;
        } returnStmt;

        struct Block* block;
    } data;
    struct Statement* next;  
} Statement;


typedef struct Block {
    Statement* firstStmt;
    int stmtCount;
    int scopeLevel;
} Block;





Statement* createAssignmentStmt(char* varName, Expression* value) {
    Statement* stmt = (Statement*)malloc(sizeof(Statement));
    stmt->type = STMT_ASSIGNMENT;
    stmt->data.assignment.varName = strdup(varName);
    stmt->data.assignment.value = value;
    stmt->next = NULL;
    return stmt;
}


// Block* createBlock() {
//     Block* block = (Block*)malloc(sizeof(Block));
//     block->firstStmt = NULL;
//     block->stmtCount = 0;
//     block->scopeLevel = currentScope;
//     return block;
// }

// void addStatementToBlock(Block* block, Statement* stmt) {
//     if (block->firstStmt == NULL) {
//         block->firstStmt = stmt;
//     } else {
//         Statement* current = block->firstStmt;
//         while (current->next != NULL) {
//             current = current->next;
//         }
//         current->next = stmt;
//     }
//     block->stmtCount++;
// }


Statement* createDeclarationStmt(char* varName, int varType, Expression* initialValue) {
    Statement* stmt = (Statement*)malloc(sizeof(Statement));
    stmt->type = STMT_DECLARATION;
    stmt->data.declaration.varName = strdup(varName);
    stmt->data.declaration.varType = varType;
    stmt->data.declaration.initialValue = initialValue;
    stmt->next = NULL;
    return stmt;
}



#endif