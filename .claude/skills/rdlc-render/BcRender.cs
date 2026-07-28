// Renders a BC/NAV RDLC layout offline from a flattened dataset produced by
// bcdataset.py. No BC server, no upload, no publish.
//
// Built by bootstrap.ps1 with the in-box .NET Framework compiler
// (csc.exe) against Microsoft's own ReportViewer 15 assemblies -- not the
// ReportViewerCore.NETCore community fork that harness/Program.cs (the
// .NET 8 / cross-platform fallback) depends on. This is C# 5 / .NET
// Framework 4, deliberately: no `var`, no null-conditional, no target-typed
// `new`, no top-level statements -- csc.exe that ships with Windows does not
// support the newer syntax.
//
// PDF mode (--out is a file):
//   bcrender.exe --rdl CustomerDetailedAging.rdlc \
//                --data out/dataset.json \
//                --params out/parameters.json \
//                --out render/report.pdf
//
// PNG mode (--out is a directory; writes page-1.png, page-2.png, ...
// directly -- no intermediate PDF, no rasteriser, no dpi mismatch between
// our own render and BC's reference PDF, which is rasterised separately by
// Rasterize-BcPdf.ps1 at the same --dpi):
//   bcrender.exe --rdl CustomerDetailedAging.rdlc \
//                --data out/dataset.json \
//                --params out/parameters.json \
//                --out render/pages --format PNG --dpi 110
using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.IO;
using System.Text;
using System.Web.Script.Serialization;
using Microsoft.Reporting.WebForms;

public static class BcRender
{
    public static int Main(string[] args)
    {
        try
        {
            Dictionary<string, string> opts = ParseArgs(args);
            string rdlPath = Require(opts, "rdl");
            string dataPath = Require(opts, "data");
            string outPath = GetOrDefault(opts, "out", "render/report.pdf");
            string format = GetOrDefault(opts, "format", "PDF"); // PDF | HTML5 | EXCELOPENXML | WORDOPENXML | IMAGE

            JavaScriptSerializer ser = new JavaScriptSerializer();
            ser.MaxJsonLength = int.MaxValue;
            Dictionary<string, object> root =
                (Dictionary<string, object>)ser.DeserializeObject(File.ReadAllText(dataPath));

            // --- Culture -----------------------------------------------------
            // Not a nicety. BC ships dates to the layout as pre-formatted strings
            // ("01/18/23") and the layout calls CDate() on them. Render under
            // sl-SI and that string either throws or parses to a different date
            // than production. Pin the thread culture to the FormatRegion
            // recorded in the dataset.
            string culture = "en-US";
            if (root.ContainsKey("meta"))
            {
                Dictionary<string, object> meta = (Dictionary<string, object>)root["meta"];
                if (meta.ContainsKey("FormatRegion"))
                    culture = Convert.ToString(meta["FormatRegion"]);
            }
            if (opts.ContainsKey("culture")) culture = opts["culture"];
            CultureInfo ci = CultureInfo.GetCultureInfo(culture);
            System.Threading.Thread.CurrentThread.CurrentCulture = ci;
            System.Threading.Thread.CurrentThread.CurrentUICulture = ci;
            Console.WriteLine("culture      : " + ci.Name);

            // --- Build the DataTable BC would have handed the renderer -------
            Dictionary<string, object> types = (Dictionary<string, object>)root["types"];
            object[] columns = (object[])root["columns"];
            DataTable table = new DataTable(Convert.ToString(root["dataSetName"]));
            foreach (object colObj in columns)
            {
                string name = Convert.ToString(colObj);
                string t = types.ContainsKey(name) ? Convert.ToString(types[name]) : "String";
                Type clr;
                switch (t)
                {
                    case "Double": clr = typeof(double); break;
                    case "DateTime": clr = typeof(DateTime); break;
                    case "Int32": clr = typeof(int); break;
                    case "Boolean": clr = typeof(bool); break;
                    default: clr = typeof(string); break;
                }
                table.Columns.Add(name, clr);
            }

            foreach (object rowObj in (object[])root["rows"])
            {
                Dictionary<string, object> rowDict = (Dictionary<string, object>)rowObj;
                DataRow row = table.NewRow();
                foreach (DataColumn c in table.Columns)
                {
                    object v = rowDict.ContainsKey(c.ColumnName) ? rowDict[c.ColumnName] : null;
                    if (v == null)
                    {
                        row[c] = DBNull.Value; // absent column -> null, NOT empty string.
                        continue;               // tablix group filters depend on this.
                    }
                    string s = Convert.ToString(v, CultureInfo.InvariantCulture);
                    if (c.DataType == typeof(double))
                    {
                        double d;
                        row[c] = double.TryParse(s, NumberStyles.Any, CultureInfo.InvariantCulture, out d)
                            ? (object)d : DBNull.Value;
                    }
                    else if (c.DataType == typeof(DateTime))
                    {
                        DateTime dt;
                        row[c] = DateTime.TryParse(s, ci, DateTimeStyles.None, out dt)
                            ? (object)dt : DBNull.Value;
                    }
                    else if (c.DataType == typeof(int))
                    {
                        int i;
                        row[c] = int.TryParse(s, out i) ? (object)i : DBNull.Value;
                    }
                    else if (c.DataType == typeof(bool))
                    {
                        bool b;
                        row[c] = bool.TryParse(s, out b) ? (object)b : DBNull.Value;
                    }
                    else
                    {
                        row[c] = s;
                    }
                }
                table.Rows.Add(row);
            }
            Console.WriteLine("dataset      : " + table.TableName + "  " + table.Rows.Count +
                               " rows x " + table.Columns.Count + " cols");

            // --- Render --------------------------------------------------------
            LocalReport report = new LocalReport();
            using (FileStream fs = File.OpenRead(rdlPath)) report.LoadReportDefinition(fs);
            report.DataSources.Add(new ReportDataSource(table.TableName, table));
            report.EnableHyperlinks = true;
            report.EnableExternalImages = true;

            if (opts.ContainsKey("params") && File.Exists(opts["params"]))
            {
                Dictionary<string, object> pd =
                    (Dictionary<string, object>)ser.DeserializeObject(File.ReadAllText(opts["params"]));
                List<ReportParameter> ps = new List<ReportParameter>();
                foreach (KeyValuePair<string, object> kv in pd)
                    ps.Add(new ReportParameter(kv.Key, Convert.ToString(kv.Value)));
                if (ps.Count > 0) report.SetParameters(ps);
                List<string> names = new List<string>();
                foreach (ReportParameter p in ps) names.Add(p.Name);
                Console.WriteLine("parameters   : " + string.Join(", ", names.ToArray()));
            }

            // Expression compilation happens here. If the layout referenced a
            // custom assembly this is where it would blow up -- BC's stock
            // layouts do not.
            if (string.Equals(format, "PNG", StringComparison.OrdinalIgnoreCase))
            {
                // --out is a directory in this mode: one page-<n>.png per
                // report page, written directly by ReportViewer's own Image
                // renderer -- no PDF, no rasteriser. The CreateStreamCallback
                // overload invokes the callback once per page automatically;
                // no manual StartPage/EndPage loop needed.
                if (!Directory.Exists(outPath)) Directory.CreateDirectory(outPath);
                int dpi = opts.ContainsKey("dpi") ? int.Parse(opts["dpi"], CultureInfo.InvariantCulture) : 110;
                string deviceInfo =
                    "<DeviceInfo><OutputFormat>PNG</OutputFormat><DpiX>" + dpi +
                    "</DpiX><DpiY>" + dpi + "</DpiY></DeviceInfo>";

                int pageCount = 0;
                List<Stream> openStreams = new List<Stream>();
                CreateStreamCallback createStream = delegate (string name, string fileNameExtension,
                    Encoding encoding, string mimeType, bool willSeek)
                {
                    pageCount++;
                    string pagePath = Path.Combine(outPath, "page-" + pageCount + ".png");
                    FileStream fs = File.Create(pagePath);
                    openStreams.Add(fs);
                    return fs;
                };

                // ReportViewer's renderer name for image output is "IMAGE" --
                // "PNG" only appears inside deviceInfo's <OutputFormat>. Our
                // own --format PNG is this program's vocabulary, not theirs.
                Warning[] warnings;
                report.Render("IMAGE", deviceInfo, createStream, out warnings);
                foreach (Stream s in openStreams) s.Close();

                Console.WriteLine("rendered     : " + outPath + "  (" + pageCount + " page(s), PNG @ " + dpi + " dpi)");
            }
            else
            {
                byte[] bytes = report.Render(format);

                string outDir = Path.GetDirectoryName(Path.GetFullPath(outPath));
                if (!string.IsNullOrEmpty(outDir) && !Directory.Exists(outDir)) Directory.CreateDirectory(outDir);
                File.WriteAllBytes(outPath, bytes);
                Console.WriteLine("rendered     : " + outPath + "  (" + bytes.Length.ToString("N0", CultureInfo.InvariantCulture) +
                                   " bytes, " + format + ")");
            }
            return 0;
        }
        catch (Exception ex)
        {
            Exception e = ex;
            int i = 0;
            while (e != null)
            {
                Console.Error.WriteLine("[" + i + "] " + e.GetType().FullName + ": " + e.Message);
                i++;
                e = e.InnerException;
            }
            return 1;
        }
    }

    private static Dictionary<string, string> ParseArgs(string[] a)
    {
        Dictionary<string, string> d = new Dictionary<string, string>();
        for (int i = 0; i < a.Length; i++)
            if (a[i].StartsWith("--") && i + 1 < a.Length) d[a[i].Substring(2)] = a[++i];
        return d;
    }

    private static string Require(Dictionary<string, string> d, string k)
    {
        string v;
        if (d.TryGetValue(k, out v)) return v;
        throw new ArgumentException("--" + k + " is required");
    }

    private static string GetOrDefault(Dictionary<string, string> d, string k, string def)
    {
        string v;
        return d.TryGetValue(k, out v) ? v : def;
    }
}
