using ModelContextProtocol.Server;
using System.ComponentModel;
using System.Globalization;
using System.Text.Json;

// Retain Lab 200's six tools; this workflow calls get_sessions_for_date directly from application code.
[McpServerToolType]
public sealed class ConferenceTools(AgendaRepository agenda)
{
    [McpServerTool(Name = "get_conference_info")]
    [Description("Get the conference name, description, format, venue, and time zone.")]
    public string GetConferenceInfo()
    {
        ConferenceInfo conference = agenda.Conference;
        return $"""
            {conference.Name}
            {conference.Description}
            Format: {conference.Format}
            Venue: {conference.Venue.Name}, {conference.Venue.Address}
            Time zone: {conference.TimeZone}
            """;
    }

    [McpServerTool(Name = "get_conference_dates")]
    [Description("Get the pre-conference workshop date and the conference dates.")]
    public string GetConferenceDates()
    {
        ConferenceDates dates = agenda.Conference.Dates;
        return $"Workshops: {dates.Workshops}; conference: {string.Join(", ", dates.Conference)}.";
    }

    [McpServerTool(Name = "get_speakers")]
    [Description("List all speakers in the conference agenda.")]
    public string GetSpeakers() =>
        string.Join(Environment.NewLine, agenda.Speakers.Select(speaker => speaker.Name));

    [McpServerTool(Name = "get_speaker_details")]
    [Description("Find speaker information by first name, last name, or full name. Partial name parts are accepted; if several speakers match, ask the user to clarify.")]
    public string GetSpeakerDetails(string name)
    {
        IReadOnlyList<Speaker> matches = agenda.FindSpeakers(name);
        if (matches.Count == 0)
            return $"No speaker matched '{name}'. Try a first name, last name, or full name from the speaker list.";

        if (matches.Count > 1)
            return $"More than one speaker matched: {string.Join(", ", matches.Select(speaker => speaker.Name))}. Ask the user which speaker they mean.";

        Speaker speaker = matches[0];
        string talks = string.Join(Environment.NewLine, agenda.Sessions
            .Where(item => item.Speakers?.Any(person =>
                string.Equals(person.Name, speaker.Name, StringComparison.OrdinalIgnoreCase)) == true)
            .Select(item => $"- {item.Date} {item.Start}, {item.Room}: {item.Title}"));

        return $"""
            {speaker.Name}
            {speaker.Title}
            {speaker.Description}
            Sessions:
            {talks}
            """;
    }

    [McpServerTool(Name = "get_sessions_for_date")]
    [Description("Return a JSON array of conference sessions for a date in yyyy-MM-dd format or a weekday name, with stable IDs, dates, times, rooms, descriptions and speakers. Breaks are excluded. An empty array means no sessions.")]
    public string GetSessionsForDate(string date)
    {
        IReadOnlyList<AgendaItem> sessions = agenda.GetSessionsForDate(date);
        // Lab 300 needs machine-readable facts, unlike Lab 200's formatted session list.
        // The composite ID identifies a slot in this snapshot; parallel rooms must have different IDs.
        return JsonSerializer.Serialize(sessions.Select(item => new
        {
            Id = $"{item.Date}|{item.Start}|{item.Room}",
            // Typed values serialize into the date/time formats expected by the client's SessionOption.
            Date = DateOnly.ParseExact(item.Date, "yyyy-MM-dd", CultureInfo.InvariantCulture),
            Start = TimeOnly.ParseExact(item.Start, "HH:mm", CultureInfo.InvariantCulture),
            End = TimeOnly.ParseExact(item.End, "HH:mm", CultureInfo.InvariantCulture),
            item.Room,
            item.Title,
            item.Description,
            Speakers = item.Speakers?.Select(speaker => speaker.Name).ToArray() ?? []
        }), JsonSerializerOptions.Web);
    }

    [McpServerTool(Name = "get_session_details")]
    [Description("Get a session's description, level, room, time, and speakers by title, or by date and exact starting time. Use title or both date and startTime.")]
    public string GetSessionDetails(string? title = null, string? date = null, string? startTime = null)
    {
        if (string.IsNullOrWhiteSpace(title)
            && (string.IsNullOrWhiteSpace(date) || string.IsNullOrWhiteSpace(startTime)))
        {
            return "Provide a session title, or provide both a date and exact start time.";
        }

        IReadOnlyList<AgendaItem> matches = agenda.FindSessions(title, date, startTime);
        if (matches.Count == 0)
            return "No session matched. Check the title, date, and start time; use get_sessions_for_date to see scheduled sessions.";

        if (matches.Count > 1)
            return $"Several sessions matched: {string.Join("; ", matches.Select(item => $"{item.Date} {item.Start} {item.Title}"))}. Ask the user to clarify.";

        AgendaItem session = matches[0];
        string speakers = string.Join(", ", session.Speakers?.Select(speaker => speaker.Name) ?? []);
        return $"""
            {session.Title}
            {session.Day}, {session.Date}, {session.Start}-{session.End}
            Room: {session.Room}
            Level: {session.Level ?? "not specified"}
            Speakers: {speakers}
            {session.Description}
            """;
    }
}
