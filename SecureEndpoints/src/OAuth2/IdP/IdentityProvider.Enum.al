enum 50101 IdentityProvider implements IIdentityProvider
{
    Extensible = true;

    value(0; AAD)
    {
        Implementation = IIdentityProvider = AADIdP;
    }
    value(1; Facebook)
    {
        Implementation = IIdentityProvider = FacebookIdP;
    }
}