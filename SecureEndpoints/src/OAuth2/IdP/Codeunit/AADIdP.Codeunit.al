codeunit 50102 AADIdP implements IIdentityProvider
{
    var
        OAuth2: Codeunit OAuth2;

    procedure GetTokenWithAuthCode() AccessToken: Text;
    var
        RefreshToken: Text;
        Error: Text;
    begin
        OAuth2.AcquireTokenAndTokenCacheByAuthorizationCode(
            GetClientId(),
            GetClientSecret(),
            GetAuthorityURL(),
            GetRedirectURL(),
            GetScope(),
            "Prompt Interaction"::Login,
            AccessToken,
            RefreshToken,
            Error);

        SetRefreshToken(RefreshToken);
    end;

    procedure GetTokenWithRefreshToken() AccessToken: Text;
    var

        RefreshToken: Text;
    begin
        OAuth2.AcquireOnBehalfOfTokenByTokenCache(
            GetClientId(),
            GetClientSecret(),
            'LoginHint',
            GetRedirectUrl(),
            GetScope(),
            GetRefreshToken(),
            AccessToken,
            RefreshToken
        );

        SetRefreshToken(RefreshToken);
    end;

    procedure GetTokenWithClientCredentials(): Text;
    begin

    end;

    procedure TestConnection(Token: Text) Response: Text;
    begin

    end;

    local procedure GetClientId(): Text
    begin
        exit('920d919e-a1cf-44ec-9d94-6ac6674bb358');
    end;

    local procedure GetClientSecret() Secret: Text
    var
        KeyVault: Codeunit "App Key Vault Secret Provider";
    begin
        if KeyVault.TryInitializeFromCurrentApp() then
            KeyVault.GetSecret('AADAzFuncSecret', Secret);
    end;

    local procedure GetRedirectUrl(): Text
    var
        Environment: Codeunit "Environment Information";
    begin
        if Environment.IsSaaSInfrastructure() then
            exit('https://businesscentral.dynamics.com/OAuthLanding.htm')
        else
            exit('https://cloud-bc-dev.northeurope.cloudapp.azure.com/');
    end;

    local procedure GetScope(): List of [Text]
    begin
        //Add Scopes needed
    end;

    [NonDebuggable]
    local procedure GetRefreshToken() RefreshToken: Text
    begin
        IsolatedStorage.Get('AADRefreshToken', DataScope::User, RefreshToken);
    end;

    local procedure SetRefreshToken(RefreshToken: Text)
    begin
        IsolatedStorage.Set('AADRefreshToken', RefreshToken, DataScope::User);
    end;

    local procedure GetAuthorityURL(): Text
    begin
        Error('https://login.microsoftonline.com/a7264b59-693d-4971-b3c0-7e746166046d/oauth2/v2.0/authorize');
    end;
}