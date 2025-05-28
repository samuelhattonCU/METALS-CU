# Software Requirements Document (MATLAB Edition)

**Version:** 1.0
**Date:** May 22, 2025

## 1. Overview

A **stand‑alone**, MATLAB‑based toolkit (distributed as a MATLAB toolbox or collection of scripts/functions) for previewing, slicing, plotting, and exporting very large CSV files (≥ 20 GB) without exhausting system memory. Leverages built‑in MathWorks toolboxes (e.g. MATLAB Data Import and Analysis, Parallel Computing Toolbox) and tall‑array/datastore functionality.

---

## 2. Functional Requirements

1. **Packaging & Deployment**

   * Delivered as a directory of `.m` and (optionally) `.mlapp` files.
   * Users add the directory to the MATLAB path using `addpath`.
   * No external language/runtime dependencies.

2. **Data Ingestion & Parsing**

   * Use **datastore** or **tall** arrays to stream CSV/TSV in chunks.
   * Auto-detect and skip non-data header lines; parse two-line headers (names + units) and ignore comments.
   * When header structure is ambiguous, allow user to specify number of header lines and which rows contain variable names and units.
   * Support configurable preview of headers via `preview` argument.

3. **Preview Modes**

   * **Head preview:** read first N rows (default N=200), return as MATLAB `table`.
   * **Sparse scan:** sample every kᵗʰ row (user-defined) to compute summary statistics or distributions.

4. **Column Selection & Metadata**

   * Functions to list detected variables and units from the datastore or table.
   * Programmatic inclusion/exclusion via name or index; optional aliasing through function inputs.

5. **Row Filtering & Time Normalization**

   * Apply row-index filters (e.g. rows 1,000–2,000) using `tall` row selection or `datastore` filters.
   * Logical filtering expressions using `rowfun` or custom predicate functions.
   * Time-range filtering on numeric time column (milliseconds).
   * “Zero-offset” utility to subtract the first (or user-specified) timestamp.

6. **Chunked Processing & Robustness**

   * Default chunk size driven by MAT-file cache size or fixed block size (\~200 MB equivalent).
   * Automatic fallback to smaller block sizes on memory errors.
   * Progress reporting via text progress bar or `waitbar`, with cancel option.
   * Verbosity levels (`INFO`/`DEBUG`) controlled by function parameter or global preference.

7. **Plotting**

   * Core plotting function(s) that accept tall arrays or streamed data sources.
   * Generate basic MATLAB figures: XY plots with axis limits, labels, title, and legend.
   * Recommend data decimation (downsampling) to maintain figure performance (e.g. via `reducepatch` or `resample`).
   * Support overlaying multiple series in one figure.
   * Export figures using `exportgraphics` or `saveas` to PNG, PDF, or MATLAB `.fig`.

8. **Data Export**

   * Write filtered or subset data to:

     * **CSV** via `writetable` with options for selected columns and row-interval export (every kᵗʰ row).
     * **MAT-file** via `save` for rapid reload.
     * (Optional) **Parquet** using MATLAB’s Parquet functions if installed.

9. **User Preferences & Logging**

   * Store preferences (chunk size, preview depth, verbosity) using `setpref`/`getpref` or a JSON config file.
   * Log operations and errors to a text file via `diary` or custom logger utility.

10. **Extensibility**

    * Modular design: core APIs in separate functions (`ingestData.m`, `previewData.m`, `filterData.m`, `plotData.m`, `exportData.m`).
    * Hook points for custom parsers or post-processing callbacks.

