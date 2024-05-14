import pandas as pd

# Load the provided Excel file
file_path = 'data.xlsx'

# Read the Excel file to get the sheet names
xls = pd.ExcelFile(file_path)

# Read each sheet into a separate DataFrame
dfs = {sheet_name: pd.read_excel(xls, sheet_name) for sheet_name in xls.sheet_names}

# To verify, let's return the sheet names
sheet_names = xls.sheet_names
sheet_names
