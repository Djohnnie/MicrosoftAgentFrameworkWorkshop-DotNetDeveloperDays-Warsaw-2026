// TODO 1: Configure a versioned Foundry Prompt Agent with File Search over ..\agenda.json.
//         Use the instructions and JSON contract in the Lab 400 README.
// TODO 2: Read TENANT_ID, CLIENT_ID, CLIENT_SECRET, FOUNDRY_ENDPOINT,
//         FOUNDRY_AGENT_NAME and FOUNDRY_AGENT_VERSION.
//         Create ClientSecretCredential, AIProjectClient and a FoundryAgent via
//         AsAIAgent(new AgentReference(name, version)). Do not use classic asst_ IDs.
// TODO 3: Read FOUNDRY_API_KEY and FOUNDRY_MODEL_DEPLOYMENT. Adapt a ResponsesClient
//         at the resource's /openai/v1 endpoint to IChatClient, as in Lab 300.
//         Create ONLY ScheduleBuilder and PlanReviewer with PlanningAgents.Create<T>.
// TODO 4: Complete FoundrySessionPicker.PickAsync with a fresh server-side conversation.
//         Send the PlanRequest and output contract; do not inject the local agenda into the prompt.
// TODO 5: Load ConferenceAgenda.Load(). Read and validate date, availability and interests.
//         Preserve Lab 300's quit/EOF behavior, stage panels and accepted-only final table.
// TODO 6: Call PlanningWorkflow.Build with
//         (request, token) => FoundrySessionPicker.PickAsync(picker, request, token),
//         scheduler, reviewer, and a delegate returning the local catalog for one day.
//         Run with InProcessExecution.RunStreamingAsync and a fresh PlanState.
// TODO 7: Report WorkflowErrorEvent and missing final output explicitly.
//         Keep C# validation and the two-revision cap; never treat model approval as proof.

Console.WriteLine("Lab 400 starter: Lab 300's graph, local agents, agenda reader and C# rules are supplied.");
Console.WriteLine("Configure the hosted picker and complete the integration. See the Lab 400 README.");
