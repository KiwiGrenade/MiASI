grammar first;

prog :	stat* EOF;

stat : expr #expr_stat
    | IF_kw '(' cond=expr ')' then=block  ('else' else=block)? #if_stat
    | declare_expr #declare_stat
    | PRINT_kw expr #print_stat
    | FOR_kw '(' declare_expr? ';' cond=expr ';' post=expr? ')' body=block #for_stat
    | DEF_kw name=ID '(' (first=ID (',' rest+=ID)*)? ')' body=block #func_def_stat
    | name=ID '(' (first=ID (',' rest+=ID)*)? ')' #func_call_stat
    ;

declare_expr : 'let' ID ( ASSIGN expr )?;

block : stat #block_single
    | '{' block* '}' #block_real
    ;

expr :  l=expr op=(MUL|DIV) r=expr #binOp
    |	l=expr op=(ADD|SUB) r=expr #binOp
    |   l=expr op=(GE|LE|EQ|GEQ|LEQ|NEQ) r= expr #binOp
    |   l=expr op=(AND|OR) r= expr #binOp
    |   ID (INC|DEC) #inc_dec
    |	INT #int_tok
    |   ID #var_tok
    |	'(' expr ')' #pars
    |   <assoc=right> ID '=' expr # assign
    ;

// function
DEF_kw : 'def' ;

// printing
PRINT_kw : 'print' ;

// conditionals
IF_kw : 'if' ;
FOR_kw : 'for' ;

// operators
    ASSIGN : '=' ;
    // logical
    AND : 'and' ;
    OR : 'or' ;

    // comparison
    GE : '>' ;
    LE : '<' ;
    GEQ : '>=' ;
    LEQ : '<=' ;
    NEQ : '!=' ;
    EQ : '==' ;

    // increment and decrement
    INC : '++' ;
    DEC : '--' ;

    // arithmetic
    DIV : '/' ;
    MUL : '*' ;
    SUB : '-' ;
    ADD : '+' ;

//NEWLINE : [\r\n]+ -> skip;
NEWLINE : [\r\n]+ -> channel(HIDDEN);

//WS : [ \t]+ -> skip ;
WS  : [ \t]+ -> channel(HIDDEN) ;

INT : [0-9]+ ;
ID  : [a-zA-Z_][a-zA-Z0-9_]* ;

COMMENT : '/*' .*? '*/' -> channel(HIDDEN) ;
LINE_COMMENT : '//' ~'\n'* '\n' -> channel(HIDDEN) ;