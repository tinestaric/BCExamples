query 50100 ScheduledJobsPerApp
{
    Access = Internal;
    UsageCategory = Administration;
    ReadState = ReadUncommitted;
    OrderBy = ascending(Count);

    elements
    {
        dataitem(AAD_Application; "AAD Application")
        {
            filter(Use_for_Job_Queues; "Use for Job Queues")
            {
                ColumnFilter = Use_for_Job_Queues = const(true);
            }
            column(Client_Id; "Client Id") { }

            dataitem(Job_Queue_Entry; "Job Queue Entry")
            {
                DataItemLink = "User ID" = AAD_Application.Description;
                SqlJoinType = LeftOuterJoin;

                column(Count)
                {
                    Method = Count;
                }
            }
        }
    }

    internal procedure FindLeastLoadedApp() AADApp: Record "AAD Application"
    begin
        CurrQuery.Open();
        CurrQuery.Read();
        AADApp.Get(CurrQuery.Client_Id);
    end;
}