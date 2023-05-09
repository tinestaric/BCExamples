page 50103 ContractAPIv2
{
    PageType = API;
    Caption = 'contract';
    APIPublisher = 'starReach';
    APIGroup = 'api';
    APIVersion = 'v2.0';
    EntityName = 'contract';
    EntitySetName = 'contracts';
    SourceTable = Contract;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(number; Rec.Number) { }
                field(description; Rec.Description) { }
                field(amount; Rec.Amount) { }
                field(customerNo; Rec.CustomerNo) { }
                field(contractDate; Rec.ContractDate) { }
                field(type; Rec.Type) { }
            }
        }
    }
}