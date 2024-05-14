
---

# Energy Grid Network Flow Optimization

## Introduction

This project integrates renewable energy sources, namely wind and solar power, into the energy grid to meet decarbonization targets. Green hydrogen is proposed as a stable energy carrier to support baseload power and decarbonize heavy industry. The system comprises wind turbines, solar PV panels, electrolyzers, and fuel cells, and includes cities, industrial districts, and electricity and gas load nodes. The optimization process determines the optimal injection of electricity into the grid to meet demand, considering both gas and electricity simultaneously to demonstrate the capacity requirements for each component of the integrated energy system.

## Parameter Setup

| Category | Parameter | Value |
|----------|-----------|-------|
| **Time Horizon Parameters** | TimeStart | 1 |
|  | TimeEnd | 365 * 24 * 4 |
| **Energy Generation Parameters** | Solar PV | C_{PV} | 400 [\$ / kW] Capital Cost of Solar PV |
|  | C_{PV-OP} | 10 [\$ / (kW*YR)] Operational and Maintenance Cost of Solar PV |
|  | \eta_{PVIV} | 0.96 PV(DC) to Home(AC) inverter efficiency |
| Wind | C_{W} | 750 [\$ / kW] Capital Cost of Wind Generation |
|  | C_{W-OP} | 45 [\$ / (kW*YR)] Operational and Maintenance Cost of Wind Generation |
| **Electrolyzer Parameters** | Electrolyzer | C_{EL} | 1000 [\$ / kW] Capital Cost of Electrolyzer |
|  | \alpha_{EL} | 0.7 Efficiency of Electricity to Hydrogen |
|  | k_{E2H} | (1/0.7) / 50 [kWh electricity to kg hydrogen] |
| **Fuel Cell Parameters** | Fuel Cell | C_{FC} | 200 * 10^-1 [\$ / kW] Capital Cost of Fuel Cell |
|  | \alpha_{FC} | 0.75 Efficiency of Hydrogen to Electricity |
|  | k_{H2E} | (1/0.75) * 33 [kg hydrogen to kWh electricity] |
| **Storage Parameters** | Storage | L_{ss} | 0.01 [/hr] Short Term Storage Leakage Rate |
|  | L_{ls} | 0.03 / 24 [/hr] Long Term Storage Leakage Rate |
|  | \beta_{l2g} | 0.75 Hydrogen Liquid to Gas Conversion Efficiency |
|  | \beta_{g2l} | 0.9 Hydrogen Gas to Liquid Conversion Efficiency |
|  | C_{l2g} | 0 [\$ / kg] Operational Cost of Hydrogen Liquid to Gas Conversion |
|  | C_{g2l} | 2.75 * 10^-1 [\$ / kg] Operational Cost of Hydrogen Gas to Liquid Conversion |
|  | C_{ss} | 0.33 [\$ / kg] Operational Cost of Short Term Storage |
|  | C_{ls} | 1.2 * 10^-1 [\$ / kg] Operational Cost of Long Term Storage |
|  | C_{C-ss} | 1000 [\$ / kg] Capital Cost of Short Term Storage |
|  | C_{C-ls} | 1400 [\$ / kg] Capital Cost of Long Term Storage |
| **Transmission & Distribution Parameters** | Transmission | \mu | 0.995 Hydrogen Transportation Efficiency |
|  | C_{d} | 10 * 10^-1 [\$ / kg] Distribution Cost of Hydrogen |
| **Economic Parameters** | Economic | Lifetime | 20 [YR] |
|  | d | 0.03 Discount Rate |
|  | CRF | \frac{d(1+d)^{Lifetime}}{(1+d)^{Lifetime}-1} Capital Recovery Factor |
| **Capacity Parameters** | Capacity | UB_{WindSize} | \infty |
|  | UB_{ESize} | \infty |

These parameters can be tuned within the provided Jupyter notebook (`finalopt.ipynb`).

## Requirements

- **Julia**: Make sure Julia is installed on your system. You can download it from [here](https://julialang.org/downloads/).
- **Packages**: The following Julia packages are required:
  - CSV
  - DataFrames
  - JuMP
  - Gurobi
- **Gurobi License**: A valid Gurobi license is required to run the optimization. You can obtain a free academic license [here](https://www.gurobi.com/academia/academic-program-and-licenses/).
- **Input Directory**: Ensure you have a directory containing the historical data in CSV format. Example CSV files for the year 2001-2020 are provided.

## Input Format

The input files should be yearly CSV profiles. Each CSV file should include the following columns:
- `DateTime`: Timestamp of the data point.
- `Wind`: Wind energy profile.
- `Solar`: Solar energy profile.
- `ElectricityHome`: Electricity demand at home.
- `ElectricityIndustry`: Electricity demand at industry.
- `GasIndustry`: Hydrogen gas demand at industry.

An example row in the CSV might look like this:
```
DateTime,Wind,Solar,ElectricityHome,ElectricityIndustry,GasIndustry
2004-01-01 00:00:00,1.2,0.8,1.5,2.0,1.0
```

## Usage

1. **Clone the Repository**: 
   ```
   git clone https://github.com/JimmyJiang666/MOPTA2024
   cd MOPTA2024
   ```

2. **Install Required Packages**:
   Open Julia REPL and run:
   ```julia
   using Pkg
   Pkg.add("CSV")
   Pkg.add("DataFrames")
   Pkg.add("JuMP")
   Pkg.add("Gurobi")
   ```

3. **Set Up Gurobi**:
   Follow the instructions [here](https://www.gurobi.com/documentation/) to set up Gurobi and ensure your license is properly configured.

4. **Prepare Input Data**:
   Place your yearly CSV profiles in the input directory. Ensure the files follow the required format.

5. **Run the Notebook**:
   Open the Jupyter notebook `finalopt.ipynb` and run all cells. The notebook will read the input data, perform the optimization, and output the results.

## Example

Example CSV profiles are provided (`data_yearly`). These files contain hourly data for wind, solar, and energy demands.

## Output

The notebook will output the optimized capacity requirements for each component of the integrated energy system, as well as the optimal operational network flow.

---
