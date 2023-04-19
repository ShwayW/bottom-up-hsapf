/*
 * ------------------------------
 * Syntax Tree and Parsing
 * Matt Gallivan
 * ------------------------------
 */

#include <ctype.h>
#include <cfloat>
#include <iostream>
#include <queue> 
#include <unordered_map>
#include <algorithm> 
#include <limits>
#include <vector>

typedef int64_t i64;
typedef uint64_t u64;

typedef struct Tree Tree;

using namespace std;

/* Parse an expression string and return a syntax tree. */
Tree* parse(const char* expr);

typedef enum { CONSTANT, IF, OPERATOR, VARIABLE } TreeType;
typedef enum { ADD, LT, MUL, SUB, } TreeOp;
typedef enum { G, H } TreeVar;

struct Tree {
    Tree *left, *right;
    TreeType type;
    union {
        Tree* condition;
        double constant;
        TreeOp op;
        TreeVar variable;
    } data;
};

/* Parser helper functions. */
Tree* parse_constant(const char* expr);
Tree* parse_led(Tree* tree, const char* expr);
Tree* parse_nud(const char* expr);
Tree* parse_pratt(const char* expr, size_t prec);
size_t precedence(char c);

/* Create a tree representing a constant value. */
Tree* tree_constant(double constant);

/* Create a tree representing an if-statement. */
Tree* tree_if(Tree* condition, Tree* left, Tree* right);

/* Free a tree and all of its children. */
void tree_free(Tree* tree);

/* Create a tree representing an operator on two sub-trees. */
Tree* tree_operator(TreeOp op, Tree* left, Tree* right);

/* Print a tree. */
void tree_print(const Tree* tree);

/* Calculate the priority function score given an expression string. */
double tree_priority(const Tree* tree, i64 h, i64 g);

/* Create a tree representing a variable value. */
Tree* tree_variable(TreeVar variable);

/*
 * ------------------------------
 * Parsing Implementation
 * ------------------------------
 */

size_t loc = 0;  /* Track the current token in the parsed string. */

Tree* parse(const char* expr) {
    loc = 0;
    return parse_pratt(expr, 0);
}

Tree* parse_constant(const char* expr) {
    if (!expr) return NULL;
    
    // Parse before decimal.
    double constant = 0.0;
    char c = expr[loc];
    do {
        constant = constant * 10 + c - '0';
        c = expr[++loc];
    } while (isdigit(c));
    
    // Parse after decimal if necessary.
    double e = 1.0;
    if (c == '.') {
        c = expr[++loc];
        do {
            constant = constant * 10 + c - '0';                    
            e *= 10;
            c = expr[++loc];
        } while (isdigit(c));
        constant = constant / e;
    }
    
    return tree_constant(constant);
}

Tree* parse_led(Tree* tree, const char* expr) {
    if (!tree || !expr) return NULL;
    char c = expr[loc++];
    switch (c) {
        case '+':
            return tree_operator(ADD, tree, parse_pratt(expr, precedence(c)));
        case '<':
            return tree_operator(LT, tree, parse_pratt(expr, precedence(c)));
        case '*':          
            return tree_operator(MUL, tree, parse_pratt(expr, precedence(c)));
        case '-':
            return tree_operator(SUB, tree, parse_pratt(expr, precedence(c)));
        case '(':
            return parse_pratt(expr, precedence(c));
        default: return NULL;
    }
}

Tree* parse_nud(const char* expr) {
    if (!expr) return NULL;
    char c = expr[loc++];
    // Parsing constants.
    if (isdigit(c)) {
        loc--;
        return parse_constant(expr);
    }
    // Parsing variables.
    else if (c == 'G') { return tree_variable(G); }
    else if (c == 'H') { return tree_variable(H); }
    // Parse an if statement.
    else if (c == 'i' && expr[loc] == 'f') {
        loc += 2;  // Skip past the '(' in the function call.
        Tree* condition = parse_pratt(expr, 0);
        loc++;  // Skip past the ','.
        Tree* left = parse_pratt(expr, 0);
        loc++;  // Skip past the ','.
        Tree* right = parse_pratt(expr, 0);
        loc++;  // Skip past the ')'.
        return tree_if(condition, left, right);
    }
    // Parsing parentheses.
    else if (c == '(') {
        Tree* tree = parse_pratt(expr, precedence(c));        
        loc++;  // Skip past the ')'.
        return tree;
    }
    // Parsing operators.
    else if (c == '+' || c == '*' || c == '-' || c == '<') {
        return parse_pratt(expr, precedence(c));
    }
    return NULL;
}

Tree* parse_pratt(const char* expr, size_t prec) {
    if (!expr) return NULL;    
    Tree* tree = parse_nud(expr);
    while (expr[loc] != '\0' && expr[loc] != ',' && precedence(expr[loc]) > prec) {
        tree = parse_led(tree, expr);
    }
    return tree;
}

size_t precedence(char c) {
    switch (c) {
        case ')': return 0;
        case '(': return 0;
        case '<': return 10;
        case '+': return 20;
        case '-': return 20;
        case '*': return 30;
        default: return 0;
    }
}

/*
 * ------------------------------
 * Syntax Tree Implementation
 * ------------------------------
 */

Tree* tree_constant(double constant) {
    Tree* tree = (Tree*) malloc(sizeof(*tree));
    if (!tree) return NULL;
    tree->left = NULL;
    tree->right = NULL;
    tree->type = CONSTANT;
    tree->data.constant = constant;
    return tree;
}

Tree* tree_if(Tree* condition, Tree* left, Tree* right) {
    if (!condition || !left || !right) return NULL;
    Tree* tree = (Tree*) malloc(sizeof(*tree));
    if (!tree) return NULL;
    tree->left = left;
    tree->right = right;
    tree->type = IF;
    tree->data.condition = condition;
    return tree;
}

void tree_free(Tree* tree) {
    if (!tree) return;
    tree_free(tree->left);
    tree_free(tree->right);
    free(tree);
}

Tree* tree_operator(TreeOp op, Tree* left, Tree* right) {
    if (!left || !right) return NULL;
    Tree* tree = (Tree*) malloc(sizeof(*tree));
    if (!tree) return NULL;
    tree->left = left;
    tree->right = right;
    tree->type = OPERATOR;
    tree->data.op = op;
    return tree;
}

static void tree_print_depth(const Tree* tree, size_t depth) {
    if (!tree) return;
    for (size_t i = 0; i < depth; ++i) { printf("  "); }
    switch (tree->type) {
        case CONSTANT:
            printf("%f\n", tree->data.constant);
            break;
        case IF:
            printf("IF\n");
            tree_print_depth(tree->data.condition, depth + 1);
            tree_print_depth(tree->left, depth + 1);
            tree_print_depth(tree->right, depth + 1);
            break;
        case OPERATOR: {
            switch (tree->data.op) {
                case ADD:
                    printf("+\n");
                    tree_print_depth(tree->left, depth + 1);
                    tree_print_depth(tree->right, depth + 1);
                    break;
                case LT:
                    printf("<\n");
                    tree_print_depth(tree->left, depth + 1);
                    tree_print_depth(tree->right, depth + 1);
                    break;
                case MUL:
                    printf("*\n");
                    tree_print_depth(tree->left, depth + 1);
                    tree_print_depth(tree->right, depth + 1);
                    break;
                case SUB:
                    printf("-\n");
                    tree_print_depth(tree->left, depth + 1);
                    tree_print_depth(tree->right, depth + 1);
                    break;
            }
            break;
        }
        case VARIABLE: {            
            switch (tree->data.variable) {
                case G:
                    printf("G\n");
                    break;
                case H: 
                    printf("H\n");
                    break;
            }
            break;
        }
    }
}

void tree_print(const Tree* tree) { tree_print_depth(tree, 0); }

double tree_priority(const Tree* tree, i64 h, i64 g) {
    if (!tree) return DBL_MAX;
    switch (tree->type) {
        case CONSTANT: {
            return tree->data.constant;
        }
        case IF: {
            if (tree_priority(tree->data.condition, h, g)) {
                return tree_priority(tree->left, h, g);
            }
            else {
                return tree_priority(tree->right, h, g);
            }
        }
        case OPERATOR: {
            switch (tree->data.op) {
                case ADD:
                    return tree_priority(tree->left, h, g) +
                           tree_priority(tree->right, h, g);
                case LT:
                    return tree_priority(tree->left, h, g) <
                           tree_priority(tree->right, h, g);
                case MUL:
                    return tree_priority(tree->left, h, g) *
                           tree_priority(tree->right, h, g);
                case SUB:
                    return tree_priority(tree->left, h, g) - 
                           tree_priority(tree->right, h, g);
                default:
                    return DBL_MAX;
            }
            break;
        }
        case VARIABLE: {
            switch (tree->data.variable) {
                case G: return g;
                case H: return h;
                default: return DBL_MAX;
            }
            break;
        }
        default: {
            return DBL_MAX;
        }
    }
}

Tree* tree_variable(TreeVar variable) {
    Tree* tree = (Tree*) malloc(sizeof(*tree));
    if (!tree) return NULL;
    tree->left = NULL;
    tree->right = NULL;
    tree->type = VARIABLE;
    tree->data.variable = variable;
    return tree;
}