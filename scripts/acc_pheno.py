import pandas as pd
import os

actinet_file = '/well/doherty/projects/shared/shing/ukb/actinet/2025-03-18/16-15-46/outputs.csv.gz'
stepcount_file = '/well/doherty/projects/shared/shing/ukb/stepcount/2025-03-18/16-18-06/Info.csv.gz'

actinet_cols = ['Filename', 'acc-overall-avg', 'moderate-vigorous-overall-avg', 'sedentary-overall-avg', 'WearTime(days)', 'CalibOK']
actinet_df = pd.read_csv(actinet_file, usecols=actinet_cols)


stepcount_cols = ['Filename', 'StepsDayAvgAdjusted', 'Cadence95thAdjusted(steps/min)', 'WearTime(days)', 'CalibOK']
stepcount_df = pd.read_csv(stepcount_file, usecols=stepcount_cols)

# exclude rows where CalibOK is False and WearTime(days) > 3
stepcount_df = stepcount_df[stepcount_df['CalibOK'] == True]
stepcount_df = stepcount_df[stepcount_df['WearTime(days)'] > 3]

# exclude rows where CalibOK is False and WearTime(days) > 3
actinet_df = actinet_df[actinet_df['CalibOK'] == True]
actinet_df = actinet_df[actinet_df['WearTime(days)'] > 3]

# extract pid from filename
actinet_df['pid'] = [os.path.basename(x).split('_')[0] for x in actinet_df['Filename']]
stepcount_df['pid'] = [os.path.basename(x).split('_')[0] for x in stepcount_df['Filename']]

# sanity check, there should be no duplication in pid
assert len(actinet_df['pid'].unique()) == len(actinet_df)
assert len(stepcount_df['pid'].unique()) == len(stepcount_df)

# check for missing values
actinet_missing = actinet_df[actinet_df.isnull().any(axis=1)]
stepcount_missing = stepcount_df[stepcount_df.isnull().any(axis=1)]
# message the number of missing values
print(f"Number of missing values in actinet: {len(actinet_missing)}")
print(f"Number of missing values in stepcount: {len(stepcount_missing)}")

# drop missing values
actinet_df_clean = actinet_df.dropna()
stepcount_df_clean = stepcount_df.dropna()

# get pids that are unique to actinet
actinet_pids = actinet_df_clean['pid'].unique()
stepcount_pids = stepcount_df_clean['pid'].unique()

# set differences
actinet_only_pids = set(actinet_pids) - set(stepcount_pids)
stepcount_only_pids = set(stepcount_pids) - set(actinet_pids)

# message the number of unique pids
print(f"Number of unique pids in actinet: {len(actinet_only_pids)}")
print(f"Number of unique pids in stepcount: {len(stepcount_only_pids)}")

# merge actinet and stepcount dataframes
merged_df = pd.merge(actinet_df, stepcount_df, on='pid', how='outer')

# write the merged dataframe to a csv
cols = ['pid', 'pid', 'acc-overall-avg', 'moderate-vigorous-overall-avg', 'sedentary-overall-avg', 'StepsDayAvgAdjusted', 'Cadence95thAdjusted(steps/min)']
pheno_df = merged_df[cols]
# rename the columns
pheno_df.columns = ['FID', 'IID', 'acc-overall-avg', 'moderate-vigorous-overall-avg', 'sedentary-overall-avg', 'StepsDayAvgAdjusted', 'Cadence95thAdjustedStepsPerMin']

# write the dataframe to a csv, separate by space, missing values should be NA
pheno_df.to_csv('/users/doherty/imh310/ukb_rap/ukb_exome/data/pheno_actinet_stepcount.csv', index=False, na_rep='NA', sep=' ')
