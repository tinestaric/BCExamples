codeunit 80100 InsertEntryBCPT
{
    Subtype = Test;

    var
        _LibraryRandom: Codeunit "Library - Random";

    trigger OnRun()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        i: integer;
    begin
        BCPTTestContext.StartScenario('Inserting Records');

        _LibraryRandom.Init();

        for i := 1 to 10 do
            InsertSimpleEntry();

        Sleep(2000);

        BCPTTestContext.EndScenario('Inserting Records');
    end;

    local procedure InsertSimpleEntry()
    var
        SimpleEntry: Record SimpleEntry;
    begin
        SimpleEntry.Init();
        SimpleEntry.EntryNo := 0;
        SimpleEntry.PostingDate := _LibraryRandom.RandDate(10);
        SimpleEntry.Amount := _LibraryRandom.RandDec(10000, 2);
        SimpleEntry.Quantity := _LibraryRandom.RandInt(100);
        SimpleEntry.Type := Enum::EntryType.FromInteger(_LibraryRandom.RandInt(2) - 1);
        SimpleEntry.Insert(true);
    end;
}