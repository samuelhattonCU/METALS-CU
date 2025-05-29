import functions as f
# import pandas as pd
import dask.dataframe as dd
import matplotlib.pyplot as plt

### Test code using really short files:

# units = pd.read_csv('./large-file-tool/sample_data.csv', nrows=1).iloc[0].to_dict()
# print(units)

# df1 = dd.read_csv('./large-file-tool/sample_data.csv', skiprows=[1], assume_missing=True)
# df2 = dd.read_csv('./large-file-tool/fake_data.csv', skiprows=[1], assume_missing=True)

# print(df1.head())
# print(df2.head())

# # df3 = dd.concat([df1, df2]).set_index('Time').compute().sort_index()
# df3 = dd.concat([df1, df2]).compute()
# df3 = df3.sort_values('Time')

# print(df3.head())

# f.xy_plot(df3, 'Time', 'Force', units)

### Try it with a smallish set of MTS data (a few gbs):

# units = pd.read_csv('./local/sample MTS data/high.csv', nrows=1).iloc[0].to_dict()
# print(units)

# df_low = dd.read_csv('./local/sample MTS data/low.csv', skiprows=[1], assume_missing=True)
# df_high = dd.read_csv('./local/sample MTS data/high.csv', skiprows=[1], assume_missing=True)


# units = pd.read_parquet('./local/sample MTS data//high.parquet').iloc[0].to_dict()
df_low = dd.read_parquet('./local/sample MTS data/low.parquet')
df_high = dd.read_parquet('./local/sample MTS data/high.parquet')

print(df_low.head())
print(df_high.head())

df_comb = dd.concat([df_low, df_high]).compute()
df_comb = df_comb.sort_values('RunningTime')

print(df_comb.head())

f.xy_plot(df=df_comb, x_var='RunningTime', y_var='AxialDisplacement')
