table 50100 Contract
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Number; Integer)
        {
            Caption = 'Number';
            AutoIncrement = true;
        }
        field(20; Description; Text[250])
        {
            Caption = 'Description';
        }
        field(30; Amount; Decimal)
        {
            Caption = 'Amount';
        }
        field(40; ContractDate; Date)
        {
            Caption = 'Contract Date';
        }
        field(50; Type; Enum ContractType)
        {
            Caption = 'Type';
        }
        field(60; CustomerNo; Code[20])
        {
            Caption = 'Customer No.';
        }
    }

    keys
    {
        key(Key1; Number)
        {
            Clustered = true;
        }
    }
}