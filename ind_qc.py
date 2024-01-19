import pyspark
import dxpy # tools starting with 'dx' are from the DNANexus ecosystem
import dxdata
import pandas as pd
from pyspark.sql.functions import when, concat_ws
from re import sub
import os

def access_dataset():
    sc = pyspark.SparkContext()
    spark = pyspark.sql.SparkSession(sc)
    # Dispense dataset
    #dispensed_database = dxpy.find_one_data_object(
    #    classname="database", 
    #    name="app*", 
    #    folder="/", 
    #    name_mode="glob", 
    #    describe=True)

    dispensed_dataset = dxpy.find_one_data_object(
        typename="Dataset", 
        name="app*.dataset", 
        folder="/", 
        name_mode="glob")
    dispensed_dataset_id = dispensed_dataset["id"]

    # Load Dataset
    dataset = dxdata.load_dataset(id=dispensed_dataset_id)
    return dataset

def retrieve_field(dataset, field_list_aliases):
    participant = dataset["participant"]
    field_list = list(field_list_aliases.keys())
    # retrieve participant data
    participant_data = participant.retrieve_fields(names=field_list, engine=dxdata.connect(), coding_values="replace", column_aliases=field_list_aliases)
    # pull it to pandas
    df = participant_data.toPandas()
    return df

def filter_on_traits(df, criterion):
    df_qced = df
    for key, values in criterion.items():
        # record the number of individuals in the dataset

        # split conditions by &
        values = values.split("&")
        for value in values:
            n_start = df_qced.shape[0]
            if value == "isna":
                df_qced = df_qced[df_qced[key].isna()]
            elif value == "notna":
                df_qced = df_qced[df_qced[key].notna()]
            elif "!" in value:
                print(value)
                df_qced = df_qced[df_qced[key] != value.replace("!", "")]
            elif "col:" in value:
                df_qced = df_qced[df_qced[key] == df_qced[value.replace("col:", "")]]
            else:
                df_qced = df_qced[df_qced[key] == value]
            n_end = df_qced.shape[0]
            print("Number of individuals dropped due to " + key + ": " + str(n_start - n_end))
    return df_qced

def filter_on_bulk(df, fam_file):
    # expect file to be in plink.fam format
    # expect df to have a column IID
    if ("IID" not in df.columns):
        raise Exception("df does not have a column IID")
    plink_fam = pd.read_csv(fam_file, delimiter = '\s', names = ['FID', 'IID', 'FatherID', 'MotherID', 'sex', 'pheno'], dtype = "object", engine = 'python')
    # retain only rows with bulk data available
    start_n = df.shape[0]
    df_bulk = df.join(plink_fam.set_index("IID"), on = "IID", rsuffix = "_fam", how = "inner")
    end_n = df_bulk.shape[0]
    print("Number of individuals dropped due to bulk data: " + str(start_n - end_n))
    return df_bulk

if __name__ == "__main__":
    # Load Dataset
    dataset = access_dataset()

    # retrieve participant data
    field_list_aliases = {
        "eid" : "IID",
        "p31" : "sex",
        "p34" : "year_birth",
        "p90012": "overall_activity",
        "p22001": "genetic_sex",
        "p22006": "is_white_british",
        "p22019": "sex_chrom_aneuploidy",
        "p22021": "kinship",
    }
    df = retrieve_field(dataset, field_list_aliases)

    # filter on traits
    gwas_trait_criterion = {
        "sex": "col:genetic_sex",
        "is_white_british": "Caucasian",
        "sex_chrom_aneuploidy": "isna",
        "kinship": "notna&!Participant excluded from kinship inference process&!Ten or more third-degree relatives identified",
        "overall_activity": "notna"
    }
    pca_trait_criterion = {
        "sex": "col:genetic_sex",
        "is_white_british": "Caucasian",
        "sex_chrom_aneuploidy": "isna",
        "kinship": "No kinship found",
        "overall_activity": "notna"
    }
    df_qced = filter_on_traits(df, gwas_trait_criterion)
    df_pca_qced = filter_on_traits(df, pca_trait_criterion)

    exom_file = "/mnt/project/Bulk/Exome sequences/Population level exome OQFE variants, PLINK format - final release/ukb23158_c10_b0_v1.fam"
    df_qced_exom = filter_on_bulk(df_qced, exom_file)
    df_pca_qced_exom = filter_on_bulk(df_pca_qced, exom_file)

    # output the IID list of individuals into files
    df_qced_exom[["IID"]].to_csv("eid_gwas_qced_exom.iid", index = False, header = False)
    df_pca_qced_exom[["IID"]].to_csv("eid_pca_qced_exom.iid", index = False, header = False)