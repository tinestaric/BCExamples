page 70100 CalculatorTester
{
    PageType = NavigatePage;
    Caption = 'Calculator Tester';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(Expressions; _Expression)
                {
                    Caption = 'Expressions';
                    ToolTip = 'Enter expressions to calculate. There are three hardcoded variables you can use: A = 1, B = 2, C = 3';
                }
                field(Result; _Result)
                {
                    Caption = 'Result';
                    ToolTip = 'Result of the calculation';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Calculate)
            {
                Caption = 'Calculate';
                ToolTip = 'Calculate the expressions';
                Image = Calculator;
                InFooterBar = true;

                trigger OnAction()
                var
                    NotationParser: Codeunit NotationParser;
                    PostfixExpression: Text;
                begin
                    PostfixExpression := NotationParser.InfixToPostfix(_Expression);

                    PostfixExpression := PostfixExpression.Replace('A', '1');
                    PostfixExpression := PostfixExpression.Replace('B', '2');
                    PostfixExpression := PostfixExpression.Replace('C', '3');

                    _Result := NotationParser.EvaluatePostfixNotation(PostfixExpression);
                end;
            }
        }
    }

    var
        _Expression: Text;
        _Result: Decimal;
}