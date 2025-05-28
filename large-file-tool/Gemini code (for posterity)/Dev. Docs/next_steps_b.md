### 3. Data Model & Metadata Handling

**3.1 Internal Metadata Representation (`headerParser` output)**

We will standardize the metadata returned by `headerParser` as a MATLAB struct with these fields:

* **variableNames**: `1×N` cell array of `char`, the column names (empty if none).
* **variableUnits**: `1×N` cell array of `char`, the units corresponding to each column (empty if none).
* **commentLines**: cell array of `char` containing any full-line comments (prefixed by `%`, `#`, etc.) that appeared before the data.
* **rawHeaderLines**: cell array of the original header lines (up to `NumHeaderLines`), for logging or reparse.
* **numHeaderLines**: integer, how many lines were treated as header.
* **delimiter**: `char` or string, the character used to split columns (`,` or `\t`).
* **dataStartLine**: integer, the 1-based index of the first data row.

This struct allows downstream modules (`ingestData`, `previewData`, `filterData`) to reference both semantic metadata and raw context without reparsing the file.

**3.2 Configuration & User Preferences**

We will rely exclusively on MATLAB's native preferences mechanism, using `setpref('DataImport', ...)` and `getpref('DataImport', ...)` for all configuration needs:

* `Delimiter` (default `','`)
* `NumHeaderLines` (default `0`)

### 4. Prototyping Sequence

We will implement and validate each core capability in phases:

* **Phase 1**: *Ingest & Preview*

  ```matlab
  function ds = ingestData(filename)
  %INGESTDATA Create a tall datastore for large CSV files
      % Retrieve delimiter preference
      delim = getpref('DataImport','Delimiter',',');
      % Create datastore without reading variable names
      ds0 = datastore(filename, ...
          'TreatAsMissing','NA', ...
          'Delimiter',delim, ...
          'ReadVariableNames',false);
      % Convert to tall for large-scale processing
      ds = tall(ds0);
  end
  ```

  ```matlab
  function tbl = previewData(ds, varargin)
  %PREVIEWDATA Return first N rows from tall datastore
      p = inputParser;
      addParameter(p,'Head',100,@(x)isnumeric(x)&&isscalar(x));
      parse(p,varargin{:});
      N = p.Results.Head;
      tbl = gather(head(ds,N));
  end
  ```

  * **Exercise header parsing** on sample files with 0–2 header lines and comments:

    ```matlab
    setpref('DataImport','NumHeaderLines',2);
    ds = ingestData('sample_with_headers.csv');
    tbl = previewData(ds,'Head',50);
    disp(tbl);
    ```

* **Phase 2**: *Filtering Capabilities*

  ```matlab
  function tbl = filterData(ds, varargin)
  %FILTERDATA Apply row, time, or function-handle filters to a tall datastore
      p = inputParser;
      addParameter(p,'RowRange',[],@(x)isnumeric(x) && numel(x)==2);
      addParameter(p,'TimeRange',[],@(x)isdatetime(x) && numel(x)==2);
      addParameter(p,'Predicate',[],@(x)isa(x,'function_handle'));
      parse(p, varargin{:});
      args = p.Results;

      % Start from the original datastore
      tds = ds;

      % Apply function-handle predicate first (tall logical indexing)
      if ~isempty(args.Predicate)
          tds = tds(args.Predicate(tds), :);
      end

      % Apply time-range filter (tall logical indexing)
      if ~isempty(args.TimeRange)
          tds = tds(tds.Time >= args.TimeRange(1) & tds.Time <= args.TimeRange(2), :);
      end

      % For row-range, gather and slice
      if ~isempty(args.RowRange)
          fullTbl = gather(tds);
          tbl = fullTbl(args.RowRange(1):args.RowRange(2), :);
      else
          tbl = gather(tds);
      end
  end
  ```

  * **Test snippets:**

    ```matlab
    % Filter rows 101–200
    tbl1 = filterData(ds, 'RowRange', [101 200]);

    % Filter by time window
    t0 = datetime(2020,1,1);
    t1 = datetime(2020,1,31);
    tbl2 = filterData(ds, 'TimeRange', [t0 t1]);

    % Filter using custom predicate
    tbl3 = filterData(ds, 'Predicate', @(T) T.Signal > 5);
    ```

* **Phase 3**: *Decimation & Plotting*

  ```matlab
  function dsDec = downsampleData(ds, varargin)
  %DOWNSAMPLEDATA Decimate a tall datastore by stride or custom function
      p = inputParser;
      addParameter(p,'Stride',10,@(x)isnumeric(x)&&isscalar(x)&&x>=1);
      addParameter(p,'Func',[],@(x)isa(x,'function_handle'));
      parse(p,varargin{:});
      args = p.Results;
      if ~isempty(args.Func)
          dsDec = args.Func(ds);
      else
          % Simple stride decimation: take every kth row
          % Note: convert to tall index expression
          dsDec = ds(1:args.Stride:end, :);
      end
  end
  ```

  ```matlab
  function h = plotData(tbl, varargin)
  %PLOTDATA Generate a plot from a gathered table
      p = inputParser;
      addParameter(p,'XVar','Time',@ischar);
      addParameter(p,'YVar','Signal',@ischar);
      parse(p,varargin{:});
      x = tbl.(p.Results.XVar);
      y = tbl.(p.Results.YVar);
      h = figure;
      plot(x, y);
      xlabel(p.Results.XVar);
      ylabel(p.Results.YVar);
      title('Decimated Signal vs. Time');
  end
  ```

  * **Test snippet:**

    ```matlab
    % Decimate by factor of 10 and plot
    dsDec = downsampleData(ds, 'Stride', 10);
    tblDec = gather(dsDec);
    h1 = plotData(tblDec, 'XVar', 'Time', 'YVar', 'Signal');
    ```

* **Phase 4**: *Export & Wrap‑up*

  ```matlab
  function exportData(tbl, filename, format)
  %EXPORTDATA Write table to specified format: 'csv', 'mat', or 'parquet'
      arguments
          tbl table
          filename char {mustBeNonempty}
          format char {mustBeMember(format, {'csv','mat','parquet'})}
      end
      switch format
          case 'csv'
              writetable(tbl, [filename '.csv']);
          case 'mat'
              data = tbl; %#ok<NASGU>
              save([filename '.mat'], 'data');
          case 'parquet'
              % Requires MATLAB Hadoop support or Parquet add-on
              try
                  parquetwrite([filename '.parquet'], tbl);
              catch ME
                  warning('Parquet export failed: %s', ME.message);
              end
      end
  end
  ```

  ```matlab
  % Full pipeline example
  function runPipeline(inputFile, outputBase)
  %RUNPIPELINE Complete data import-to-export workflow
      % Phase 1: ingest & preview
      ds = ingestData(inputFile);
      tblHead = previewData(ds, 'Head', 100);
      disp('Preview of data:'); disp(tblHead);

      % Phase 2: apply filters (example: none)
      tblFilt = filterData(ds);

      % Phase 3: downsample & plot
      dsDec = downsampleData(ds, 'Stride', 10);
      tblDec = gather(dsDec);
      plotData(tblDec, 'XVar', 'Time', 'YVar', 'Signal');

      % Phase 4: export results
      exportData(tblDec, [outputBase '_decimated'], 'csv');
      exportData(tblDec, [outputBase '_decimated'], 'mat');
  end
  ```

### 5. Testing & Validation Strategy

To ensure correctness and robustness, we will define MATLAB `unittest.TestCase` classes under `tests/`, leveraging our synthetic CSV assets.

* **Framework**: MATLAB `unittest.TestCase` classes, named for each module under test.

* **Test Assets**: in `tests/data/`, include:

  * `noHeader.csv` (plain data, no header lines)
  * `oneLineNames.csv` (single header row of names)
  * `twoLineNamesUnits.csv` (names + units)
  * `malformed.csv` (uneven rows, missing entries)
  * `commented.csv` (comment lines before data)

* **Coverage Goals**:

  * *headerParser*: correct parsing of `variableNames`, `variableUnits`, `commentLines`, `delimiter`, `numHeaderLines` for all cases.
  * *ingestData*/`previewData`: ability to ingest and preview without errors, honoring `Delimiter` and `NumHeaderLines` prefs.
  * *filterData*: filtering by row range, time window, and predicate yields expected table sizes/values.
  * *downsampleData*/*plotData*: decimation stride correctness and figure handle output.
  * *exportData*: generated files exist and contain expected contents in each format.

**Example Test Class (tests/TestDataImport.m)**

```matlab
classdef TestDataImport < matlab.unittest.TestCase
    properties
        PrefsBackup
    end
    methods (TestMethodSetup)
        function savePrefs(testCase)
            % Preserve existing prefs
            testCase.PrefsBackup = getpref('DataImport');
        end
        function createAssets(testCase)
            % Ensure test files exist in tests/data/
        end
    end
    methods (TestMethodTeardown)
        function restorePrefs(testCase)
            % Restore original prefs
            if ~isempty(testCase.PrefsBackup)
                setpref('DataImport', fieldnames(testCase.PrefsBackup), struct2cell(testCase.PrefsBackup));
            end
        end
    end
    methods (Test)
        function testHeaderParserNoHeader(testCase)
            hdr = headerParser('tests/data/noHeader.csv');
            testCase.assertEmpty(hdr.variableNames);
            testCase.verifyEqual(hdr.numHeaderLines, 0);
        end
        function testHeaderParserOneLine(testCase)
            setpref('DataImport','NumHeaderLines',1);
            hdr = headerParser('tests/data/oneLineNames.csv');
            testCase.verifyEqual(hdr.variableNames, {'ColA','ColB','ColC'});
            testCase.verifyEqual(hdr.numHeaderLines,1);
        end
        function testIngestPreview(testCase)
            ds = ingestData('tests/data/noHeader.csv');
            tbl = previewData(ds,'Head',10);
            testCase.verifySize(tbl, [10, size(tbl,2)]);
        end
        function testFilterRowRange(testCase)
            ds = ingestData('tests/data/noHeader.csv');
            tbl = filterData(ds,'RowRange',[5,15]);
            testCase.verifyEqual(height(tbl), 11);
        end
    end
end
```

Additional classes (`TestFiltering.m`, `TestDecimationPlotting.m`, `TestExport.m`) will follow the same pattern, focusing on module-specific assertions. Continuous integration can run via `runtests('tests')` in `startup.m`.

### 6. Performance Benchmarking

* **Metrics**:

  * *Load Time*: time to create a tall datastore on a 20 GB CSV.
  * *Preview Time*: time to fetch first 200 rows.
  * *Plot Time*: time to downsample and render a 10 M‑point series.
* **Targets** (on 16 GB RAM machine):

  * Load < 10 s
  * Preview < 1 s
  * Plot (10 M → 100 k points) < 5 s

Scripts will automate benchmarks and log results to CSV for tracking over time.



### 7. Project Setup & Orchestration

```
/project-root
├── src/            % .m files for each core module
├── tests/          % MATLAB unittest classes and sample data
├── data/           % small & large sample CSVs for testing
├── docs/           % README, design docs, API reference
├── config.json     % project‑level prefs
└── startup.m       % adds /src to path and initializes prefs
```

* Include a `README.md` with build/test instructions:

  ```bash
  addpath('src');
  run_tests;
  benchmark_performance;
  ```



### 8. Review Checkpoints

At the end of each phase (see Section 4), we will:

1. **Demo** the functionality on a representative dataset.
2. **Compare** behavior against requirements.
3. **Collect** your feedback and adjust before proceeding.

---

*Next:* Please review this detailed plan for steps 3–8, and let me know if you’d like edits or if you’d like me to begin Phase 1 implementation.

