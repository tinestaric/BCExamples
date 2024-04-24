page 50100 SimpleEntryList
{
    Caption = 'Simple Entries';
    PageType = List;
    UsageCategory = Lists;
    ApplicationArea = All;
    SourceTable = SimpleEntry;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(EntryNo; Rec.EntryNo)
                {
                    ToolTip = 'Entry No.';
                }

            }
        }
    }
}