namespace CallApiWithUserPool
{
    internal class UserPoolManager
    {
        private List<S2SUser> users = new List<S2SUser>();
        private int currentIndex = -1;

        public UserPoolManager(IEnumerable<S2SUser> users)
        {
            this.users.AddRange(users);
        }

        public S2SUser GetNextUser()
        {
            if (users.Count == 0)
            {
                throw new InvalidOperationException("No users available in the pool.");
            }

            currentIndex = (currentIndex + 1) % users.Count;
            return users[currentIndex];
        }
    }

}
