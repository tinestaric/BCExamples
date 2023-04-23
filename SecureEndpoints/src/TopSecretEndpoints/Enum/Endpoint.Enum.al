enum 50102 Endpoint implements IEndpoint
{
    Extensible = true;

    value(1; AADEndpoint)
    {
        Implementation = IEndpoint = AADEndpoint;
        Caption = 'Azure Active Directory Endpoint';
    }
    value(2; FBEndpoint)
    {
        Implementation = IEndpoint = FBEndpoint;
        Caption = 'Facebook Endpoint';
    }
    value(3; CertificateEndpoint)
    {
        Implementation = IEndpoint = CertificateEndpoint;
        Caption = 'Certificate Endpoint';
    }
    value(4; WhitelistedEndpoint)
    {
        Implementation = IEndpoint = WhitelistedEndpoint;
        Caption = 'Whitelisted Endpoint';
    }
    value(5; ProxyWhitelistedEndpoint)
    {
        Implementation = IEndpoint = ProxyWhitelistedEndpoint;
        Caption = 'Proxy Whitelisted Endpoint';
    }
}