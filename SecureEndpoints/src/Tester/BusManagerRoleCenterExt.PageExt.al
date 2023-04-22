pageextension 50100 BusManagerRoleCenterExt extends "Business Manager Role Center"
{
    actions
    {
        addfirst(embedding)
        {
            action(SalesOrders)
            {
                ApplicationArea = All;
                Caption = 'Endpoint Tester';
                RunObject = page EndpointTester;
                ToolTip = 'Test various endpoints with higher security requirements.';
            }
        }
    }

}