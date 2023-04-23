codeunit 50112 AADS2S implements ITokenGetter
{
    [NonDebuggable]
    procedure GetToken() AccessToken: Text;
    var
        JsonParser: Codeunit JsonParser;
        Client: HttpClient;
        Headers: HttpHeaders;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        JsonToken: JsonToken;
        TokenURLTok: Label 'https://login.microsoftonline.com/b65e6ce1-543b-4eb3-8b2a-5e3e0f086e36/oauth2/token';
        ResponseBody: Text;
    begin
        Request.SetRequestUri(TokenURLTok);
        Request.GetHeaders(Headers);
        Headers.Add('grant_type', 'client_credentials');
        Headers.Add('client_id', GetClientId());
        Headers.Add('client_secret', GetClientSecret());

        Client.Send(Request, Response);

        Response.Content.ReadAs(ResponseBody);

        if Response.IsSuccessStatusCode then begin
            JsonToken.ReadFrom(ResponseBody);
            AccessToken := JsonParser.GetValueAsText(JsonToken, 'access_token');
        end else
            Error('%1 %2', Response.ReasonPhrase, ResponseBody);


    end;

    local procedure GetClientId(): Text
    begin
        exit('79b345f6-8ab0-4cae-8305-65671c04199d');
    end;

    [NonDebuggable]
    local procedure GetClientSecret() Secret: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('AADAzFunct-Secret', Secret);
    end;
}