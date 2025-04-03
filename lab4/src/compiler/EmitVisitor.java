package compiler;

import SymbolTable.LocalSymbols;
import grammar.firstLexer;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.tree.TerminalNode;
import org.stringtemplate.v4.ST;
import org.stringtemplate.v4.STGroup;
import grammar.firstBaseVisitor;
import grammar.firstParser;

import java.util.List;
import java.util.Objects;

public class EmitVisitor extends firstBaseVisitor<ST> {
    private final STGroup stGroup;
    LocalSymbols<Integer> localVars = new LocalSymbols<Integer>();
    Integer ifCounter = 0;
    Integer cmpCounter = 0;

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
    public ST visitLogic_int_tok(firstParser.Logic_int_tokContext ctx) {
        return stGroup.getInstanceOf("int").add("i", ctx.INT().getText());
    }

    @Override
    public ST visitLogic_id_tok(firstParser.Logic_id_tokContext ctx) {
        return stGroup.getInstanceOf("read").add("n", ctx.getText());
    }

    @Override
    public ST visitLogic_comp(firstParser.Logic_compContext ctx) {
        String operation;
        switch (ctx.op.getType()) {
            case firstParser.GE -> operation = "JG";
            case firstParser.GEQ -> operation = "JGE";
            case firstParser.LE -> operation = "JL";
            case firstParser.LEQ -> operation = "JLE";
            case firstParser.EQ -> operation = "JE";
            case firstParser.NEQ -> operation = "JNE";

            default -> throw new IllegalArgumentException("Nieznana operacja logiczna: " + ctx.op.getText());
        }

        ST st = stGroup.getInstanceOf("comp");
        st.add("p1", visit(ctx.l))
                .add("p2", visit(ctx.r))
                .add("comp_id", cmpCounter++)
                .add("op", operation);

        return st;
    }

    @Override
    public ST visitBinOp(firstParser.BinOpContext ctx) {
        String opAss;
        switch (ctx.op.getType()) {
            case firstLexer.ADD -> opAss = "add";
            case firstLexer.SUB -> opAss = "sub";
            case firstLexer.MUL -> opAss = "mul";
            case firstLexer.DIV -> opAss = "div";
            default -> throw new RuntimeException("Nieznany operator: " + ctx.op.getText());
        }

        ST st = stGroup.getInstanceOf(opAss);
        return st.add("p1",visit(ctx.l)).add("p2",visit(ctx.r));
    }

    @Override
    public ST visitVar_tok(firstParser.Var_tokContext ctx) {
        return stGroup.getInstanceOf("read").add("n", ctx.getText());
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
        if(ctx.else_ != null) {
            return  stGroup.getInstanceOf("if_stat")
                    .add("label_id", Integer.toString(ifCounter++))
                    .add("cond", visit(ctx.cond))
                    .add("then", visit(ctx.then))
                    .add("else_then", visit(ctx.else_));
        }
        else {
            return  stGroup.getInstanceOf("if_stat")
                    .add("label_id", Integer.toString(ifCounter++))
                    .add("cond", visit(ctx.cond))
                    .add("then", visit(ctx.then));
        }
    }

    @Override
    public ST visitLogic_not(firstParser.Logic_notContext ctx) {
        return stGroup.getInstanceOf("not").add("logic_expr", visit(ctx.expr_log()));
    }

    @Override
    public ST visitFor_stat(firstParser.For_statContext ctx) {
        return super.visitFor_stat(ctx);
    }

    @Override
    public ST visitLogic_and_or(firstParser.Logic_and_orContext ctx) {
        String operation;
        switch (ctx.op.getType()) {
            case firstParser.AND -> operation = "and";
            case firstParser.OR -> operation = "or";

            default -> throw new IllegalArgumentException("Nieznana operacja logiczna: " + ctx.op.getText());
        }

        ST st = stGroup.getInstanceOf(operation);
        st.add("p1", visit(ctx.l))
                .add("p2", visit(ctx.r));

        return st;
    }

    //    @Override
//    public ST visitFunc_call_stat(firstParser.Func_call_statContext ctx) {
//        ST st = stGroup.getInstanceOf("func_call");
//        st.add("name", ctx.name.getText());
//
//        List<firstParser.ExprContext> args = ctx.args;
//        for (firstParser.ExprContext arg : args) {
//            ST visit = visit(arg);
//            st.add("pars", visit);
//        }
//
//        return st;
//    }
//
//    @Override
//    public ST visitFunc_def_stat(firstParser.Func_def_statContext ctx) {
//
//        ST st = stGroup.getInstanceOf("func_def")
//                .add("name", ctx.name.getText())
//                .add("body", visit(ctx.body));
//
//        List<Token> params = ctx.par;
//        st.add("pars", params);
//
//        return st;
//    }

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

    @Override
    public ST visitBlock_real(firstParser.Block_realContext ctx) {
        ST deflt = stGroup.getInstanceOf("deflt");

        List<firstParser.BlockContext> blocks = ctx.block();
        for (firstParser.BlockContext block : blocks) {
            ST st = visit(block);
            if (st != null) {
                deflt.add("elem", st);
            }

        }
        return deflt;
    }
}
