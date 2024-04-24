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
                    ToolTip = 'Specifies the entry number';
                }
                field(CreatedBy; CreatedBy)
                {
                    Caption = 'Created by';
                    ToolTip = 'Specifies the user who created the entry';
                }
            }
        }
    }

    var
        CreatedBy: Text;

    trigger OnAfterGetRecord()
    var
        User: Record User;
    begin
        User.Get(Rec.SystemCreatedBy);
        CreatedBy := User."Full Name";
    end;
}