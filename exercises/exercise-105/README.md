# Exercise 105 - Structured Output

> **Part:** Part 1, From LLM calls to agents\
> **Focus:** Request a typed employee with `GetResponseAsync<Employee>`\
> **History:** None; each request generates an independent fictional employee

## What you'll build

Instead of receiving free-form text, generate an `Employee` with a family name, first name, birth date, salary, and function title. The generic type argument tells the structured-output helper which C# type to return:

```csharp
public record Employee(
    string Name,
    string FirstName,
    DateOnly BirthDate,
    decimal Salary,
    string FunctionTitle);
```

`Name` is the family name, `BirthDate` is a date without a time, and `Salary` is the annual gross salary in EUR. All employee data is fictional.

## Run it

From this directory:

```powershell
dotnet run
```

Use the **.NET 10 SDK** and the [Foundry environment-variable setup from exercise 001](../exercise-001/README.md#1-set-your-microsoft-foundry-credentials). An optional, Git-ignored local `Properties\launchSettings.json` profile can supply these values; it is not included in a fresh clone. Otherwise, set the variables in the same PowerShell session before running. Use a deployment that supports JSON-schema structured output, such as GPT-4.1.

Describe the employee you want and press **Enter**. Type `quit` to exit.

## What changed?

The `ResponsesClient` setup, `OpenAI` 2.14.0, and `Microsoft.Extensions.AI` / `Microsoft.Extensions.AI.OpenAI` 10.11.0 packages are unchanged from exercises 101-104. This exercise uses their generic structured-output helper:

```csharp
using IChatClient chatClient = client.AsIChatClient(model);

var response = await chatClient.GetResponseAsync<Employee>(
    $"Generate one fictional adult employee based on this request: {input}. " +
    "Name is the family name. Salary is the annual gross salary in EUR.",
    useJsonSchemaResponseFormat: true);

Employee employee = response.Result;
```

The adapter still calls the Responses API. `GetResponseAsync<Employee>` derives a JSON schema from the record, requests schema-constrained output, and deserializes the result into an `Employee`. Setting `useJsonSchemaResponseFormat: true` explicitly requests structured output from the model rather than relying on a prompt that merely asks for JSON.

The console serializes the typed object as indented JSON for readability. You can also use its properties directly in C#; no manual text parsing or hand-written JSON schema is needed.

Structured output constrains the shape, not the truth or business validity of the values. Application code must still validate rules such as an adult birth date or a nonnegative salary. Refusals, unsupported models, invalid output, and request failures surface as exceptions; this exercise deliberately does not add recovery logic.

There is no conversation history, persona, or Agent Framework agent here, so each request focuses on generating one typed object.

## Try it

1. Request "A senior C# developer working in Warsaw."
2. Request "A junior accountant working in Brussels."
3. Compare the same five fields and their types in both responses.
4. Add a property to `Employee`, rebuild, and observe how the generated output changes.

Read [Microsoft Learn: Request a response with structured output](https://learn.microsoft.com/en-us/dotnet/ai/quickstarts/structured-output).
