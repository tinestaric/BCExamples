pageextension 50102 EntraApplicationCardJQ extends "AAD Application Card"
{
    layout
    {
        addafter("Contact Information")
        {
            field("Use for Job Queues"; Rec."Use for Job Queues")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies if the application can be used for scheduling job queues.';
            }
            field(ClientSecret; _Secret)
            {
                ApplicationArea = All;
                Caption = 'Client Secret';
                ToolTip = 'Specify the client secret for the application. This will be used to acquire access tokens for the application when calling scheduling Job Queues Entries through an API.';
                ExtendedDatatype = Masked;

                trigger OnValidate()
                begin
                    Rec.SetSecret(_Secret);
                    _Secret := '*';
                end;
            }
        }
    }

    var
        _Secret: Text;

    trigger OnAfterGetCurrRecord()
    begin
        if not Rec.GetSecret().IsEmpty() then
            _Secret := '*';
    end;
}