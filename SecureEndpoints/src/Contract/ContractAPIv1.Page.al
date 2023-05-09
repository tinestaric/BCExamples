page 50102 ContractAPIv1
{
    PageType = API;
    Caption = 'contract';
    APIPublisher = 'starReach';
    APIGroup = 'api';
    APIVersion = 'v1.0';
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
            }
        }
    }
}