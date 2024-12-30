page 50101 Log
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = Log;
    SourceTableView = sorting(SystemCreatedAt);

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(MyField; Rec.Id) { }
                field(ExtensionType; Rec.ExtensionType) { }
                field(ObjectType; Rec.ObjectType) { }
                field(EventName; Rec.EventName) { }
                field(CreatedAt; Rec.SystemCreatedAt) { }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Clean)
            {

                trigger OnAction()
                begin
                    Rec.DeleteAll(false);
                end;
            }
        }
    }
}
