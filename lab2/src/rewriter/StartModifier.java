package rewriter;

import org.antlr.v4.runtime.CharStream;
import org.antlr.v4.runtime.CharStreams;
import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.tree.ParseTree;
import org.antlr.v4.runtime.tree.ParseTreeWalker;

import java.io.FileWriter;
import java.io.IOException;

public class StartModifier {
    public static void main(String[] args) {
        CharStream inp = null;

        try {
            inp = CharStreams.fromFileName("src/rewriter/InsertDocListener.java");
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        JavaLexer lex = new JavaLexer(inp);
        CommonTokenStream tokens = new CommonTokenStream(lex);
        JavaParser par = new JavaParser(tokens);

        ParseTree tree = par.compilationUnit();
        ParseTreeWalker walker = new ParseTreeWalker();
        InsertDocListener inserter = new InsertDocListener(tokens);
        walker.walk(inserter,tree);
        System.out.println(inserter.rewriter.getText());
        try {
            var wr = new FileWriter("wy.java");
            wr.write(inserter.rewriter.getText());
            wr.close();
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
