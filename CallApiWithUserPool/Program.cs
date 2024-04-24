using CallApiWithUserPool;

var users = new List<S2SUser>
    {
        new S2SUser("clientId1", "clientSecret1"),
        new S2SUser("clientId2", "clientSecret2"),
        new S2SUser("clientId3", "clientSecret3"),
    };

var tokenUrl = "https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token"; // Replace {tenantId} with your actual tenant ID
var userPool = new UserPoolManager(users);
var apiService = new ApiService(userPool, tokenUrl);

// Make an API call
for (var i = 0; i <10; i++)
{ 
    apiService.MakeApiCallAsync("https://api.businesscentral.dynamics.com/v2.0/{environmentName}/ODataV4/SimpleAPI_InsertEntry?company={CompanyName}"); // Replace with your actual endpoint and parameters
    Console.WriteLine("Sent");
}

Console.ReadKey();