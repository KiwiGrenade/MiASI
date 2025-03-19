package interpreter;

import grammar.*;
import org.antlr.v4.runtime.*;
import org.antlr.v4.runtime.tree.ParseTree;

import java.io.IOException;

public class Start {
    public static void main(String[] args) {
        CharStream inp = null;
        try {
            inp = CharStreams.fromFileName("we.first");
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
//        CharStream inp = CharStreams.fromString("1+2*3-(4+5)","wejście");
//        CharStream inp = CharStreams.fromStream(System.in);

        firstLexer lex = new firstLexer(inp);
        CommonTokenStream tokens = new CommonTokenStream(lex);
        firstParser par = new firstParser(tokens);

        ParseTree tree = par.prog();

        CalculateVisitor v = new CalculateVisitor(inp,tokens);
        Integer res = v.visit(tree);
//        System.out.printf("Wynik: %d\n", res);
    }
}
