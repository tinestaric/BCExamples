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
                field(TokenGetter; TokenGetter)
                {
                    Caption = 'Token Getter';
                    ToolTip = 'Specify the Token Getter to be used for authentication.';
                }
                field(SignMessage; SignMessage)
                {
                    Caption = 'Sign Message';
                    ToolTip = 'Specify whether the message should be signed.';
                }
            }
            group(Send)
            {
                ShowCaption = false;
                field(SendRequest; SendRequestLbl)
                {
                    ShowCaption = false;
                    ToolTip = 'Sends the OAuth Message based on the above parameters.';
                    Style = Favorable;

                    trigger OnDrillDown()
                    var
                        ResponseMessage: HttpResponseMessage;
                    begin
                        ResponseMessage := EndpointManagement.GetTopSecretInfo(TokenGetter, Endpoint, SignMessage);

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
        SignMessage: Boolean;
        TokenGetter: Enum IdentityProvider;
        Endpoint: Enum Endpoint;
        SendRequestLbl: Label 'Send Request';
}