tableextension 50200 Ext1MyCustomerExt extends MyCustomer
{
    fields
    {
        modify(MyField2)
        {
            trigger OnBeforeValidate()
            begin
                Log.AddLog('EXT1', 'TableExt', 'OnValidate');
            end;

            trigger OnAfterValidate()
            begin
                Log.AddLog('EXT1', 'TableExt', 'OnAfterValidate');
            end;
        }
    }
    trigger OnBeforeInsert()
    begin
        Log.AddLog('Ext1', 'TableExt', 'OnBeforeInsert');
    end;

    trigger OnInsert()
    begin
        Log.AddLog('Ext1', 'TableExt', 'OnInsert');
    end;

    trigger OnAfterInsert()
    begin
        Log.AddLog('Ext1', 'TableExt', 'OnAfterInsert');
    end;


    trigger OnBeforeModify()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnBeforeModify');
    end;

    trigger OnModify()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnModify');
    end;

    trigger OnAfterModify()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnAfterModify');
    end;

    trigger OnBeforeDelete()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnBeforeDelete');
    end;

    trigger OnDelete()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnDelete');
    end;

    trigger OnAfterDelete()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnAfterDelete');
    end;

    trigger OnBeforeRename()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnBeforeRename');
    end;

    trigger OnRename()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnRename');
    end;

    trigger OnAfterRename()
    begin
        Log.AddLog('EXT1', 'TableExt', 'OnAfterRename');
    end;

    var
        Log: Record Log;

}