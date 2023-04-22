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
            }
            group(Send)
            {
                ShowCaption = false;
                field(SendOAuthMessage; SendOAuthMessageLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Sends the OAuth Message based on the above parameters.';
                    Style = Favorable;

                    trigger OnDrillDown()
                    var
                        ResponseMessage: HttpResponseMessage;
                    begin
                        ResponseMessage := EndpointManagement.GetTopSecretInfo(IdP, Endpoint);

                        IsSuccess := ResponseMessage.IsSuccessStatusCode;
                        StatusCode := ResponseMessage.HttpStatusCode;
                        ReasonPhrase := ResponseMessage.ReasonPhrase;
                        ResponseMessage.Content.ReadAs(ResponseBody);
                    end;
                }
            }
            group(Response)
            {

                field(IsSuccess; IsSuccess)
                {
                    ApplicationArea = All;
                    Caption = 'Is Success';
                    ToolTip = 'Specifies whether the request was successful.';
                    Editable = false;
                }
                field(StatusCode; StatusCode)
                {
                    ApplicationArea = All;
                    Caption = 'Status Code';
                    ToolTip = 'Specifies the status code of the request.';
                    Editable = false;
                }
                field(ReasonPhrase; ReasonPhrase)
                {
                    ApplicationArea = All;
                    Caption = 'Reason Phrase';
                    ToolTip = 'Specifies the reason phrase of the request.';
                    Editable = false;
                }
                group(ResponseBodyGroup)
                {
                    Caption = 'Response Body';
                    field(ResponseBody; ResponseBody)
                    {
                        ApplicationArea = All;
                        MultiLine = true;
                        ShowCaption = false;
                        ToolTip = 'Specify the response to be returned by the endpoint.';
                        Editable = false;
                    }
                }
            }
        }
    }

    var
        EndpointManagement: Codeunit EndpointManagement;
        ResponseBody: Text;
        StatusCode: Integer;
        IsSuccess: Boolean;
        ReasonPhrase: Text;
        IdP: Enum IdentityProvider;
        Endpoint: Enum Endpoint;
        SendOAuthMessageLbl: Label 'Send OAuth Message';
}