grammar first;

prog:	stat* EOF ;

stat: expr #expr_stat
    | IF_kw '(' cond=expr ')' then=block  ('else' else=block)? #if_stat
    | declare_expr #declare_stat
    | PRINT_kw expr #print_stat
    | FOR_kw '(' declare_expr? ';' cond=expr ';' post=expr? ')' body=block #for_stat
    ;

declare_expr:
    ID ( INIT expr )? ;

block : stat #block_single
    | '{' block* '}' #block_real
    ;

expr:
        l=expr op=(MUL|DIV) r=expr #binOp
    |	l=expr op=(ADD|SUB) r=expr #binOp
    |   ID (INC|DEC) #inc_dec
    |	INT #int_tok
    |   ID #var_tok
    |	'(' expr ')' #pars
    |   l=expr op=(GE|LE|EQ|GEQ|LEQ|NEQ) r= expr #binOp
    |   l=expr op=(AND|OR) r= expr #binOp
    | <assoc=right> ID '=' expr # assign
    ;

INC : '++' ;
DEC : '--' ;

IF_kw : 'if' ;
PRINT_kw : 'print' ;
FOR_kw : 'for' ;

AND : 'and' ;
OR : 'or' ;

GE : '>' ;
LE : '<' ;
GEQ : '>=' ;
LEQ : '<=' ;
NEQ : '!=' ;
EQ : '==' ;


INIT : ':=' ;

DIV : '/' ;

MUL : '*' ;

SUB : '-' ;

ADD : '+' ;

//NEWLINE : [\r\n]+ -> skip;
NEWLINE : [\r\n]+ -> channel(HIDDEN);

//WS : [ \t]+ -> skip ;
WS : [ \t]+ -> channel(HIDDEN) ;

INT     : [0-9]+ ;


ID : [a-zA-Z_][a-zA-Z0-9_]* ;

COMMENT : '/*' .*? '*/' -> channel(HIDDEN) ;
LINE_COMMENT : '//' ~'\n'* '\n' -> channel(HIDDEN) ;