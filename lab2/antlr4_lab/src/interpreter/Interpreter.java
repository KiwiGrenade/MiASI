package interpreter;
import java.util.Objects;

import SymbolTable.GlobalSymbols;
import SymbolTable.LocalSymbols;
import grammar.firstBaseVisitor;
import grammar.firstParser;
import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.TokenStream;
import org.antlr.v4.runtime.misc.Interval;


public class Interpreter extends firstBaseVisitor<Integer> {
    GlobalSymbols<Integer> globalVars = new GlobalSymbols<Integer>();
    LocalSymbols<Integer> localVars = new LocalSymbols<Integer>();

    private TokenStream tokStream = null;
    private CharStream input=null;
    public Interpreter(CharStream inp) {
        super();
        this.input = inp;
    }

    public Interpreter(TokenStream tok) {
        super();
        this.tokStream = tok;
    }
    public Interpreter(CharStream inp, TokenStream tok) {
        super();
        this.input = inp;
        this.tokStream = tok;
    }

    private String getText(ParserRuleContext ctx) {
        int a = ctx.start.getStartIndex();
        int b = ctx.stop.getStopIndex();
        if(input==null) throw new RuntimeException("Input stream undefined");
        return input.getText(new Interval(a,b));
    }

    @Override
    public Integer visitPrint_stat(firstParser.Print_statContext ctx) {
        var st = ctx.expr();
        var result = visit(st);
        System.out.println("> " + result);
        // System.out.printf("|%s=%d|\n", st.getText(), result); //nie drukuje ukrytych ani pominiętych spacji
        // System.out.printf("|%s=%d|\n", getText(st),  result); //drukuje wszystkie spacje
        //System.out.printf("|%s=%d|\n", tokStream.getText(st),  result); //drukuje spacje z ukrytego kanału, ale nie ->skip
        return result;

    }

    @Override
    public Integer visitProg(firstParser.ProgContext ctx) {
        Integer result = null;
        for (var child : ctx.children) {
            result = visit(child);
        }
        return result;
    }

    @Override
    public Integer visitDeclare_stat(firstParser.Declare_statContext ctx) {
        return visit(ctx.getChild(0));
    }

    @Override
    public Integer visitFor_stat(firstParser.For_statContext ctx) {
        localVars.enterScope();
        if (ctx.declare_expr() != null) {
            visit( ctx.declare_expr() );
        }

        while (ctx.cond == null || (visit(ctx.cond) != 0)) {
            visit(ctx.body);
            if (ctx.post != null) {
                visit(ctx.post);
            }
        }

        localVars.leaveScope();
        return 0;
    }

    @Override
    public Integer visitInc_dec(firstParser.Inc_decContext ctx) {
        String variable_name = ctx.ID().getText();
        Integer endVal = 0;

        if (globalVars.hasSymbol(variable_name)) {
            if (ctx.DEC() != null) {
                globalVars.setSymbol(variable_name, globalVars.getSymbol(variable_name) - 1);
            }
            if (ctx.INC() != null) {
                globalVars.setSymbol(variable_name, globalVars.getSymbol(variable_name) + 1);
            }
            endVal = globalVars.getSymbol(variable_name);
        }
        else if (localVars.hasSymbol(variable_name)) {
            if (ctx.DEC() != null) {
                localVars.setSymbol(variable_name, localVars.getSymbol(variable_name) - 1);
            }
            if (ctx.INC() != null) {
                localVars.setSymbol(variable_name, localVars.getSymbol(variable_name) + 1);
            }
            endVal = localVars.getSymbol(variable_name);
        }
        else {
            throw new RuntimeException("Variable " + variable_name + " not defined");
        }

        return endVal;
    }

    @Override
    public Integer visitDeclare_expr(firstParser.Declare_exprContext ctx) {
        Integer value = 0;
        if (ctx.INIT() != null) {
            value = visit(ctx.expr());
        }

        String varName = ctx.ID().getText();

        if(!globalVars.hasSymbol(varName)) {
            globalVars.newSymbol(varName);
            globalVars.setSymbol(varName, value);
        }
        else if (!localVars.hasSymbol(varName)) {
            localVars.newSymbol(varName);
            localVars.setSymbol(varName, value);
        }

        return value;
    }

    @Override
    public Integer visitVar_tok(firstParser.Var_tokContext ctx) {
        String varName = ctx.ID().getText();
        if (localVars.hasSymbol(varName)) {
            return localVars.getSymbol(varName);
        }
        else if(globalVars.hasSymbol(varName)) {
            return globalVars.getSymbol(varName);
        }
        else {
            throw new RuntimeException("Variable " + varName + " not defined");
        }
    }

    @Override
    public Integer visitExpr_stat(firstParser.Expr_statContext ctx) {
        return visit(ctx.getChild(0));
    }

    @Override
    public Integer visitIf_stat(firstParser.If_statContext ctx) {
        Integer result = 0;
        if (visit(ctx.cond)!=0) {
            result = visit(ctx.then);
        }
        else {
            if(ctx.else_ != null)
                result = visit(ctx.else_);
        }
        return result;
    }

    @Override
    public Integer visitBlock_single(firstParser.Block_singleContext ctx) {
        return visit(ctx.getChild(0));
    }

    @Override
    public Integer visitBlock_real(firstParser.Block_realContext ctx) {
        localVars.enterScope();
        Integer result = null;
        for (var child : ctx.children) {
            result = visit(child);
        }
        localVars.leaveScope();
        return result;
    }

    @Override
    public Integer visitInt_tok(firstParser.Int_tokContext ctx) {
        return Integer.parseInt(ctx.INT().getText());
    }

    @Override
    public Integer visitPars(firstParser.ParsContext ctx) {
        return visit(ctx.expr());
    }

    @Override
    public Integer visitBinOp(firstParser.BinOpContext ctx) {
        Integer left = visit(ctx.expr(0));
        Integer right = visit(ctx.expr(1));
        String op = ctx.getChild(1).getText();

        return switch (op) {
            case "+" -> left + right;
            case "-" -> left - right;
            case "*" -> left * right;
            case "/" -> {
                if (right == 0) {
                    throw new ArithmeticException("Dzielenie przez zero");
                }
                yield left / right;
            }
            case ">" -> left > right ? 1 : 0;
            case "<" -> left < right ? 1 : 0;
            case "=="-> Objects.equals(left, right) ? 1 : 0;
            case ">=" -> left >= right ? 1 : 0;
            case "<=" -> left <= right ? 1 : 0;
            case "!="-> !Objects.equals(left, right) ? 1 : 0;
            case "or"-> (left != 0 || right != 0) ? 1 : 0;
            case "and"-> (left != 0 && right != 0) ? 1 : 0;
            default -> throw new RuntimeException("Nieznany operator: " + op);
        };
    }

    @Override
    public Integer visitAssign(firstParser.AssignContext ctx) {
        Integer value = visit(ctx.expr());
        String varName = ctx.ID().getText();
        if(localVars.hasSymbol(varName)) {
            localVars.setSymbol(varName, value);
        }
        else if(globalVars.hasSymbol(varName)) {
            globalVars.setSymbol(varName, value);
        }
        return value;
    }
}