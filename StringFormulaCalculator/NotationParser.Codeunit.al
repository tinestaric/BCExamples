codeunit 70100 NotationParser
{
    Access = Internal;

    #region Transform to Postfix Notation
    /// <summary>
    /// Transforms an infix notation to a postfix notation.
    /// </summary>
    /// <param name="Expression">String expression. Can contain numbers or letters as operands</param>
    /// <returns>Expressions in Postfix notation</returns>
    internal procedure InfixToPostfix(Expression: Text): Text
    var
        Stack: Record Stack;
        InvalidExpressionErr: Label 'Invalid Expression.';
        InvalidExpressionTokenErr: Label '%1 is not a valid character in calculation formula.', Comment = '%1 = Invalid Token';
        Operators: List of [Text];
        TokenList: List of [Text];
        PostfixNotation: Text;
        Token: Text;
    begin
        InitializeOperators(Operators);
        Normalize(Expression);

        TokenList := Expression.Split(' ');

        foreach Token in TokenList do
            case true of
                IsVariableOrNumber(Token): // If the scanned character is an operand, add it to output.
                    PostfixNotation += Token + ' ';
                Token = '(': // If the scanned character is an '(', push it to the Stack.
                    Stack.Push(Token);
                Token = ')': // If the scanned character is an ')', pop and output from the Stack until an '(' is encountered.
                    begin
                        while (Stack.Count > 0) and not (Stack.Peek() = '(') do
                            PostfixNotation += Stack.Pop() + ' ';

                        if (Stack.Count > 0) and not (Stack.Peek() = '(') then
                            Error(InvalidExpressionErr)
                        else
                            Stack.Pop();
                    end;
                Operators.Contains(Token):
                    begin // an operator is encountered
                        while (Stack.Count > 0) and (Priority(Token) <= Priority(Stack.Peek())) do
                            PostfixNotation += Stack.Pop() + ' ';

                        Stack.Push(Token);
                    end;
                Token = '':
                    ;//Do nothing
                else
                    Error(InvalidExpressionTokenErr, Token);
            end;

        // pop all the operators from theStack
        while (Stack.Count > 0) do
            PostfixNotation += Stack.Pop() + ' ';

        PostfixNotation := PostfixNotation.Trim();
        EXIT(PostfixNotation);
    end;

    local procedure Normalize(var Expression: Text)
    begin
        Expression := Expression.ToUpper();
        Expression := Expression.Replace(' ', '');
        Expression := Expression.Replace('+', ' + ');
        Expression := Expression.Replace('-', ' - ');
        Expression := Expression.Replace('*', ' * ');
        Expression := Expression.Replace('/', ' / ');
        Expression := Expression.Replace('^', ' ^ ');
        Expression := Expression.Replace('(', '( ');
        Expression := Expression.Replace(')', ' )');
        Expression := Expression.Replace('\ - ', ' -');
    end;

    local procedure IsVariableOrNumber(vTok: Text): Boolean
    var
        RegEx: Codeunit Regex;
        LetterOrDigitTok: Label '^(-?[0-9.,]+|-?[A-Za-z0-9:]+)$', Locked = true;
    begin
        EXIT(RegEx.IsMatch(vTok, LetterOrDigitTok));
    end;

    local procedure Priority(Char: Text): Integer
    begin
        case true of
            Char = '+',
            Char = '-':
                EXIT(1);
            Char = '*',
            Char = '/':
                EXIT(2);
            Char = '^':
                EXIT(3);
        end;
        EXIT(-1);
    end;
    #endregion

    #region Evaluate Postfix Notation
    /// <summary>
    /// Evaluates a postfix notation. Expression must contain only numbers as operands.
    /// </summary>
    /// <param name="Expression">Expression in Postfix notation format</param>
    /// <returns>Calculation result</returns>
    internal procedure EvaluatePostfixNotation(Expression: Text): Decimal
    var
        Stack: Record Stack;
        Operand1: Decimal;
        Operand2: Decimal;
        Result: Decimal;
        Operators: List of [Text];
        TokenList: List of [Text];
        Token: Text;
    begin
        InitializeOperators(Operators);

        TokenList := Expression.Split(' ');

        foreach Token in TokenList do
            if (Operators.Contains(Token)) then begin
                Evaluate(Operand2, Stack.Pop());
                Evaluate(Operand1, Stack.Pop());

                Result := Calculate(Token, Operand1, Operand2);
                Stack.Push(Result);
            end else
                Stack.Push(Token);

        Evaluate(Result, Stack.Pop());
        EXIT(Result);
    end;

    local procedure Calculate(Token: Text; Operand1: Decimal; Operand2: Decimal): Decimal
    begin
        case true of
            Token = '+':
                EXIT(Operand1 + Operand2);
            Token = '-':
                EXIT(Operand1 - Operand2);
            Token = '*':
                EXIT(Operand1 * Operand2);
            Token = '/':
                EXIT(Operand1 / Operand2);
            Token = '^':
                EXIT(Power(Operand1, Operand2));
        end;
    end;
    #endregion

    #region Initialize
    local procedure InitializeOperators(var Operators: List of [Text])
    begin
        Operators.Add('+');
        Operators.Add('-');
        Operators.Add('*');
        Operators.Add('/');
        Operators.Add('^');
    end;
    #endregion
}