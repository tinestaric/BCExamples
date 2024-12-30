pageextension 50200 Ext1MyCustomerExt extends MyCustomer
{
    layout
    {
        modify(MyField2)
        {
            trigger OnBeforeValidate()
            begin
                Log.AddLog('EXT1', 'PageExt', 'OnBeforeValidate');
            end;

            trigger OnAfterValidate()
            begin
                Log.AddLog('EXT1', 'PageExt', 'OnAfterValidate');
            end;

            trigger OnAfterAfterLookup(Selected: RecordRef)
            begin
                Log.AddLog('EXT1', 'PageExt', 'OnAfterAfterLookup');
            end;

            // trigger OnLookup(var Text: Text): Boolean
            // begin
            //     Log.AddLog('EXT1', 'PageExt', 'OnLookup');
            // end;
        }
    }
    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.AddLog('Ext1', 'PageExt', 'OnInsertRecord');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.AddLog('EXT1', 'PageExt', 'OnModifyRecord');
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.AddLog('EXT1', 'PageExt', 'OnDeleteRecord');
    end;

    var
        Log: Record Log;

}