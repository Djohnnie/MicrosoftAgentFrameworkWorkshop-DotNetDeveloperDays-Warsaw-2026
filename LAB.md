# Lab: Build DevDays Buddy

This is the original four-part scenario outline, not the instructions for the
implemented numbered labs. Use these READMEs for the current workshop:

| Part | Implemented material |
| --- | --- |
| 1 | [Lab 100](labs/lab-100/README.md): an agent grounded in the conference agenda |
| 2 | [Lab 200](labs/lab-200/README.md): agenda tools hosted in an MCP server |
| 3 | [Lab 300](labs/lab-300/README.md): a three-agent workflow with C# schedule validation |
| 4 | [Authentication exercises](exercises/exercise-401/README.md) and a [Foundry agent invocation](exercises/exercise-405/README.md); no Lab 400 is implemented |

The implemented labs use the bundled DeveloperDays agenda, not the fictional
catalog proposed below. Their READMEs take precedence over this original outline.

Build a friendly conference assistant that helps attendees discover sessions and
put together a schedule. The same small application grows throughout the
workshop: first it can chat, then it can use tools, then it can coordinate
specialist agents, and finally it becomes more reliable and ready to run.

The goal is to experience the ideas in each part of the workshop in one
continuous, practical exercise—not to build a full conference platform. Keep
the data local, the interface simple, and the steps small enough to complete
incrementally.

## The scenario

An attendee tells DevDays Buddy what they are interested in, their experience
level, and how much time they have. The assistant recommends relevant sessions,
checks that they do not overlap, and explains its choices.

For example:

> I’m new to AI, interested in cloud security, and have two hours free. Make me
> a realistic schedule and explain why you chose those sessions.

Use a small fictional session catalog stored in a local JSON file. Each session
can have an ID, title, description, topics, level, start time, end time, and
room. This avoids external APIs and setup while still giving the assistant
useful information to reason over.

## The four proposed parts

### Part 1 — From an LLM call to an agent

Start with a minimal console chat application using the Microsoft Agent
Framework. Give the assistant a clear role: help attendees explore the
conference, ask clarifying questions when a request is vague, and never invent
session details.

Build up from a single model call to a conversational agent that remembers
earlier turns. Try a few attendee questions, including one that needs
clarification and one that asks about a session not in the catalog.

**You are done when:** the assistant can hold a short conversation, follow its
role, and distinguish what it knows from what it would need to look up.

### Part 2 — Give the agent capabilities: tools and MCP

Add tools that let the assistant work with the session catalog instead of
guessing. Start with a session search tool that accepts a topic or keyword.
Then add a schedule-building or availability-checking tool that can identify
sessions in a requested time window and flag overlaps.

Have the assistant choose when to call each tool, present the results in plain
language, and handle searches that return no matches. Keep the tools focused:
the model decides what to do, while the application code performs the actual
lookup and schedule checks.

If MCP is being covered in this part, expose one catalog capability through an
MCP server or connect to a provided MCP server. Treat that as an alternate way
to provide a capability; the core exercise still works with in-process tools.

**You are done when:** recommendations are grounded in catalog results and the
assistant can explain when a session search or schedule check was used.

### Part 3 — Orchestrate agents and workflows

Split the work between two focused agents:

- **Session Scout** finds relevant sessions and summarizes why they match the
  attendee's interests and experience.
- **Itinerary Planner** turns candidate sessions into a schedule that fits the
  attendee's available time and avoids overlaps.

Add a coordinating agent or workflow that passes the attendee's request to the
right specialists, combines their results, and returns one useful answer. Make
the handoff explicit: the planner should use the scout's actual candidates,
rather than independently inventing or searching for sessions.

Try a request that requires both specialists, and then a simpler request that
needs only one. Notice whether the extra orchestration helps enough to justify
its complexity.

**You are done when:** the coordinated result contains relevant sessions, fits
the requested time, avoids conflicts, and reads like one coherent response.

### Part 4 — Make the assistant reliable and production-minded

Harden the app against ordinary failures and awkward inputs. Validate tool
arguments and session data; handle empty results, malformed data, and tool or
model errors without presenting invented success. Add concise logging around
tool calls and agent handoffs, while avoiding attendee secrets or unnecessary
personal data in logs.

Add a few focused checks for important behavior: a session search returns only
matching catalog entries, conflicting sessions are not scheduled together,
and a failed lookup is reported clearly. Review the assistant's instructions
and tool boundaries so it cannot claim a schedule is valid unless the
application's checks confirm it.

**You are done when:** expected failures are visible and understandable, core
schedule rules are checked by code, and a small set of tests protects those
rules.

## Suggested progression

Keep one working application and build on it after each workshop part. At each
stage, run the same attendee request and compare how the result improves:

1. A conversational answer, without access to conference data.
2. A grounded answer based on catalog tools.
3. A coordinated recommendation and conflict-free itinerary.
4. The same experience with validation, useful failure handling, and tests.

The finished lab should remain deliberately small: a console interface, a
fictional local catalog, a handful of tools, and only the orchestration needed
to demonstrate the workshop concepts.
