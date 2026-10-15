# Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework

**.NET DeveloperDays Warsaw 2026**

Workshop slides and materials for building GenAI-enabled .NET applications with
the Microsoft Agent Framework. Regenerate the SVG slides with
[`_tools\build-slides.ps1`](_tools/build-slides.ps1) or export the PowerPoint
deck with [`_tools\svg_to_pptx.ps1`](_tools/svg_to_pptx.ps1).

## Presentation slides

### Slide 1 - Hands-on building GenAI enabled .NET applications using the Microsoft Agent Framework
![Slide 01](_slides/slide-01.svg)

> **TL;DR:** We are learning how to build GenAI-enabled .NET applications with the Microsoft Agent Framework.

This workshop takes you from GenAI fundamentals to practical .NET applications built with the Microsoft Agent Framework. Across the session, you will move from calling an LLM to giving agents tools, coordinating their work, and making them more reliable.

### Slide 2 - About the speaker
![Slide 02](_slides/slide-02.svg)

> **TL;DR:** You are learning from hands-on experience in .NET, Azure, and generative AI.

Johnny Hooyberghs brings 18 years of software experience to the workshop, with a focus on .NET application development, Azure, and generative AI. He has been a Microsoft MVP in Developer Technologies and Azure since 2020, and works as a public speaker and trainer.

### Slide 3 - Follow along
![Slide 03](_slides/slide-03.svg)

> **TL;DR:** Scan the QR code to open the workshop repository.

Use the QR code to open the workshop repository and follow along with its slides and materials. The repository also contains the exercises you will use to try the concepts in code.

### Slide 4 - Full-day workshop agenda
![Slide 04](_slides/slide-04.svg)

> **TL;DR:** You are following a full-day path from GenAI fundamentals to reliable, production-ready agents.

The agenda starts with GenAI fundamentals, then moves through four workshop parts: building agents from LLM calls, giving agents tools and MCP capabilities, orchestrating agents and workflows, and improving reliability for production. Breaks and lunch separate the sessions across the day.

### Slide 5 - Introduction to GenAI
![Slide 05](_slides/slide-05.svg)

> **TL;DR:** You are starting with the GenAI foundations for the hands-on workshop.

This opening section introduces generative AI before you build applications and agents with the Microsoft Agent Framework. It sets up the core concepts that the later hands-on parts put into practice.

### Slide 6 - The evolution of AI
![Slide 06](_slides/slide-06.svg)

> **TL;DR:** AI has progressed from hand-written rules to systems that learn and generate.

The slide traces four approaches: people write rules, machine-learning models learn from examples, deep-learning networks learn richer representations, and generative models create new content such as text, images, audio, and code. This progression adds capabilities rather than making every earlier technique obsolete; the right approach depends on the task.

### Slide 7 - Types of machine learning
![Slide 07](_slides/slide-07.svg)

> **TL;DR:** You are comparing learning methods by the feedback and objectives they use.

The slide compares the feedback each method uses. Supervised learning learns a mapping from inputs to labeled answers, unsupervised learning finds structure such as clusters without answer labels, and reinforcement learning tries actions in an environment and uses rewards or penalties to improve outcomes over time.

### Slide 8 - The reinforcement loop
![Slide 08](_slides/slide-08.svg)

> **TL;DR:** An agent improves by acting in an environment and learning from rewards.

The diagram follows a repeated cycle: an agent chooses an action, that action changes the environment, and the environment returns a new state and reward. The reward scores the outcome and updates the agent's policy, shaping which actions it tries next.

### Slide 9 - AI is not one thing
![Slide 09](_slides/slide-09.svg)

> **TL;DR:** AI combines many capabilities, and LLMs specialize in generating language.

The slide groups AI capabilities into prediction, perception, recommendation, and generation, with examples such as fraud detection, speech recognition, personalization, and text or code creation. Large language models belong to the generative category; they are one kind of AI model, not a synonym for the whole field.

### Slide 10 - What is a model?
![Slide 10](_slides/slide-10.svg)

> **TL;DR:** A model learns patterns from examples and applies them to new inputs.

The diagram separates training from use: a learning algorithm processes examples to produce a trained model, and the model then applies its learned patterns to new inputs. Depending on the model, the output may be a prediction or generated content; an LLM specializes in generating language token by token.

### Slide 11 - How LLMs work
![Slide 11](_slides/slide-11.svg)

> **TL;DR:** An LLM generates text by predicting one token at a time.

The five-step flow starts with a prompt, splits its text into token IDs, converts those IDs into vectors, and scores possible next tokens. The model selects one token, appends it to the sequence, and repeats the prediction loop until it reaches a stopping condition. Because models process tokens rather than words or lines, token counts affect both context limits and usage.

### Slide 12 - Exercise 001: Tokenization demo
![Slide 12](_slides/slide-12.svg)

[Exercise 001 README](exercises/exercise-001/README.md)

> **TL;DR:** Run the Token Visualizer to see how tokenization affects context size and cost.

Configure the Microsoft Foundry endpoint, key, and model, then run the Token Visualizer console app and send it a message. Try natural-language sentences, C# code, and identifiers to inspect how each becomes a token stream, then compare local counts with API usage. The exercise shows why wording and formatting can affect context size and cost.

### Slide 13 - Why LLMs hallucinate
![Slide 13](_slides/slide-13.svg)

> **TL;DR:** Ground and verify LLM answers because fluent language does not prove a claim is true.

LLMs optimize for predicting likely text that fits the context, not for verifying whether each claim is true. When context lacks needed facts or contains stale information, a model can fill the gap with a plausible-sounding answer, and confident style can make the error harder to spot. Ground responses in evidence, verify important claims, use tools for current facts, and keep human review for consequential or safety-sensitive decisions.

### Slide 14 - RAG: giving an LLM the right knowledge
![Slide 14](_slides/slide-14.svg)

> **TL;DR:** RAG retrieves relevant information and gives it to an LLM as context for an answer.

Retrieval-Augmented Generation first uses a question and its intent to search documents or chunks for relevant information. It then places the retrieved context alongside the prompt so the model can draft an evidence-based answer. RAG adds knowledge at answer time, but results still depend on finding the right passages, trusting the sources, and using the context correctly.

### Slide 15 - Beyond chatbots
![Slide 15](_slides/slide-15.svg)

> **TL;DR:** An agent uses decisions and actions to pursue a goal beyond answering a prompt.

A chatbot typically answers a prompt or one turn at a time, and it cannot take action unless an application connects it to tools. An agent interprets a goal and its current state, chooses a tool or action, observes the result, and continues as needed. Agents can still chat, but they add decision-making and action around the model.

### Slide 16 - Agent orchestration
![Slide 16](_slides/slide-16.svg)

> **TL;DR:** An orchestrator coordinates specialized agents to reach a shared outcome.

An orchestrator routes work and manages handoffs between agents with focused responsibilities. A planner breaks a goal into tasks, a researcher finds relevant facts, and a builder or reviewer creates a result and checks it against the request. Specialization can help with complex work, while people should stay in control of consequential actions.

### Slide 17 - What is Microsoft Agent Framework?
![Slide 17](_slides/slide-17.svg)

> **TL;DR:** Microsoft Agent Framework brings together agents, workflows, and integrations for building production-grade AI applications.

Microsoft Agent Framework is an open framework for building AI agents and multi-agent workflows in .NET and Python. It brings together individual agents that use models, tools, and MCP servers; harness agents that support long-running tasks with planning, memory, file access, and approvals; workflows that connect agents and functions through explicit paths; and integrations for model providers, middleware, context, evaluation, and UI. It also provides building blocks such as session state, middleware, and observability.

Read the [Microsoft Learn overview](https://learn.microsoft.com/en-us/agent-framework/overview/?pivots=programming-language-csharp) and the [framework README](https://github.com/microsoft/agent-framework/blob/main/README.md).

### Slide 18 - Agents or workflows?
![Slide 18](_slides/slide-18.svg)

> **TL;DR:** Use agents for open-ended tasks and workflows when you need explicit control over coordinated steps.

Use an agent when a task is open-ended or conversational and needs the model to plan or choose tools. Use a workflow when the process has defined steps, needs explicit execution order, or coordinates multiple agents or functions. If a regular function handles the task, choose that simpler option instead.

Read the [Microsoft Learn overview](https://learn.microsoft.com/en-us/agent-framework/overview/?pivots=programming-language-csharp) and the [framework README](https://github.com/microsoft/agent-framework/blob/main/README.md).

### Slide 19 - Part 1: From LLM calls to agents
![Slide 19](_slides/slide-19.svg)

> **TL;DR:** Turn a basic LLM call into a conversational agent that can follow a role and remember earlier turns.

Part 1 moves from a minimal console chat and a single model call to a conversational agent that remembers earlier turns. Give the assistant a clear role, teach it to ask for clarification when a request is vague, and check that it does not invent details when it lacks information.

### Slide 20 - Exercise 101: Simple Chatbot
![Slide 20](_slides/slide-20.svg)

[Exercise 101 README](exercises/exercise-101/README.md)

> **TL;DR:** Chat with a language model through independent requests that do not retain conversation history.

Run the console app and talk to a Microsoft Foundry model through `IChatClient`, adapting the OpenAI SDK's Responses client and using the same environment variables as exercise 001. Send a message with `GetResponseAsync` and print `response.Text`. Each request contains only the current message, with no agent or earlier turns, so follow-ups have no prior context. This establishes the stateless baseline before agents and conversation history are introduced.

### Slide 21 - Exercise 102: Chatbot with History
![Slide 21](_slides/slide-21.svg)

[Exercise 102 README](exercises/exercise-102/README.md)

> **TL;DR:** Send earlier user messages and assistant replies with each new question so follow-ups have context.

Keep a `List<ChatMessage>` outside the loop and append both sides of the conversation. Pass the history to `GetResponseAsync` and retain `response.Messages`. Each request sends the full history, allowing the model to understand follow-ups. Compare the behavior with exercise 101, then restart the app to discard the history. Longer conversations use more input tokens.

### Slide 22 - Exercise 103: Chatbot Personas
![Slide 22](_slides/slide-22.svg)

[Exercise 103 README](exercises/exercise-103/README.md)

> **TL;DR:** Add a system prompt to give the chatbot a persona while keeping conversation history.

Build on exercise 102 by updating a system `ChatMessage` at the start of the history. The chatbot starts as a curious, cheerful 10-year-old, then gets two years younger after each reply: 10, 8, 6, 4, 2, 0, staying at zero. Replace the persona instruction while retaining the user and assistant history. Compare tone and vocabulary as the age changes, ending with baby-like babbling. The prompt guides behavior but does not change the model or guarantee factual answers.

### Slide 23 - Exercise 104: Structured Output
![Slide 23](_slides/slide-23.svg)

[Exercise 104 README](exercises/exercise-104/README.md)

> **TL;DR:** Use a C# generic type to generate an employee with a predictable output shape.

Define an `Employee` record with name, first name, birth date, salary, and function title. Adapt the Responses client to `IChatClient` and call `GetResponseAsync<Employee>` with JSON-schema output enabled, using a deployment that supports structured output. Read the typed result and display it as JSON. The schema constrains the structure, but application code must still validate business rules and values.

### Slide 24 - Exercise 105: Local Ollama Chatbot
![Slide 24](_slides/slide-24.svg)

[Exercise 105 README](exercises/exercise-105/README.md)

> **TL;DR:** Use a local Ollama model while keeping the same chat interface and conversation history.

Run `qwen2.5:7b` locally with Ollama and replace exercise 102's Foundry client with `OllamaApiClient`. The `IChatClient` conversation loop and history stay unchanged. No Foundry credentials are needed; compare the responses and speed with the cloud model.

### Slide 25 - Exercise 106: Chatbot Agent
![Slide 25](_slides/slide-25.svg)

[Exercise 106 README](exercises/exercise-106/README.md)

> **TL;DR:** Create an agent with persona instructions and reuse a session to keep conversation context.

Wrap the Foundry-backed `IChatClient` in an `AIAgent` using `ChatClientAgentOptions`, `InMemoryChatHistoryProvider`, and `ChatOptions.Instructions` for a cheerful persona whose age stays at 10. `RawRepresentationFactory` sets `CreateResponseOptions.StoredOutputEnabled = false` so history is kept in the local session, not continued through stored server responses. Create one `AgentSession` before the loop and pass it to each `RunAsync` call. After every reply, `DebugHistory` uses `TryGetInMemoryChatHistory` to print the actual local messages; they are still sent to Foundry for inference. This is the final exercise of Part 1; tools and workflows come later.

### Slide 26 - Lab 100: DevDays Buddy
![Slide 26](_slides/slide-26.svg)

[Lab 100 README](labs/lab-100/README.md)

> **TL;DR:** Build an agent that answers questions about the .NET DeveloperDays Warsaw 2026 agenda.

Combine everything from Part 1 in a lab with an empty `starter` and a possible `solution`. The conference description and the full Tuesday and Wednesday agenda—day, time, room, session title and description, and speaker names and descriptions—are hard-coded in `agenda.json`, compiled in as an embedded resource, and placed in the agent instructions as context. One `AgentSession` keeps follow-up questions in context, and Spectre.Console adds a banner, a thinking spinner, answer panels, and an `agenda` table. The whole agenda is sent with every request, which motivates the tools in Part 2.

### Slide 27 - Part 2: Giving agents capabilities: tools and MCP
![Slide 27](_slides/slide-27.svg)

> **TL;DR:** Give agents tools and MCP capabilities so they can look up information instead of guessing.

Part 2 starts with a familiar history-based chatbot and gives it separate tools for the current date and time. The model chooses when to call a focused capability, while application code performs the actual lookup. The exercises then introduce dependency injection and MCP discovery and hosting. In the broader DevDays Buddy conference-assistant scenario, future tools could ground responses by searching a session catalog or checking schedule availability and conflicts.

### Slide 28 - Exercise 201: Chatbot Agent with Tools
![Slide 28](_slides/slide-28.svg)

[Exercise 201 README](exercises/exercise-201/README.md)

> **TL;DR:** Use an AIAgent with separate tools that return the current local time and date.

Wrap the Foundry `IChatClient` in an `AIAgent`, create independent `get_current_time` and `get_current_date` functions with `AIFunctionFactory`, and make them available through the agent's `ChatClientAgentOptions`. An in-memory history provider retains context in an `AgentSession`; `StoredOutputEnabled = false` prevents a server-side conversation ID from conflicting with that local history, and `UseFunctionInvocation()` executes functions selected by the model. The tools return values from the computer running the app.

### Slide 29 - Exercise 202: Local Chatbot with Tools
![Slide 29](_slides/slide-29.svg)

[Exercise 202 README](exercises/exercise-202/README.md)

> **TL;DR:** Run exercise 201's date and time tools with a local Ollama model instead of Foundry.

Keep the same agent, tool functions, and in-memory session history, but use `OllamaApiClient` with `qwen2.5:7b` on `http://localhost:11434`. No Foundry credentials are needed; Ollama and the model must be running locally.

### Slide 30 - Exercise 203: Dependency Injection for Agent Tools
![Slide 30](_slides/slide-30.svg)

[Exercise 203 README](exercises/exercise-203/README.md)

> **TL;DR:** Pass an `IServiceProvider` to `AsAIAgent` so tool methods can resolve dependencies.

Register `TimeProvider` in a `ServiceCollection` and add `IServiceProvider` to the date/time tool method signatures. `AIFunctionFactory` keeps that parameter out of the model-facing schema; during invocation, the agent supplies its configured service provider. Do not put `UseFunctionInvocation()` in the chat-client pipeline here, because the agent needs to create the function-invocation layer that uses the provider passed to `AsAIAgent`. Disable Responses storage so server-side conversation IDs do not conflict with the local session history.

### Slide 31 - Exercise 204: Microsoft Learn MCP Agent
![Slide 31](_slides/slide-31.svg)

[Exercise 204 README](exercises/exercise-204/README.md)

> **TL;DR:** Discover Microsoft Learn's remote MCP tools and use them in an agent conversation.

Connect to `https://learn.microsoft.com/api/mcp` over Streamable HTTP, call `ListToolsAsync`, and print each tool's name and description so the user can see what they can ask. Pass those MCP tools to an `AIAgent`; the agent can invoke them during the conversation. `DebugHistory` makes tool calls and results visible. The public endpoint requires no authentication or API key.

### Slide 32 - Exercise 205: Host Date and Time MCP Tools
![Slide 32](_slides/slide-32.svg)

[Exercise 205 README](exercises/exercise-205/README.md)

> **TL;DR:** Host exercise 201's date and time tools in ASP.NET Core and call them from a separate agent client.

Exercise 205 splits MCP hosting and consumption into two projects. The ASP.NET server exposes the current local date and time through MCP over Streamable HTTP, with `TimeProvider` injected into the tool class by ASP.NET Core's DI container. The console client connects to `http://localhost:5285/mcp`, lists the server's tools, and provides them to a Foundry-backed `AIAgent`. Run the server first in one terminal, then the client in another.

### Slide 33 - Lab 200: DevDays Buddy MCP Tools
![Slide 33](_slides/slide-33.svg)

[Lab 200 README](labs/lab-200/README.md)

> **TL;DR:** Replace Lab 100's full-agenda prompt context with focused conference MCP tools.

Build an ASP.NET MCP server with an embedded `agenda.json` and six tools for conference information, dates, speakers, and sessions. A separate console agent discovers and invokes those tools; the entire agenda is never added to the agent's instructions.

### Slide 34 - Lab 200: Build the Agenda MCP Server
![Slide 34](_slides/slide-34.svg)

Implement tools for the conference name and description, dates, speaker list and speaker lookup, sessions by date, and session details by title or date and start time. Deterministic partial matching should return ambiguity candidates instead of silently selecting the wrong speaker or session.

### Slide 35 - Lab 200: Connect the DevDays Buddy Agent
![Slide 35](_slides/slide-35.svg)

Run the MCP server and console client as separate processes. The client discovers tools over Streamable HTTP and supplies them to an `AIAgent`; only the selected tool results and conversation history are sent to the model, not the full agenda document.

### Slide 36 - Part 3: Orchestrating agents and workflows
![Slide 36](_slides/slide-36.svg)

> **TL;DR:** Coordinate specialist agents and workflows to combine their work into one useful result.

Part 3 splits a larger request between a Session Scout and an Itinerary Planner, then uses an orchestrator or workflow to coordinate their handoffs. The scout finds and explains relevant sessions; the planner uses those actual candidates to build a schedule within the attendee's available time and avoid overlaps. The exercise also compares when this extra coordination helps and when one specialist is enough.

### Slide 37 - Part 4: Making agents reliable and production-ready
![Slide 37](_slides/slide-37.svg)

> **TL;DR:** Make agents reliable with validation, clear failure handling, logging, and tests.

Part 4 improves agent reliability with input and data validation, understandable error handling, concise logging, and tests for important behavior. It also reinforces that application code—not an unsupported model claim—should verify critical rules such as whether a proposed schedule contains conflicts.

### Slide 38 - Any questions?
![Slide 38](_slides/slide-38.svg)

> **TL;DR:** You are wrapping up with time for questions and a link to the workshop materials.

Use the closing slide to ask questions and continue exploring the workshop repository. The link points attendees back to the materials so they can revisit the slides and exercises after the session.
