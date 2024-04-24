permissionset 50100 Full
{
    Assignable = true;
    Permissions = tabledata SimpleEntry = RIMD,
        table SimpleEntry = X,
        page SimpleEntryList = X,
        codeunit EnqueueJobExternalRequest = X,
        codeunit InsertSimpleEntry = X,
        query ScheduledJobsPerApp = X,
        codeunit ScheduleJobAPI = X;
}