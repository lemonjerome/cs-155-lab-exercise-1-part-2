%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/* ── Parse-tree node ── */
typedef struct Node {
    char        *label;
    struct Node *children[3];
    int          num_children;
} Node;

int depth = 0;

void indent(int d) {
    for (int i = 0; i < d * 2; i++) putchar(' ');
}

Node *make_node(const char *label, int num_children, ...) {
    int i;
    va_list args;
    Node *n = (Node *)malloc(sizeof(Node));
    n->label        = strdup(label);
    n->num_children = num_children;
    va_start(args, num_children);
    for (i = 0; i < num_children && i < 3; i++)
        n->children[i] = va_arg(args, Node *);
    va_end(args);
    return n;
}

void print_tree(Node *n) {
    int i;
    if (!n) return;
    indent(depth);
    printf("%s\n", n->label);
    depth++;
    for (i = 0; i < n->num_children; i++)
        print_tree(n->children[i]);
    depth--;
}

void yyerror(const char *msg);
int  yylex(void);
%}
%union {
    int          ival;
    double       fval;
    struct Node *node;
}
%token <ival> NUM
%token <fval> FNUM
%token PLUS MINUS TIMES DIVIDE LPAREN RPAREN POWER
%left PLUS MINUS
%left TIMES DIVIDE
%right POWER
%right UMINUS
%type <node> expr term exponent factor
%%
program:
    expr {
        Node *root = make_node("None", 1, $1);
        print_tree(root);
    }
;

expr:
    expr PLUS term  { $$ = make_node("expr", 3, $1, make_node("+", 0), $3); }
  | expr MINUS term { $$ = make_node("expr", 3, $1, make_node("-", 0), $3); }
  | term            { $$ = make_node("expr", 1, $1); }
;

term:
    term TIMES exponent  { $$ = make_node("term", 3, $1, make_node("*", 0), $3); }
  | term DIVIDE exponent { $$ = make_node("term", 3, $1, make_node("/", 0), $3); }
  | exponent             { $$ = make_node("term", 1, $1); }
;

exponent:
    factor POWER exponent { $$ = make_node("exponent", 3, $1, make_node("^", 0), $3); }
  | factor               { $$ = make_node("exponent", 1, $1); }
;

factor:
    NUM {
        char buf[32];
        snprintf(buf, sizeof(buf), "%d", $1);
        $$ = make_node("factor", 1, make_node(buf, 0));
    }
  | LPAREN expr RPAREN {
        $$ = make_node("factor", 3, make_node("(", 0), $2, make_node(")", 0));
    }
  | MINUS factor %prec UMINUS {
        $$ = make_node("factor", 2, make_node("-", 0), $2);
    }
;
%%
void yyerror(const char *msg) {
fprintf(stderr, "Parse error: %s\n", msg);
}
int main(void) {
return yyparse();
}