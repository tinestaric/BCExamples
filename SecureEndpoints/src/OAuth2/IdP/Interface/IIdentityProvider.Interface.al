interface IIdentityProvider
{
    procedure GetTokenWithAuthCode(): Text
    procedure GetTokenWithRefreshToken(): Text
    procedure GetTokenWithClientCredentials(): Text
}