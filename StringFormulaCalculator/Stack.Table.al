table 70100 Stack
{
    Access = Internal;
    Caption = 'Temp Stack';
    DataClassification = CustomerContent;
    Extensible = false;
    TableType = Temporary;

    fields
    {
        field(1; StackOrder; Integer) { Caption = 'StackOrder'; }
        field(2; Value; Text[2048]) { Caption = 'Value'; }
    }

    keys
    {
        key(PK_TempStack; StackOrder) { Clustered = true; }
    }

    var
        _LastIndex: Integer;

    internal procedure Peek(): Text
    begin
        if (FindLast()) then
            EXIT(Value);
    end;

    internal procedure Pop() TopValue: Text
    begin
        if (FindLast()) then begin
            TopValue := Value;
            Delete(true);
            _LastIndex := _LastIndex - 1;
        end;
    end;

    internal procedure Push(NewValue: Variant)
    begin
        Validate(StackOrder, _LastIndex);
        Validate(Value, Format(NewValue));
        Insert(true);
        _LastIndex := _LastIndex + 1;
    end;
}