grammar first;

prog:	stat* EOF ;

stat:   var_init #expr_stat
    |   var_decl #var_decl_stat
    |   var_assign #var_assign_stat
    |   IF_kw '(' cond=cond_expr ')' then=block  ('else' else=block)? #if_stat
    |   '>' expr #print_stat
    ;

block:  stat #block_single
    |   '{' block* '}' #block_real
    ;

int_expr:   int_expr (MUL|DIV) int_expr #binOp
    |	int_expr (ADD|SUB) int_expr #binOp
    |	INT #int_tok
    |	ID #id_tok
    |	'(' int_expr ')' #pars
//    |   <assoc=right> ID '=' expr #assign
    ;

bool_expr: l=bool_expr r_list+=(op=(AND|OR) r=bool_expr)* #boolOp
    |  '!' bool_expr #negation
    |   TRUE #true
    |   FALSE #false
    |   '(' bool_expr ')' #pars
    ;

comp_expr: l=int_expr op=(LT|LE|GT|GE|EQ|NE) r=int_expr #compOp
    |   '(' comp_expr ')' #pars
    ;

cond_expr: comp_expr (op=(AND|OR) cond_expr)* #condOp
    |   bool_expr
    ;



bool_var_decl: 'bool' ID #var_decl
    ;

bool_var_init: 'bool' ID '=' int_expr #var_init
    ;

int_var_decl: 'int' ID #var_decl
    ;

int_var_init: 'int' ID '=' int_expr #var_init
    ;

var_init: int_var_init #int_var_init
    | bool_var_init #bool_var_init
    ;

var_decl: int_var_decl #int_var_decl
    | bool_var_decl #bool_var_decl
    ;

var_assign: ID '=' (int_expr|bool_expr) #var_assign
    ;

IF_kw : 'if' ;

DIV : '/' ;

MUL : '*' ;

SUB : '-' ;

ADD : '+' ;

LT : '<' ;

LE : '<=' ;

GT : '>' ;

GE : '>=' ;

EQ : '==' ;

NE : '!=' ;

AND : '&&' ;

OR : '||' ;

TRUE : 'true' ;

FALSE : 'false' ;

//NEWLINE : [\r\n]+ -> skip;
NEWLINE : [\r\n]+ -> channel(HIDDEN);

//WS : [ \t]+ -> skip ;
WS : [ \t]+ -> channel(HIDDEN) ;

INT     : [0-9]+ ;

ID : [a-zA-Z_][a-zA-Z0-9_]* ;

COMMENT : '/*' .*? '*/' -> channel(HIDDEN) ;
LINE_COMMENT : '//' ~'\n'* '\n' -> channel(HIDDEN) ;