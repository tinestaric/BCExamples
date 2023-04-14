interface IEndpoint
{
    procedure GetRequestMessage(Token: Text; Content: Text): HttpRequestMessage;
}