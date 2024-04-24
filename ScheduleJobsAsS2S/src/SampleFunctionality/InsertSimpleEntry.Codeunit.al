codeunit 50102 InsertSimpleEntry
{
    trigger OnRun()
    begin
        InsertEntry();
    end;

    procedure InsertEntry()
    var
        SimpleEntry: Record SimpleEntry;
    begin
        SimpleEntry.Insert();
    end;
}