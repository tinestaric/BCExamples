table 50100 Log
{
    DataClassification = CustomerContent;
    // LookupPageId = Log;

    fields
    {
        field(1; Id; Integer) { }
        field(2; ExtensionType; Text[30]) { }
        field(3; ObjectType; Text[30]) { }
        field(4; EventName; Text[50]) { }
    }

    keys
    {
        key(Key1; Id) { Clustered = true; }
        key(CreatedAt; SystemCreatedAt) { }

    }

    procedure AddLog(pExtensionType: Text[30]; pObjectType: Text[30]; pEventName: Text[50])
    begin
        if Rec.FindLast() then;

        Rec.Id := Rec.Id + 1;
        Rec.ExtensionType := pExtensionType;
        Rec.ObjectType := pObjectType;
        Rec.EventName := pEventName;
        Rec.Insert(true);
    end;
}