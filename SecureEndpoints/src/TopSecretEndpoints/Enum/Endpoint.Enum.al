enum 50102 Endpoint implements IEndpoint
{
    Extensible = true;

    value(1; FBEndpoint)
    {
        Implementation = IEndpoint = FBEndpoint;
    }
    value(2; AADEndpoint)
    {
        Implementation = IEndpoint = AADEndpoint;
    }
    value(3; CertificateEndpoint)
    {
        Implementation = IEndpoint = CertificateEndpoint;
    }
}