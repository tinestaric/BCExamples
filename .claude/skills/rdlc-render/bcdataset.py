#!/usr/bin/env python3
"""
Flatten a Business Central report dataset (SaveAsXml / "Send to > XML Document")
into the flat DataSet_Result table that an RDLC layout expects.

Rules derived empirically against BC 28.2 output and verified against BC's own
"Report data in Excel" export:

  1. Walk <DataItems> depth-first in document order.
  2. Emit one row per LEAF DataItem node. Parent nodes do not get their own row.
  3. Each row carries its own <Column> values plus every ancestor's columns,
     carried forward. Columns belonging to unrelated branches are null.
  4. For any column carrying a formatter attribute (decimalformatter /
     dateformatter), synthesise a companion column "<name>Format" holding the
     format string. BC's generated layouts bind these to the textbox
     Style/Format property, e.g.
        <Format>=Fields!Cust_Ledger_Entry_Remaining_Amount_Format.Value</Format>
     They are absent from the Excel export but required by the RDL.
  5. <Labels> supply the values for the RDL's <ReportParameters>.

Usage:
    python3 bcdataset.py dataset.xml layout.rdlc -o out/
      -> out/dataset.csv        flat DataSet_Result
      -> out/parameters.json    report parameter name/value pairs
"""

import argparse
import csv
import json
import os
import sys
import xml.etree.ElementTree as ET

RDL_NS = "{http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition}"
FORMATTER_ATTRS = ("decimalformatter", "dateformatter", "timeformatter", "datetimeformatter")


def rdl_fields(rdl_path):
    """Field names the layout declares, in declaration order, plus the dataset name."""
    root = ET.parse(rdl_path).getroot()
    for ds in root.iter(RDL_NS + "DataSet"):
        fields = [f.get("Name") for f in ds.iter(RDL_NS + "Field")]
        return ds.get("Name"), fields
    raise SystemExit("no DataSet found in layout")


def rdl_parameters(rdl_path):
    root = ET.parse(rdl_path).getroot()
    out = []
    for p in root.iter(RDL_NS + "ReportParameter"):
        default = None
        dv = p.find(RDL_NS + "DefaultValue")
        if dv is not None:
            vals = [v.text for v in dv.iter(RDL_NS + "Value")]
            default = vals[0] if vals else None
        out.append({"name": p.get("Name"),
                    "type": p.findtext(RDL_NS + "DataType") or "String",
                    "default": default})
    return out


def flatten(xml_path):
    """Return (rows, ordered_column_names, labels)."""
    root = ET.parse(xml_path).getroot()

    labels = {}
    labels_el = root.find("Labels")
    if labels_el is not None:
        for lab in labels_el.findall("Label"):
            labels[lab.get("name")] = lab.text or ""

    order = []
    seen = set()
    rows = []

    def note(name):
        if name not in seen:
            seen.add(name)
            order.append(name)

    def columns_of(node):
        out = {}
        cols = node.find("Columns")
        if cols is None:
            return out
        for col in cols.findall("Column"):
            name = col.get("name")
            out[name] = col.text if col.text is not None else ""
            note(name)
            for attr in FORMATTER_ATTRS:
                if col.get(attr):
                    fname = name + "Format"
                    out[fname] = col.get(attr)
                    note(fname)
        return out

    def walk(container, inherited):
        for node in container.findall("DataItem"):
            merged = dict(inherited)
            merged.update(columns_of(node))
            kids = node.find("DataItems")
            # A leaf is "no DataItem children", not "no <DataItems> tag" --
            # BC sometimes emits an empty <DataItems/> container on a node
            # that has no nested repeating group data for this particular
            # run (e.g. a ledger entry with no applied entries). Treating
            # that as "has children" silently drops the row entirely.
            if kids is None or not kids.findall("DataItem"):
                rows.append(merged)          # leaf -> one row
            else:
                walk(kids, merged)           # parent -> carry down only

    top = root.find("DataItems")
    if top is None:
        raise SystemExit("no <DataItems> in dataset xml")
    walk(top, {})
    return rows, order, labels


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("xml")
    ap.add_argument("rdl", nargs="?")
    ap.add_argument("-o", "--outdir", default=".")
    args = ap.parse_args()

    rows, discovered, labels = flatten(args.xml)
    os.makedirs(args.outdir, exist_ok=True)

    if args.rdl:
        dataset_name, columns = rdl_fields(args.rdl)
        missing = [c for c in columns if c not in discovered]
        extra = [c for c in discovered if c not in columns]
        print(f"dataset name in layout : {dataset_name}")
        print(f"layout declares        : {len(columns)} fields")
        print(f"dataset supplies       : {len(discovered)} columns")
        if missing:
            print(f"MISSING (layout wants, dataset lacks): {missing}")
        if extra:
            print(f"unused (dataset has, layout ignores) : {extra}")
        params = rdl_parameters(args.rdl)
        for p in params:
            p["value"] = labels.get(p["name"], p["default"] or "")
            src = "Labels" if p["name"] in labels else "RDL default"
            print(f"parameter {p['name']} = {p['value']!r}  (from {src})")
        with open(os.path.join(args.outdir, "parameters.json"), "w") as fh:
            json.dump({p["name"]: p["value"] for p in params}, fh, indent=2)
    else:
        columns = discovered

    # JSON is the machine-readable artefact: it preserves the distinction between
    # "column absent on this row" (null -> DBNull) and "column present but blank"
    # (""). That distinction is load-bearing: this layout filters a tablix group on
    # =Fields!TempCurrencyTotalBuffer_Total_Amount_.Value, and BC emits genuinely
    # empty currency codes elsewhere. Collapse them and the totals rows move.
    # Column typing. BC hands the renderer typed columns, and it matters:
    # this layout does Sum(Fields!Cust_Ledger_Entry_Remaining_Amt_LCY_.Value),
    # which silently concatenates instead of adding if the column arrives as text.
    # decimalformatter is the reliable signal for "this is a decimal".
    numeric = {c[:-len("Format")] for c in columns if c.endswith("Format")}

    # Booleans carry no formatter attribute at all -- the XML gives no typed
    # signal, unlike decimals. BC always serialises them as the literal
    # strings "True"/"False" though, so a column whose every observed
    # (present, non-blank) value is one of those two is a boolean in
    # disguise. Layouts commonly gate visibility with
    # =IIF(Fields!SomeFlag.Value, ...), which throws if that arrives as the
    # text "False" instead of an actual Boolean.
    boolean = set()
    for c in columns:
        if c in numeric:
            continue
        observed = {r[c] for r in rows if r.get(c) not in (None, "")}
        if observed and observed <= {"True", "False"}:
            boolean.add(c)

    types = {c: ("Double" if c in numeric else "Boolean" if c in boolean else "String")
             for c in columns}

    root = ET.parse(args.xml).getroot()
    req = root.find("./BCReportInformation/ReportRequest")
    meta = {k: (req.findtext(k) or "") for k in
            ("CompanyName", "UserName", "Language", "FormatRegion", "DateAndTime")} if req is not None else {}

    json_path = os.path.join(args.outdir, "dataset.json")
    with open(json_path, "w", encoding="utf-8") as fh:
        json.dump({"dataSetName": dataset_name if args.rdl else "DataSet_Result",
                   "meta": meta,
                   "columns": columns,
                   "types": types,
                   "rows": [{c: r.get(c, None) for c in columns} for r in rows]},
                  fh, indent=1)

    # CSV is for eyeballing and for diffing against BC's own Excel export,
    # which writes the literal string NULL for absent columns.
    csv_path = os.path.join(args.outdir, "dataset.csv")
    with open(csv_path, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=columns, extrasaction="ignore")
        w.writeheader()
        for r in rows:
            w.writerow({c: ("NULL" if c not in r else r[c]) for c in columns})
    print(f"wrote {len(rows)} rows x {len(columns)} cols -> {json_path}, {csv_path}")


if __name__ == "__main__":
    main()
