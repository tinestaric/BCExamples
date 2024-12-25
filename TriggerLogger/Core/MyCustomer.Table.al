table 50140 MyCustomer
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; MyField; Integer) { ToolTip = 'My Field'; }
        field(2; MyField2; Integer)
        {
            ToolTip = 'My Field 2';
            TableRelation = Log.Id;

            trigger OnValidate()
            begin
                Log.AddLog('Core', 'Table', 'OnValidate');
            end;

            // trigger OnLookup()
            // begin
            //     Log.AddLog('Core', 'Table', 'OnLookup');
            // end;
        }
    }

    keys
    {
        key(Key1; MyField)
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        Log.AddLog('Core', 'Table', 'OnInsert');
    end;

    trigger OnModify()
    begin
        Log.AddLog('Core', 'Table', 'OnModify');
    end;

    trigger OnDelete()
    begin
        Log.AddLog('Core', 'Table', 'OnDelete');
    end;

    trigger OnRename()
    begin
        Log.AddLog('Core', 'Table', 'OnRename');
    end;

    var
        Log: Record Log;

}