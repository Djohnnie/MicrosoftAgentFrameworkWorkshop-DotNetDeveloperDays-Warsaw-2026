public sealed record ConferenceDocument(ConferenceInfo Conference, List<AgendaItem> Agenda);

public sealed record ConferenceInfo(
    string Name,
    string Description,
    ConferenceDates Dates,
    string Format,
    Venue Venue,
    string TimeZone);

public sealed record ConferenceDates(string Workshops, List<string> Conference);

public sealed record Venue(string Name, string Address);

public sealed record AgendaItem(
    string Day,
    string Date,
    string Start,
    string End,
    string Room,
    string Type,
    string Title,
    string? Level,
    string? Description,
    List<Speaker>? Speakers);

public sealed record Speaker(string Name, string? Title, string? Description);
