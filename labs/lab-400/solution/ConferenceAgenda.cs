using System.Globalization;
using System.Reflection;
using System.Text.Json;

public static class ConferenceAgenda
{
    public static SessionOption[] Load()
    {
        using Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("agenda.json")
            ?? throw new InvalidOperationException("Embedded resource 'agenda.json' was not found.");
        using JsonDocument document = JsonDocument.Parse(stream);
        return document.RootElement.GetProperty("agenda").EnumerateArray()
            .Where(item => item.GetProperty("type").GetString() != "break")
            .Select(item =>
            {
                string date = Required(item, "date");
                string start = Required(item, "start");
                string room = Required(item, "room");
                return new SessionOption(
                    $"{date}|{start}|{room}",
                    DateOnly.ParseExact(date, "yyyy-MM-dd", CultureInfo.InvariantCulture),
                    TimeOnly.ParseExact(start, "HH:mm", CultureInfo.InvariantCulture),
                    TimeOnly.ParseExact(Required(item, "end"), "HH:mm", CultureInfo.InvariantCulture),
                    room, Required(item, "title"),
                    item.TryGetProperty("description", out var description) ? description.GetString() : null,
                    item.TryGetProperty("speakers", out var speakers)
                        ? speakers.EnumerateArray().Select(speaker => Required(speaker, "name")).ToArray() : []);
            }).ToArray();
    }

    private static string Required(JsonElement item, string name) =>
        item.GetProperty(name).GetString()
        ?? throw new InvalidOperationException($"Agenda field '{name}' must not be null.");
}
