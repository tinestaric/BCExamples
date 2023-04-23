codeunit 50103 FacebookAuthCode implements ITokenGetter
{

    [NonDebuggable]
    procedure GetToken() Token: Text;
    var
        JsonParser: Codeunit JsonParser;
        EndpointManagement: Codeunit EndpointManagement;
        OAuth2ControlAddIn: Page "OAuth2 Control Add-In";
        Client: HttpClient;
        ResponseMessage: HttpResponseMessage;
        AuthorityUrlLbl: Label 'https://www.facebook.com/v15.0/dialog/oauth?client_id=%1&redirect_uri=%2&state=%3', Comment = '%1 - ClientId, %2 - Redirect Uri, %3 - State', Locked = true;
        TokenUrlLbl: Label 'https://graph.facebook.com/v15.0/oauth/access_token?client_id=%1&redirect_uri=%2&client_secret=%3&code=%4', Comment = '%1 - Client Id, %2 - Redirect Uri, %3 - Client Secret, %4 - Auth Code', Locked = true;
        AuthCode: Text;
        AuthCodeErr: Text;
        OAuthAuthorityURL: Text;
        TokenUrl: Text;
        ResponseBody: Text;
        State: Text;
        JsonToken: JsonToken;
    begin
        State := Format(CreateGuid(), 0, 4);

        OAuthAuthorityURL := StrSubstNo(AuthorityUrlLbl, GetClientId(), EndpointManagement.GetRedirectUrl(), State);

        OAuth2ControlAddIn.SetOAuth2Properties(OAuthAuthorityURL, State);
        OAuth2ControlAddIn.RunModal();

        AuthCode := OAuth2ControlAddIn.GetAuthCode();
        AuthCodeErr := OAuth2ControlAddIn.GetAuthError();

        if AuthCodeErr <> '' then
            Error(AuthCodeErr);

        TokenUrl := StrSubstNo(TokenUrlLbl, GetClientId(), EndpointManagement.GetRedirectUrl(), GetClientSecret(), AuthCode);

        Client.Get(TokenUrl, ResponseMessage);

        ResponseMessage.Content.ReadAs(ResponseBody);

        if ResponseMessage.IsSuccessStatusCode then begin
            JsonToken.ReadFrom(ResponseBody);
            Token := JsonParser.GetValueAsText(JsonToken, 'access_token');
        end else
            Error('%1 %2', ResponseMessage.ReasonPhrase, ResponseBody);
    end;

    local procedure GetClientId(): Text
    begin
        EXIT('556109569412929')
    end;

    [NonDebuggable]
    local procedure GetClientSecret() Secret: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('FBSecret', Secret);
    end;
}