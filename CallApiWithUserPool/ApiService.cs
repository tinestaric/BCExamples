using System.Net.Http.Headers;
using System.Text.Json;

namespace CallApiWithUserPool
{
    internal class ApiService
    {
        private readonly UserPoolManager userPool;
        private readonly string tokenEndpoint; // AAD Token URL

        public ApiService(UserPoolManager userPool, string tokenEndpoint)
        {
            this.userPool = userPool;
            this.tokenEndpoint = tokenEndpoint;
        }

        private async Task<string> GetAADTokenAsync(S2SUser user)
        {
            using (var httpClient = new HttpClient())
            {
                var parameters = new Dictionary<string, string>
            {
                {"grant_type", "client_credentials"},
                {"client_id", user.ClientId},
                {"client_secret", user.ClientSecret},
                {"scope", "https://api.businesscentral.dynamics.com/.default"}
            };

                var response = await httpClient.PostAsync(tokenEndpoint, new FormUrlEncodedContent(parameters));
                if (!response.IsSuccessStatusCode)
                {
                    throw new InvalidOperationException("Could not retrieve token.");
                }

                var responseContent = await response.Content.ReadAsStringAsync();
                var tokenJson = JsonSerializer.Deserialize<JsonElement>(responseContent);
                return tokenJson.GetProperty("access_token").GetString();
            }
        }

        public async Task<string> MakeApiCallAsync(string apiEndpoint)
        {
            var user = userPool.GetNextUser();
            var token = await GetAADTokenAsync(user);

            using (var httpClient = new HttpClient())
            {
                httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
                
                var response = await httpClient.PostAsync(apiEndpoint, null);
                if (!response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    return $"Failed to call API. Status: {response.StatusCode} Error: {responseContent}";
                }
                return await response.Content.ReadAsStringAsync();
            }
        }
    }
}
