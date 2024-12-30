tableextension 50100 MyCustomerExt extends MyCustomer
{
    fields
    {
        modify(MyField2)
        {
            trigger OnBeforeValidate()
            begin
                Log.AddLog('Core', 'TableExt', 'OnValidate');
            end;

            trigger OnAfterValidate()
            begin
                Log.AddLog('Core', 'TableExt', 'OnAfterValidate');
            end;
        }
    }

    trigger OnBeforeInsert()
    begin
        Log.AddLog('Core', 'TableExt', 'OnBeforeInsert');
    end;

    trigger OnInsert()
    begin
        Log.AddLog('Core', 'TableExt', 'OnInsert');
    end;

    trigger OnAfterInsert()
    begin
        Log.AddLog('Core', 'TableExt', 'OnAfterInsert');
    end;

    trigger OnBeforeModify()
    begin
        Log.AddLog('Core', 'TableExt', 'OnBeforeModify');
    end;

    trigger OnModify()
    begin
        Log.AddLog('Core', 'TableExt', 'OnModify');
    end;

    trigger OnAfterModify()
    begin
        Log.AddLog('Core', 'TableExt', 'OnAfterModify');
    end;

    trigger OnBeforeDelete()
    begin
        Log.AddLog('Core', 'TableExt', 'OnBeforeDelete');
    end;

    trigger OnDelete()
    begin
        Log.AddLog('Core', 'TableExt', 'OnDelete');
    end;

    trigger OnAfterDelete()
    begin
        Log.AddLog('Core', 'TableExt', 'OnAfterDelete');
    end;

    trigger OnBeforeRename()
    begin
        Log.AddLog('Core', 'TableExt', 'OnBeforeRename');
    end;

    trigger OnRename()
    begin
        Log.AddLog('Core', 'TableExt', 'OnRename');
    end;

    trigger OnAfterRename()
    begin
        Log.AddLog('Core', 'TableExt', 'OnAfterRename');
    end;

    var
        Log: Record Log;

}