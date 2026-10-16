// TODO 1: Read Foundry configuration and connect to http://localhost:5287/mcp.
//         Discover the tools and keep McpClient alive until the console exits.
// TODO 2: Create an IChatClient using Lab 200's Responses client setup.
// TODO 3: Use PlanningAgents.Create<T> to create three independent AIAgents:
//         SessionPicker -> CandidateSelection, ScheduleBuilder -> ScheduleDraft,
//         PlanReviewer -> PlanReview. Give each agent one focused responsibility.
// TODO 4: Read a date (yyyy-MM-dd), a same-day From/Until window (HH:mm),
//         and interests. Validate input in C#; handle quit and EOF at every prompt.
// TODO 5: Complete PlanningWorkflow.cs and call PlanningWorkflow.Build, passing
//         (date, token) => ConferenceAgendaClient.LoadAsync(mcpClient, date, token).
// TODO 6: Run it with InProcessExecution.RunStreamingAsync and a new PlanState.
//         Print ExecutorCompletedEvent handoffs and WorkflowOutputEvent results.
//         Report WorkflowErrorEvent explicitly; never show an invalid draft as approved.
// TODO 7: Render accepted sessions from the canonical catalog, ordered by Start.
//         Otherwise display reviewer feedback and validation errors.

Console.WriteLine("Lab 300 starter: the MCP server, models, JSON agent helper and C# schedule rules are ready.");
Console.WriteLine("Complete the workflow executors and console client. See the Lab 300 README.");
