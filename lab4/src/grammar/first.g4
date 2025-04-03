grammar first;

prog :	stat* EOF;

stat : expr #expr_stat
    | expr_log #expr_log_stat
    | IF_kw '(' cond=expr_log ')' then=block  ('else' else=block)? #if_stat
    | declare_expr #declare_stat
    | PRINT_kw expr #print_stat
    | FOR_kw '(' declare_expr? ';' cond=expr_log ';' post=expr? ')' body=block #for_stat
//    | DEF_kw name=ID '(' params? ')' body=block #func_def_stat
//    | name=ID '(' args ')' #func_call_stat
    ;

//params: ID (',' ID)*;

//args: (ID|INT) (',' (ID|INT))*;

declare_expr : 'let' ID ( ASSIGN expr )?;

block : stat #block_single
    | '{' block* '}' #block_real
    ;

expr_log: NOT r=expr_log #logic_not
          |   l=expr op=(EQ|NEQ) r=expr #logic_comp
          |   l=expr op=(LE|GE|GEQ|LEQ) r=expr #logic_comp
          |   l=expr_log op=(AND|OR) r=expr_log #logic_and_or
          |   INT #logic_int_tok
          |   ID #logic_id_tok
          |	  '(' expr_log ')' #logic_pars
          ;

expr :  l=expr op=(MUL|DIV) r=expr #binOp
    |	l=expr op=(ADD|SUB) r=expr #binOp
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
    NOT : 'not' ;
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