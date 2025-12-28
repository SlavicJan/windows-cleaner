# What got unified in this pack

- Canonical runnable set is under RUN/
- Legacy/source zips are kept under SOURCES/ for traceability / rollback
- v2/v3/v4 variants kept because they contain different CLI semantics (e.g. --outdir placement),
  and older bugs (SwitchParameter NoUI, invalid escape warnings) that were fixed in later versions.

If you only want ONE set: use RUN/ only. Everything else is archival.
