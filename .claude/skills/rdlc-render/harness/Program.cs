using System.Data;
using System.Globalization;
using System.Text.Json;
using Microsoft.Reporting.NETCore;

// Renders a BC/NAV RDLC layout offline from a flattened dataset produced by
// bcdataset.py. No BC server, no upload, no publish.
//
//   dotnet run -- --rdl CustomerDetailedAging.rdlc \
//                 --data out/dataset.json \
//                 --params out/parameters.json \
//                 --out render/report.pdf

var opts = ParseArgs(args);
string rdlPath    = Require(opts, "rdl");
string dataPath   = Require(opts, "data");
string outPath    = opts.GetValueOrDefault("out", "render/report.pdf");
string format     = opts.GetValueOrDefault("format", "PDF");   // PDF | HTML5 | EXCELOPENXML | WORDOPENXML | IMAGE
string? paramPath = opts.GetValueOrDefault("params");

using var doc = JsonDocument.Parse(File.ReadAllText(dataPath));
var rootEl = doc.RootElement;

// --- Culture -------------------------------------------------------------
// This is not a nicety. BC ships dates to the layout as pre-formatted strings
// ("01/18/23") and the layout calls CDate() on them. Render under sl-SI and
// that string either throws or parses to a different date than production.
// Pin the thread culture to the FormatRegion recorded in the dataset.
string culture = opts.GetValueOrDefault("culture")
                 ?? (rootEl.TryGetProperty("meta", out var m) && m.TryGetProperty("FormatRegion", out var fr)
                     ? fr.GetString() ?? "en-US" : "en-US");
var ci = CultureInfo.GetCultureInfo(culture);
CultureInfo.DefaultThreadCurrentCulture = ci;
CultureInfo.DefaultThreadCurrentUICulture = ci;
Console.WriteLine($"culture      : {ci.Name}");

// --- Build the DataTable BC would have handed the renderer ---------------
var table = new DataTable(rootEl.GetProperty("dataSetName").GetString());
var types = rootEl.GetProperty("types");
foreach (var col in rootEl.GetProperty("columns").EnumerateArray())
{
    string name = col.GetString()!;
    string t = types.TryGetProperty(name, out var tv) ? tv.GetString()! : "String";
    table.Columns.Add(name, t switch
    {
        "Double"   => typeof(double),
        "DateTime" => typeof(DateTime),
        "Int32"    => typeof(int),
        "Boolean"  => typeof(bool),
        _          => typeof(string)
    });
}

foreach (var rowEl in rootEl.GetProperty("rows").EnumerateArray())
{
    var row = table.NewRow();
    foreach (DataColumn c in table.Columns)
    {
        if (!rowEl.TryGetProperty(c.ColumnName, out var v) || v.ValueKind == JsonValueKind.Null)
        {
            row[c] = DBNull.Value;   // absent column -> null, NOT empty string.
            continue;                // tablix group filters depend on this.
        }
        string s = v.ToString() ?? "";
        if (c.DataType == typeof(double))
            row[c] = double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out var d)
                     ? d : (object)DBNull.Value;
        else if (c.DataType == typeof(DateTime))
            row[c] = DateTime.TryParse(s, ci, DateTimeStyles.None, out var dt)
                     ? dt : (object)DBNull.Value;
        else if (c.DataType == typeof(int))
            row[c] = int.TryParse(s, out var i) ? i : (object)DBNull.Value;
        else if (c.DataType == typeof(bool))
            row[c] = bool.TryParse(s, out var b) ? b : (object)DBNull.Value;
        else
            row[c] = s;
    }
    table.Rows.Add(row);
}
Console.WriteLine($"dataset      : {table.TableName}  {table.Rows.Count} rows x {table.Columns.Count} cols");

// --- Render --------------------------------------------------------------
var report = new LocalReport();
using (var fs = File.OpenRead(rdlPath)) report.LoadReportDefinition(fs);
report.DataSources.Add(new ReportDataSource(table.TableName, table));
report.EnableHyperlinks = true;
report.EnableExternalImages = true;

if (paramPath is not null && File.Exists(paramPath))
{
    using var pd = JsonDocument.Parse(File.ReadAllText(paramPath));
    var ps = pd.RootElement.EnumerateObject()
               .Select(p => new ReportParameter(p.Name, p.Value.GetString() ?? ""))
               .ToArray();
    if (ps.Length > 0) report.SetParameters(ps);
    Console.WriteLine($"parameters   : {string.Join(", ", ps.Select(p => p.Name))}");
}

// Expression compilation happens here. If the layout referenced a custom
// assembly this is where it would blow up -- BC's stock layouts do not.
byte[] bytes = report.Render(format);

Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(outPath))!);
File.WriteAllBytes(outPath, bytes);
Console.WriteLine($"rendered     : {outPath}  ({bytes.Length:N0} bytes, {format})");

static Dictionary<string, string> ParseArgs(string[] a)
{
    var d = new Dictionary<string, string>();
    for (int i = 0; i < a.Length; i++)
        if (a[i].StartsWith("--") && i + 1 < a.Length) d[a[i][2..]] = a[++i];
    return d;
}
static string Require(Dictionary<string, string> d, string k) =>
    d.TryGetValue(k, out var v) ? v : throw new ArgumentException($"--{k} is required");
