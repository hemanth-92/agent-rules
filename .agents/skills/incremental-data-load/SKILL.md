---
name: incremental-data-load
description: Design maintainable incremental data pipelines by choosing an extraction pattern, a load strategy, and a backfill strategy. Use when asked to build or review incremental ingestion, pick between overwrite-partition, merge/upsert, and append-only loads, add watermark or CDC-style extraction, make a pipeline idempotent and re-runnable, or plan a bootstrap or backfill of historical data.
---

# incremental-data-load

An incremental pipeline is defined by three decisions: how rows are extracted
from the source, how they are written to the destination, and how history is
reprocessed. Decide all three explicitly; most incremental pipeline defects come
from an unstated choice, not from the transform logic.

## Workflow

1. **Choose the extraction pattern** from what the source can tell you about
   change. Prefer the highest option the source supports.

   - **`updated_at` available** (preferred; captures inserts and updates):

     ```sql
     Select * From source
     Where updated_at >= :start_ts And updated_at < :end_ts;
     ```

     Confirm the source sets `updated_at = inserted_at` on row creation.
     Without that, new rows are silently skipped.

   - **`inserted_at` only** (append-only sources, fact-shaped data; updates to
     existing rows are not captured):

     ```sql
     Select * From source
     Where inserted_at >= :start_ts And inserted_at < :end_ts;
     ```

   - **No timestamp; diff against the destination.** Use a single primary key
     when one exists, and fall back to a hash of the columns that form the
     natural key only when it does not:

     ```sql
     -- primary key comparison
     Select s.* From source As s
     Left Join destination As d On s.pk = d.pk
     Where d.pk Is Null;

     -- hashed composite key
     Select s.* From source As s
     Left Join destination As d
       On md5(s.col_a || s.col_b) = md5(d.col_a || d.col_b)
     Where d.col_a Is Null;
     ```

     This scans both sides and is the expensive option. It also couples
     extraction to the destination, which constrains backfills (step 3). Typical
     for API pulls and third-party dumps.

   - Use half-open time intervals (`>= start`, `< end`) so adjacent runs neither
     duplicate nor drop boundary rows.

2. **Choose the load strategy** from the destination data model.

   - **Overwrite partitions** - destination partitioned by event time; each run
     replaces whole partitions (Spark `overwritePartitions`, or `DELETE` plus
     `INSERT` per partition). Idempotent, re-runnable without cleanup, and
     absorbs late-arriving data by rerunning the affected partitions. This is
     the default choice. Use for fact tables and snapshot dimensions. Cost:
     a partitioning scheme and repartition work on every run.
   - **Row-based merge/upsert** - `MERGE INTO`, `INSERT ... ON CONFLICT`, or
     `DELETE` plus `INSERT` keyed by identifier. Use for SCD2 dimensions and
     transactional tables needing point updates or deletes. Cost: not
     re-runnable without a cleanup step, and more logic to get right.
   - **Append-only** - write every row, dedupe downstream. Use for bronze/raw
     landing zones and streaming ingestion where duplicates are acceptable.
     Cost: storage growth and a mandatory downstream dedupe.

3. **Decide the backfill strategy before shipping, not after a failure.**

   First check whether the pipeline can be rerun at all. Manual destination
   cleanup is required before a backfill if either is true:

   - Extraction reads the destination - for example
     `Where inserted_at > (Select max(inserted_at) From destination)`, or the
     diff-based patterns in step 1.
   - The load step uses `UPDATE` or `DELETE`.

   Then scale the backfill:

   - **Single process** - reprocess the whole historical range in one run. Use
     when compute allows; simplest.
   - **Serial runs** - run one interval at a time in chronological order.
     Required when runs are not independent. Check the arithmetic first: a
     12-hour daily pipeline backfilled over 2 years takes about a year of
     wall-clock time, so the pipeline never catches up.
   - **Parallel runs** - run independent intervals concurrently. Fastest, but
     only valid when no run reads the destination and no logic looks back
     across intervals.

4. **Bootstrap, then switch to incremental.** Load full history once, record the
   watermark that load reached, and run incrementally from there. Store the
   watermark in the orchestrator or a control table, not in the pipeline code.

5. **Handle deletes and late arrivals deliberately.** Source deletes are
   invisible to timestamp extraction unless the source soft-deletes and bumps
   `updated_at`. Options: soft-delete flags carried through as updates, SCD2
   end-dating, or a periodic full-key reconciliation. Late-arriving rows are
   free under partition overwrite (rerun the partition) and require explicit
   handling under append-only.

6. **Plan for schema drift.** Additive changes - new columns, widening types
   such as int to long - are safe with table-format schema evolution. Changing
   a column's meaning or narrowing a type is breaking: it needs manual
   intervention and usually reprocessing.

## Decision chart

```
Extraction
  source has updated_at?      -> filter on updated_at   (inserts + updates)
  source has inserted_at only -> filter on inserted_at  (inserts only)
  neither                     -> diff vs destination    (pk, else key hash)

Load
  fact / snapshot dimension   -> overwrite partition    (idempotent)
  SCD2 / transactional        -> merge / upsert         (needs cleanup to rerun)
  bronze, duplicates fine     -> append                 (dedupe downstream)

Backfill
  compute is sufficient       -> single process
  runs not independent        -> serial (check catch-up time)
  runs independent            -> parallel
```

## Diagnostics

```sql
-- gaps, duplicates, and partial reruns across partitions
Select event_date, count(*), count(Distinct pk)
From destination
Group By event_date Order By event_date;

-- watermark lag: how far behind the destination is
Select max(updated_at) From destination;

-- duplicate keys, which append-only loads accumulate
Select pk, count(*) From destination Group By pk Having count(*) > 1;
```

Idempotency check: run the pipeline for one interval, snapshot the destination,
run the same interval again, and diff. Any difference means the load strategy is
not re-runnable as written.

## Validation

- Extraction interval is half-open; no row is dropped or double-counted at
  interval boundaries.
- `updated_at` is populated on insert when the `updated_at` pattern is used.
- Rerunning one interval leaves the destination unchanged, or the required
  cleanup step is documented for merge and append loads.
- Backfill strategy matches run independence; parallel backfill is used only
  when extraction and load are destination-independent.
- Bootstrap load and watermark handoff are documented and reproducible.
- Delete semantics and late-arriving-data behavior are stated, not assumed.
