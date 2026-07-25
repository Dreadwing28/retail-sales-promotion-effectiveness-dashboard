import os
import pandas as pd


def main():
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    raw_dir = os.path.join(project_root, "data", "raw")

    print("Project root:", project_root)
    print("Raw dir:", raw_dir)
    print("Files in raw:", os.listdir(raw_dir))

    # update this filename if needed
    raw_file = "retail_store_sales_promotions_demand.csv"

    file_path = os.path.join(raw_dir, raw_file)
    print("Loading:", file_path)

    df = pd.read_csv(file_path)

    print("\nShape:", df.shape)
    print("\nColumns:", df.columns.tolist())

    print("\nHead:")
    print(df.head().to_string())

    print("\nInfo:")
    print(df.info())

    print("\nMissing values per column:")
    print(df.isna().sum())

    print("\nDescribe (numeric):")
    print(df.describe())


if __name__ == "__main__":
    main()