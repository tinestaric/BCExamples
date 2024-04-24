namespace CallApiWithUserPool
{
    internal class S2SUser
    {
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }  // Consider using a more secure method to handle passwords

        public S2SUser(string clientId, string clientSecret)
        {
            ClientId = clientId;
            ClientSecret = clientSecret;
        }
    }

}
