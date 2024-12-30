pageextension 50100 MyCustomerExt extends MyCustomer
{

    layout
    {
        modify(MyField2)
        {
            trigger OnBeforeValidate()
            begin
                Log.AddLog('Core', 'PageExt', 'OnBeforeValidate');
            end;

            trigger OnAfterValidate()
            begin
                Log.AddLog('Core', 'PageExt', 'OnAfterValidate');
            end;

            trigger OnAfterAfterLookup(Selected: RecordRef)
            begin
                Log.AddLog('Core', 'PageExt', 'OnAfterAfterLookup');
            end;

            // trigger OnLookup(var Text: Text): Boolean
            // begin
            //     Log.AddLog('Core', 'PageExt', 'OnLookup');
            // end;
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.AddLog('Core', 'PageExt', 'OnInsertRecord');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.AddLog('Core', 'PageExt', 'OnModifyRecord');
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.AddLog('Core', 'PageExt', 'OnDeleteRecord');
    end;

    var
        Log: Record Log;

}