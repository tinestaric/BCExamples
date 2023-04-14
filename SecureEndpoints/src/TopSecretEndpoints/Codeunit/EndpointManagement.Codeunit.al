codeunit 50101 EndpointManagement
{

    // [NonDebuggable]
    internal procedure GetTopSecretInfo(
        IIdentityProvider: Interface IIdentityProvider;
        TokenAuthType: Enum TokenAuthType;
        IEndpoint: Interface IEndpoint
    ) Response: Text
    var
        Token: Text;
    begin
        case TokenAuthType of
            TokenAuthType::AuthCode:
                Token := IIdentityProvider.GetTokenWithAuthCode();
            TokenAuthType::RefreshToken:
                Token := IIdentityProvider.GetTokenWithRefreshToken();
            TokenAuthType::ClientCredentials:
                Token := IIdentityProvider.GetTokenWithClientCredentials();
        end;

        Response := CallEndpoint(IEndpoint, Token);
    end;

    local procedure CallEndpoint(IEndpoint: Interface IEndpoint; Token: Text) Response: Text
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        ResponseBody: Text;
    begin
        RequestMessage := IEndpoint.GetRequestMessage(Token, '');

        Client.Send(RequestMessage, ResponseMessage);

        if ResponseMessage.IsSuccessStatusCode then begin
            ResponseMessage.Content.ReadAs(ResponseBody);
            Response := ResponseBody;
        end else begin
            ResponseMessage.Content.ReadAs(ResponseBody);
            Error('%1 %2', ResponseMessage.ReasonPhrase, ResponseBody);
        end;
    end;
}