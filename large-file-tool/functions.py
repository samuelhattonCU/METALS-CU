import matplotlib.pyplot as plt
import dask.dataframe as dd
import os

# def csv_to_parquet(csv_path, parquet_path=None, **kwargs):
#     df = dd.read_csv(csv_path, **kwargs)
#     if parquet_path is None:
#         base, _ = os.path.splitext(csv_path)
#         parquet_path = base + ".parquet"
#     # Ensure the parent directory exists
#     parent_dir = os.path.dirname(parquet_path)
#     if parent_dir and not os.path.exists(parent_dir):
#         os.makedirs(parent_dir)
#     df.repartition(npartitions=1).to_parquet(
#         parquet_path,
#         engine="pyarrow",
#         write_index=False,
#         write_metadata_file=False,
#         single_file=True
#     )
#     # df.to_parquet(parquet_path)
#     print(f"Successfully converted to Parquet: {parquet_path}")
#     print(df.head())
#     return parquet_path

# def get_variables_and_units(parquet_path):
#     df = dd.read_parquet(parquet_path)
#     # Compute only the first two rows
#     header_rows = df.head(2)
#     variable_names = list(header_rows.iloc[0])
#     units = list(header_rows.iloc[1])
#     return variable_names, units

# def plot(x_var, y_var, parquet_path):
#     df = dd.read_parquet(parquet_path)
#     # Skip the first two rows (variable names and units)
#     data = df.iloc[2:].compute()
#     # Use the variable names from the first row as column names
#     variable_names, _ = get_variables_and_units(parquet_path)
#     data.columns = variable_names
#     plt.figure()
#     plt.plot(data[x_var], data[y_var])
#     plt.xlabel(x_var)
#     plt.ylabel(y_var)
#     plt.title(f"{y_var} vs {x_var}")
#     plt.show()

def xy_plot(df, x_var, y_var, units=None):
    if x_var not in df.columns or y_var not in df.columns:
        raise ValueError(f"Columns {x_var} and/or {y_var} not found in DataFrame")
    
    plt.figure(figsize=[10,5])
    plt.plot(df[x_var], df[y_var])

    if units is not None:
        x_label = f"{x_var} {units.get(x_var, '')}"
        y_label = f"{y_var} {units.get(y_var, '')}"
    else:
        x_label = x_var
        y_label = y_var

    plt.xlabel(x_label)
    plt.ylabel(y_label)
    plt.title(f"{y_var} vs. {x_var}")
    plt.grid(True)
    plt.tight_layout()
    my_path = os.path.dirname(os.path.abspath(__file__))
    parent_path = os.path.abspath(os.path.join(my_path, os.pardir))
    figures_dir = os.path.join(parent_path, "local/figures")
    # print(figures_dir)
    os.makedirs(figures_dir, exist_ok=True)
    plt.savefig(f"{figures_dir}/{y_var}_vs_{x_var}.png")