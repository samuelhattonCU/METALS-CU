# Component Design and Prototyping Plan

This document outlines the design of core components and the prototyping strategy for the MATLAB large‑CSV toolkit, leveraging `datastore` and `tall` arrays.

---

## 1. Component Design

### 1.1 Module Overview

| Module           | Purpose                                                   |
| ---------------- | --------------------------------------------------------- |
| `ingestData`     | Stream CSV/TSV files into MATLAB using `datastore`/`tall` |
| `previewData`    | Provide header and data previews (head, sparse)           |
| `filterData`     | Apply row, time, and logical filters on tall/data streams |
| `plotData`       | Generate responsive figures from streamed data            |
| `exportData`     | Save subsets to CSV, MAT, or Parquet                      |
| `headerParser`   | Detect and parse two‑line headers and comments            |
| `downsampleData` | Decimate data for plotting performance                    |
| `configManager`  | Handle user preferences and logging                       |

### 1.2 Function Signatures

```matlab
% Ingest data into a datastore or tall array, with column validation and explicit error handling for malformed or uneven rows
function ds = ingestData(filename, varargin)
% Inputs:
%   filename         - Path to CSV/TSV
%   'Delimiter'      - Character delimiter (e.g. ',')
%   'NumHeaderLines' - Number of header lines (int)
%   'HeaderRows'     - Struct with nameLine/unitLine
%   'ReadSize'       - Number of rows per chunk (int)
%   'SelectedVariableNames' - Cell array of variable names to read
% Outputs:
%   ds               - MATLAB datastore or tall table

% Preview first N rows or sparse scan, with optional index-building or caching to avoid rescanning entire file on repeated previews
function tbl = previewData(ds, varargin)
% Inputs:
%   ds         - Datastore or tall array
%   'Mode'     - 'head' | 'sparse'
%   'N'        - Number of rows or sampling interval
% Outputs:
%   tbl        - MATLAB table with preview rows

% Apply filters: row, time, logical
function dsOut = filterData(ds, varargin)
% Inputs:
%   ds         - Datastore or tall
%   'RowRange' - [start, end]
%   'TimeRange'- [t0, t1]
%   'Predicate'- Function handle for logical filtering
%   'ZeroOffset'- Logical, adjust time to zero offset
% Outputs:
%   dsOut      - Filtered datastore/tall

% Plot streamed data with decimation
function fig = plotData(ds, varargin)
% Inputs:
%   ds             - Datastore or tall
%   'XVar','YVar'  - Variables for axes
%   'Downsample'   - Function handle or factor
%   'Title','Labels' - Plot title and axis labels
% Outputs:
%   fig            - MATLAB figure handle

% Export filtered data
function exportData(ds, filename, varargin)
% Inputs:
%   ds         - Datastore or tall
%   filename   - Output file path
%   'Format'   - 'csv' | 'mat' | 'parquet'
%   'Columns'  - Cell array of column names or indices
% Outputs:
%   (none)     - Writes file to disk

% Parse headers and units
function meta = headerParser(filename, varargin)
% Inputs:
%   filename       - Path to file
%   'NumHeaderLines', 'HeaderRows'
% Outputs:
%   meta           - Struct(names, units, commentLines)

% Decimate data for plotting
function dsDec = downsampleData(ds, factorOrFcn)
% Inputs:
%   ds             - Datastore or tall
%   factorOrFcn    - Decimation factor or function handle
% Outputs:
%   dsDec          - Downsampled datastore/tall

% Manage user preferences and logs
function cfg = configManager(varargin)
% Inputs:
%   'ChunkSize', 'PreviewDepth', 'Verbosity'
% Outputs:
%   cfg            - Struct with current settings
```

### 1.3 Datastore / Tall‑Array Orchestration

* **Core pipeline**:

  ```matlab
  ds = ingestData(...);
  previewData(ds);
  dsF = filterData(ds);
  plotData(dsF);
  exportData(dsF);
  ```
* **Orchestration layer**: Uses `configManager` to set chunk size and verbosity, surfaces errors with clear messages, and lets users explicitly adjust `ChunkSize` rather than automatically retrying with smaller chunks.
