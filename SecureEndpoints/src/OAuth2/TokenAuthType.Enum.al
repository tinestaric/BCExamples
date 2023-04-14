enum 50100 TokenAuthType
{
    Extensible = true;

    value(0; None) { }
    value(1; AuthCode) { }
    value(2; RefreshToken) { }
    value(3; ClientCredentials) { }
}