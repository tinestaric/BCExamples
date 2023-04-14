page 50101 EndpointTester
{
    PageType = Card;
    Extensible = false;
    Caption = 'Endpoint Tester';
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Endpoint; Endpoint)
                {
                    Caption = 'Endpoint';
                    ToolTip = 'Specify the endpoint to be tested.';
                }
                field(IdP; IdP)
                {
                    Caption = 'Identity Provider';
                    ToolTip = 'Specify the identity provider to be used for authentication.';
                }
                field(AuthType; AuthType)
                {
                    Caption = 'Auth Type';
                    ToolTip = 'Specify the authentication type to be used for authentication.';
                }
                field(SendOAuthMessage; SendOAuthMessageLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Sends the OAuth Message based on the above parameters.';

                    trigger OnDrillDown()
                    begin
                        Response := EndpointManagement.GetTopSecretInfo(IdP, AuthType, Endpoint);
                    end;
                }

                field(Response; Response)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Caption = 'Response';
                    ToolTip = 'Specify the response to be returned by the endpoint.';
                }
            }
        }
    }

    var
        EndpointManagement: Codeunit EndpointManagement;
        Response: Text;
        IdP: Enum IdentityProvider;
        AuthType: Enum TokenAuthType;
        Endpoint: Enum Endpoint;
        SendOAuthMessageLbl: Label 'Send OAuth Message';
}