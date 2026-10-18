public static class PlanRules
{
    public static string[] Validate(PlanState state)
    {
        // Collect actionable feedback for the next draft rather than asking an LLM to do time arithmetic.
        List<string> errors = [];
        if (state.Draft.Length == 0)
            errors.Add("The draft is empty. Select at least one candidate.");

        var seen = new HashSet<string>(StringComparer.Ordinal);
        List<SessionOption> selected = [];
        foreach (SessionChoice choice in state.Draft)
        {
            if (!seen.Add(choice.SessionId))
                errors.Add($"Duplicate session ID: {choice.SessionId}.");

            // A real agenda ID is not sufficient: the builder must stay within the picker's candidates.
            SessionOption? session = state.Catalog.FirstOrDefault(item => item.Id == choice.SessionId);
            if (session is null || !state.Candidates.Any(item => item.SessionId == choice.SessionId))
            {
                errors.Add($"Unknown or non-candidate session ID: {choice.SessionId}.");
                continue;
            }

            if (string.IsNullOrWhiteSpace(choice.Reason))
                errors.Add($"Missing recommendation reason: {choice.SessionId}.");
            if (session.Date != state.Request.Date
                || session.Start < state.Request.From || session.End > state.Request.Until
                || session.End <= session.Start)
                errors.Add($"Session outside the requested date/time window: {session.Title}.");
            selected.Add(session);
        }

        // Checking in start-time order detects conflicts regardless of the model's output order.
        // Strict "<" allows back-to-back sessions; this lab does not add travel time between rooms.
        SessionOption[] ordered = selected.OrderBy(item => item.Start).ToArray();
        for (int i = 1; i < ordered.Length; i++)
        {
            if (ordered[i].Start < ordered[i - 1].End)
                errors.Add($"Overlap: {ordered[i - 1].Title} / {ordered[i].Title}.");
        }

        return errors.ToArray();
    }
}
