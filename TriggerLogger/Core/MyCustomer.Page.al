page 50100 MyCustomer
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = MyCustomer;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(MyField; Rec.MyField) { }
                field(MyField2; Rec.MyField2)
                {
                    trigger OnValidate()
                    begin
                        Log.AddLog('Core', 'Page', 'OnValidate');
                    end;

                    trigger OnAfterLookup(Selected: RecordRef)
                    begin
                        Log.AddLog('Core', 'Page', 'OnAfterLookup');
                    end;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Log.AddLog('Core', 'Page', 'OnLookup');
                        exit(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActionName)
            {

                trigger OnAction()
                begin
                    Log.AddLog('Core', 'Page', 'OnAction');
                end;
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        Log.AddLog('Core', 'Page', 'OnInsertRecord');
    end;

    trigger OnModifyRecord(): Boolean
    begin
        Log.AddLog('Core', 'Page', 'OnModifyRecord');
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        Log.AddLog('Core', 'Page', 'OnDeleteRecord');
    end;

    var
        Log: Record Log;

}