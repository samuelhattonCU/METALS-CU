# MATLAB Data Import Toolkit

This toolkit provides a suite of MATLAB functions for ingesting, previewing, filtering, decimating, plotting, and exporting data from large CSV and TSV files. It leverages MATLAB's `datastore` and `tall` array functionalities for memory-efficient processing of datasets that may exceed available system memory.

## Directory Structure

The toolkit is organized as follows:

```
/project-root
├── src/                      % Core MATLAB functions
│   ├── headerParser.m        % Parses file headers, comments, and structure
│   ├── ingestData.m          % Ingests data into datastore or tall array
│   ├── previewData.m         % Provides head or sparse previews of data
│   ├── filterData.m          % Filters data by row, time, or predicate
│   ├── downsampleData.m      % Decimates data (stride or custom function)
│   ├── plotData.m            % Generates plots from table/tall array data
│   ├── exportData.m          % Exports data to CSV, MAT, or Parquet
│   ├── runPipeline.m         % Example script demonstrating a full workflow
│   └── configManager.m       % Manages user preferences for the toolkit
├── tests/                    % MATLAB unittest classes and sample data
│   ├── data/                 % Sample CSV/TSV files for testing
│   │   ├── noHeader.csv
│   │   ├── oneLineNames.csv
│   │   ├── twoLineNamesUnits.csv
│   │   ├── commented.csv
│   │   ├── malformed.csv
│   │   ├── empty.csv
│   │   ├── onlyHeaders.csv
│   │   ├── onlyComments.csv
│   │   └── tabDelimited.tsv
│   ├── TestDataImport.m        % Unit tests for headerParser, ingestData, previewData
│   ├── TestFiltering.m         % Unit tests for filterData
│   ├── TestDecimationPlotting.m% Unit tests for downsampleData, plotData
│   └── TestExport.m            % Unit tests for exportData
└── startup.m                 % Adds src/ and tests/ to path, initializes preferences
```


## Core Function Descriptions

### `src/` Directory

* **`headerParser.m`**:
    * Analyzes a text file to detect or use specified delimiters, number of header lines, variable names, units, and comment lines.
    * Returns a metadata struct containing this information, including the determined data start line.
* **`ingestData.m`**:
    * Creates a MATLAB `datastore` or `tall` array from a specified CSV/TSV file.
    * Utilizes `headerParser.m` or user-provided parameters (e.g., `NumHeaderLines`, `Delimiter`) to configure the datastore.
    * Handles selection of variables and missing data representation.
* **`previewData.m`**:
    * Provides a quick look at the data from a datastore or tall array.
    * Supports 'head' mode (first N rows) and 'sparse' mode (every K-th row).
* **`filterData.m`**:
    * Applies various filters to a datastore or tall array.
    * Supports filtering by row range, time range (on a specified time column), or a custom logical predicate function.
    * Can also apply a "zero-offset" to a specified time column.
* **`downsampleData.m`**:
    * Reduces the number of data points in a datastore or tall array.
    * Supports stride-based decimation (taking every K-th row) or a user-provided custom downsampling function.
* **`plotData.m`**:
    * Generates 2D line plots from a MATLAB `table` (data from datastores or tall arrays should be `gather`ed or downsampled to a table first if large).
    * Allows specification of X and Y variables, titles, labels, and legends.
    * Can plot multiple Y variables against a single X variable.
* **`exportData.m`**:
    * Writes data from a `table` (or gathered datastore/tall array) to a file.
    * Supported formats: CSV, MAT-file, and Parquet (if MATLAB Parquet support is installed).
    * Allows selection of specific variables for export.
* **`runPipeline.m`**:
    * An example script demonstrating a complete workflow: ingesting data, previewing, filtering, downsampling, plotting, and exporting.
    * Serves as a template for users to build their own custom processing pipelines.
* **`configManager.m`**:
    * Manages user preferences for the toolkit using MATLAB's `setpref` and `getpref`.
    * Allows setting, getting, and initializing default preferences for options like delimiter, number of header lines, and preview sizes.

### Root Directory

* **`startup.m`**:
    * A script to be run when starting a MATLAB session where this toolkit will be used.
    * Adds the `src/` and `tests/` directories to the MATLAB path.
    * Initializes default toolkit preferences using `configManager('init')`.

## Basic Usage Instructions

1.  **Setup**:
    * Place the entire project directory (e.g., `DataImportToolkit/`) in a location accessible to MATLAB.
    * Open MATLAB.
    * Navigate to the `project-root` directory (e.g., `cd /path/to/DataImportToolkit`).
    * Run the startup script:
        ```matlab
        startup
        ```
        This will add the necessary folders to your MATLAB path and set up default preferences.

2.  **Ingesting Data**:
    Use `ingestData` to load your CSV/TSV file. It will attempt to auto-detect settings or use preferences.
    ```matlab
    filename = 'my_large_data.csv';
    ds = ingestData(filename); % Creates a tall array by default

    % To specify options:
    % ds_custom = ingestData(filename, 'NumHeaderLines', 2, 'Delimiter', '\t', 'OutputType', 'datastore');
    ```

3.  **Previewing Data**:
    ```matlab
    tbl_head = previewData(ds, 'N', 50); % Get first 50 rows
    disp(tbl_head);

    % tbl_sparse = previewData(ds, 'Mode', 'sparse', 'Step', 1000); % Get every 1000th row (can be slow for tall arrays)
    ```

4.  **Filtering Data**:
    ```matlab
    % Filter by row range (rows 1000 to 2000)
    ds_filtered_rows = filterData(ds, 'RowRange', [1000, 2000], 'OutputType', 'tall');

    % Filter by a value in a column (e.g., where 'SignalValue' > 5.0)
    myPredicate = @(T) T.SignalValue > 5.0;
    ds_filtered_predicate = filterData(ds, 'Predicate', myPredicate, 'OutputType', 'tall');

    % Filter by time (assuming a 'Timestamp' column in seconds from start)
    % ds_filtered_time = filterData(ds, 'TimeColumn', 'Timestamp', 'TimeRange', [60, 120], 'OutputType', 'tall');
    ```

5.  **Downsampling Data**:
    ```matlab
    % Decimate by taking every 10th row
    ds_decimated = downsampleData(ds_filtered_predicate, 'Stride', 10, 'OutputType', 'tall');
    ```

6.  **Plotting Data**:
    Data usually needs to be in a regular MATLAB `table` for plotting. If `ds_decimated` is still a `tall` array and reasonably small after decimation, gather it.
    ```matlab
    tbl_for_plot = gather(ds_decimated);
    if height(tbl_for_plot) < 2e6 % Example threshold for plotting directly
        fig = plotData(tbl_for_plot, 'XVar', 'Timestamp', 'YVar', 'SignalValue');
    else
        warning('Data might be too large to plot directly. Consider further decimation.');
    end
    ```

7.  **Exporting Data**:
    ```matlab
    % Export the decimated table to CSV
    exportData(tbl_for_plot, 'output/processed_signal', 'Format', 'csv');

    % Export to MAT file
    % exportData(tbl_for_plot, 'output/processed_signal_data', 'Format', 'mat');
    ```

8.  **Using the Example Pipeline**:
    The `runPipeline.m` script provides a configurable example:
    ```matlab
    inputFile = 'path/to/your/large_file.csv';
    outputBase = 'output/analysis_results'; % Files like output/analysis_results_plot.png will be created
    % runPipeline(inputFile, outputBase, 'NumHeaderLines', 1, 'DownsampleStride', 100, 'PlotYVar', 'SensorA');
    ```

9.  **Managing Preferences**:
    Use `configManager` to view or change default settings:
    ```matlab
    configManager('list'); % View current preferences
    % configManager('set', 'Delimiter', '\t'); % Set default delimiter to tab
    % configManager('init'); % Reset to toolkit defaults
    ```

## Running Tests

The toolkit includes a suite of unit tests to verify functionality.

1.  **Ensure Setup**: Make sure you have run the `startup.m` script from the project root directory in your current MATLAB session. This adds the `src/` and `tests/` directories to the path.

2.  **Navigate to Test Directory (Optional but Recommended)**:
    While not strictly necessary if paths are set, it's good practice:
    ```matlab
    cd tests
    ```
    Or, if you are in the project root:
    ```matlab
    % No need to cd if tests/ is on the path via startup.m
    ```

3.  **Run All Tests**:
    To run all test classes located in the `tests/` directory (or any directory containing test classes that `runtests` can discover):
    ```matlab
    results = runtests('tests'); % Specify the 'tests' folder
    % OR, if 'tests' is the current folder or already on path and discoverable:
    % results = runtests;
    disp(results);
    ```

4.  **Run a Specific Test Class**:
    For example, to run only the tests in `TestDataImport.m`:
    ```matlab
    results_import = runtests('TestDataImport');
    disp(results_import);
    ```

5.  **Run a Specific Test Method within a Class**:
    For example, to run only the `testHeaderParserNoHeader` method in the `TestDataImport` class:
    ```matlab
    results_method = runtests('TestDataImport/testHeaderParserNoHeader');
    disp(results_method);
    ```

6.  **Using the Test Browser**:
    MATLAB's Test Browser provides a GUI for running tests.
    * Go to the "Editor" or "Live Editor" tab.
    * In the "Test" section, click "Run Tests" or open the "Test Browser".
    * You can select specific tests or classes to run from the browser.

The test results will indicate how many tests passed, failed, or were incomplete (e.g., due to skipped tests like the Parquet export if the necessary add-on isn't installed).
