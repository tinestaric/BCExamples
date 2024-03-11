table 80100 SimpleEntry
{
    Access = Internal;
    Caption = 'Simple Entry';
    DataClassification = CustomerContent;
    Extensible = false;

    fields
    {
        field(1; EntryNo; Integer)
        {
            AutoIncrement = true;
            Caption = 'Entry No.';
        }
        field(20; PostingDate; Date) { Caption = 'Posting Date'; }
        field(30; Type; Enum EntryType) { Caption = 'Type'; }
        field(40; Amount; Decimal) { Caption = 'Amount'; }
        field(50; Quantity; Decimal) { Caption = 'Quantity'; }
    }

    keys
    {
        key(PK; EntryNo)
        {
            Clustered = true;
        }
        key(Type; Type)
        {
            SumIndexFields = Amount, Quantity;
        }
    }
}