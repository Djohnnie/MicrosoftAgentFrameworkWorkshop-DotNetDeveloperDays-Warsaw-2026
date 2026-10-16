using System.Reflection;
using System.Text.Json;

public sealed class AgendaRepository
{
    private readonly ConferenceDocument _document;

    private AgendaRepository(ConferenceDocument document)
    {
        _document = document;
    }

    public ConferenceInfo Conference => _document.Conference;

    public IReadOnlyList<AgendaItem> Sessions =>
        _document.Agenda.Where(item => item.Type != "break").ToArray();

    public IReadOnlyList<Speaker> Speakers =>
        _document.Agenda
            .SelectMany(item => item.Speakers ?? [])
            .DistinctBy(speaker => speaker.Name, StringComparer.OrdinalIgnoreCase)
            .OrderBy(speaker => speaker.Name, StringComparer.OrdinalIgnoreCase)
            .ToArray();

    public static AgendaRepository Load()
    {
        // The fixed logical resource name keeps loading independent of the server's working directory.
        using Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("agenda.json")
            ?? throw new InvalidOperationException("Embedded resource 'agenda.json' was not found.");

        ConferenceDocument document = JsonSerializer.Deserialize<ConferenceDocument>(
            stream,
            JsonSerializerOptions.Web)
            ?? throw new InvalidOperationException("Embedded agenda.json is empty or invalid.");

        return new AgendaRepository(document);
    }

    public IReadOnlyList<AgendaItem> GetSessionsForDate(string dateOrDay)
    {
        string? date = ResolveDate(dateOrDay);
        return date is null
            ? []
            : Sessions.Where(item => item.Date == date).OrderBy(item => item.Start).ToArray();
    }

    public IReadOnlyList<Speaker> FindSpeakers(string name)
    {
        string[] searchTerms = Normalize(name)
            .Split(' ', StringSplitOptions.RemoveEmptyEntries);

        if (searchTerms.Length == 0)
            return [];

        return Speakers
            .Where(speaker =>
            {
                string[] nameParts = Normalize(speaker.Name)
                    .Split(' ', StringSplitOptions.RemoveEmptyEntries);

                // Match every supplied name part by prefix; the tool reports ambiguity instead of picking one.
                return searchTerms.All(term =>
                    nameParts.Any(part => part.StartsWith(term, StringComparison.Ordinal)));
            })
            .ToArray();
    }

    public IReadOnlyList<AgendaItem> FindSessions(string? title, string? date, string? startTime)
    {
        // Combine supplied filters, so a title can be narrowed by date/time without another search strategy.
        IEnumerable<AgendaItem> matches = Sessions;

        if (!string.IsNullOrWhiteSpace(title))
        {
            string normalizedTitle = Normalize(title);
            matches = matches.Where(item =>
                Normalize(item.Title).Contains(normalizedTitle, StringComparison.Ordinal));
        }

        if (!string.IsNullOrWhiteSpace(date))
        {
            string? resolvedDate = ResolveDate(date);
            if (resolvedDate is null)
                return [];

            matches = matches.Where(item => item.Date == resolvedDate);
        }

        if (!string.IsNullOrWhiteSpace(startTime))
            matches = matches.Where(item => item.Start == startTime.Trim());

        return matches.OrderBy(item => item.Date).ThenBy(item => item.Start).ToArray();
    }

    public string? ResolveDate(string dateOrDay)
    {
        string query = dateOrDay.Trim();
        string? exactDate = _document.Agenda
            .Select(item => item.Date)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .FirstOrDefault(date => string.Equals(date, query, StringComparison.OrdinalIgnoreCase));

        if (exactDate is not null)
            return exactDate;

        // Weekday aliases resolve only to dates present in the snapshot, never the machine's current week.
        return _document.Agenda
            .FirstOrDefault(item => string.Equals(item.Day, query, StringComparison.OrdinalIgnoreCase))
            ?.Date;
    }

    private static string Normalize(string text) =>
        string.Join(' ', text.Trim().ToLowerInvariant()
            .Split(' ', StringSplitOptions.RemoveEmptyEntries));
}
