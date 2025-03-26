package rewriter;

import org.antlr.v4.runtime.CommonTokenStream;
import org.antlr.v4.runtime.ParserRuleContext;
import org.antlr.v4.runtime.Token;
import org.antlr.v4.runtime.TokenStreamRewriter;
import org.stringtemplate.v4.ST;

import java.util.List;
import rewriter.JavaParserBaseListener;
import rewriter.JavaParser;

public class InsertDocListener  extends JavaParserBaseListener{
    private final CommonTokenStream tokStream;
    TokenStreamRewriter rewriter;
    private String interesting = null;

    public InsertDocListener(CommonTokenStream tokens) {
        this.tokStream = tokens;
        rewriter = new TokenStreamRewriter(tokens);
    }

    @Override
    public void exitClassBodyDeclaration(JavaParser.ClassBodyDeclarationContext ctx) {
        if (interesting == null) return;

        List<Token> spaces = tokStream.getHiddenTokensToLeft(ctx.start.getTokenIndex());
        Token lastBefore = spaces.get(spaces.size()-1);

        ST docST = new ST(lastBefore.getText()+"<line; separator = \"\n*  \">");
        docST.add("line","/**")
                .add("line",interesting)
                .add("line","\n*/");
        rewriter.insertBefore(lastBefore,docST.render());
        interesting = null;
    }

    @Override
    public void exitConstructorDeclaration(JavaParser.ConstructorDeclarationContext ctx) {
        interesting = ctx.identifier().IDENTIFIER().getText();
    }

    @Override
    public void exitMethodDeclaration(JavaParser.MethodDeclarationContext ctx) {
        interesting = ctx.identifier().IDENTIFIER().getText();
    }
}
