import functions as f
import pandas as pd
import dask.dataframe as dd
import matplotlib.pyplot as plt





units = pd.read_csv('sample_data.csv', nrows=1).iloc[0].to_dict()
print(units)

df1 = dd.read_csv('sample_data.csv', skiprows=[1], assume_missing=True)
df2 = dd.read_csv('fake_data.csv', skiprows=[1], assume_missing=True)

print(df1.head())
print(df2.head())

# df3 = dd.concat([df1, df2]).set_index('Time').compute().sort_index()
df3 = dd.concat([df1, df2]).compute()
df3 = df3.sort_values('Time')

print(df3.head())

f.xy_plot(df3, 'Time', 'Force', units)


