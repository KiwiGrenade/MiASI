package compiler;

import SymbolTable.LocalSymbols;
import grammar.firstLexer;
import org.antlr.v4.runtime.tree.TerminalNode;
import org.stringtemplate.v4.ST;
import org.stringtemplate.v4.STGroup;
import grammar.firstBaseVisitor;
import grammar.firstParser;

import java.util.Objects;

public class EmitVisitor extends firstBaseVisitor<ST> {
    private final STGroup stGroup;
    LocalSymbols<Integer> localVars = new LocalSymbols<Integer>();
    Integer ifCounter = 0;

    public EmitVisitor(STGroup group) {
        super();
        this.stGroup = group;
    }

    @Override
    protected ST defaultResult() {
        return stGroup.getInstanceOf("deflt");
    }

    @Override
    protected ST aggregateResult(ST aggregate, ST nextResult) {
        if(nextResult!=null)
            aggregate.add("elem",nextResult);
        return aggregate;
    }


//    @Override
//    public ST visitTerminal(TerminalNode node) {
//        return new ST("Terminal node:<n>").add("n",node.getText());
//    }

    @Override
    public ST visitInt_tok(firstParser.Int_tokContext ctx) {
        ST st = stGroup.getInstanceOf("int");
        st.add("i",ctx.INT().getText());
        return st;
    }

    @Override
    public ST visitBinOp(firstParser.BinOpContext ctx) {
        String opAss = "";

        ST left = visit(ctx.l);
        ST right = visit(ctx.r);

        switch (ctx.op.getType()) {
            case firstLexer.ADD -> opAss = "add";
            case firstLexer.SUB -> opAss = "sub";
            case firstLexer.MUL -> opAss = "mul";
            case firstLexer.DIV -> {
                opAss = "div";
//                if (right == 0) {
//                    throw new ArithmeticException("Dzielenie przez zero");
//                }
//                yield left / right;
            }
//            case firstLexer.GE -> opAss = "ge";
//            case firstLexer.LE -> opAss = "le";
            case firstLexer.EQ-> opAss = "eq";
//            case firstLexer.GEQ -> opAss = "geq";
//            case firstLexer.LEQ -> opAss = "leq";
//            case firstLexer.NEQ-> opAss = "neq";
//            case firstLexer.OR-> opAss = "or";
//            case firstLexer.AND-> opAss = "and";
            default -> throw new RuntimeException("Nieznany operator: " + ctx.op.getText());
        }

        ST st = stGroup.getInstanceOf(opAss);

        return st.add("p1",left).add("p2",right);
    }

    @Override
    public ST visitVar_tok(firstParser.Var_tokContext ctx) {
        ST st = stGroup.getInstanceOf("read");
        return st.add("n", ctx.getText());
    }

    @Override
    public ST visitPars(firstParser.ParsContext ctx) {
        return visit(ctx.expr());
    }

    @Override
    public ST visitAssign(firstParser.AssignContext ctx) {
        ST st = stGroup.getInstanceOf("assign");
        st.add("name", ctx.ID().getText());
        st.add("expr", visit(ctx.expr()));
        return st;
    }

    @Override
    public ST visitPrint_stat(firstParser.Print_statContext ctx) {
        ST st = stGroup.getInstanceOf("deflt");
        return st.add("elem", visit(ctx.expr()));
    }

    @Override
    public ST visitExpr_stat(firstParser.Expr_statContext ctx) {
        return super.visitExpr_stat(ctx);
    }

    @Override
    public ST visitProg(firstParser.ProgContext ctx) {
        ST st = stGroup.getInstanceOf("end");
        return st.add("prog", visitChildren(ctx));
    }

    @Override
    public ST visitDeclare_stat(firstParser.Declare_statContext ctx) {
        return super.visitDeclare_stat(ctx);
    }

    @Override
    public ST visitIf_stat(firstParser.If_statContext ctx) {
        return  stGroup.getInstanceOf("cond")
                .add("labelID", Integer.toString(ifCounter++))
                .add("condition", visit(ctx.cond))
                .add("if_true", visit(ctx.then))
                .add("if_false", visit(ctx.else_));
    }

    @Override
    public ST visitDeclare_expr(firstParser.Declare_exprContext ctx) {
        String varName = ctx.ID().getText();
        if(ctx.ASSIGN() != null) {
            ST st = stGroup.getInstanceOf("init");
            st.add("name", varName);
            return st.add("expr", visit(ctx.expr()));
        }
        else {
            ST st = stGroup.getInstanceOf("dec");
            return st.add("n", varName);
        }
    }
}
