# MOPTA Competition Base Model 04/13/2024

############ Initialize Tools ############
begin
    import Pkg;
    # Initialize JuMP to allow mathematical programming models
    # Add Packages if you are running this for the first time
    
    #=
    Pkg.add("JuMP")
    Pkg.add("CSV")
    Pkg.add("DataFrames")
    Pkg.add("Clp")
    Pkg.add("PlotlyJS")
    Pkg.add("Dates")
    Pkg.add("XLSX")
    Pkg.add("FileIO")
    Pkg.add("PrettyTables")
    Pkg.add("Gurobi")
    Pkg.add("PyCall")
    =#
    
    using JuMP
    using CSV
    using DataFrames
    using PlotlyJS
    using Dates
    using XLSX
    using FileIO
    using Base
    using PrettyTables
    # using PyCall
    using Gurobi
    # using Clp
    # using Ipopt
end

############ Program Preparations ############
begin
    # Update automatically the date when this program is run.
    today_date = today()
    
    # Please update information of this program to automatically update the code name.
    code_name = "BaseModel"
    version = "1.0"

    folder_name = "$code_name._V$version._$today_date"

    # Create folder to later save data and plots
    begin
        # Define the path for the new folder
        folder_path = "$folder_name"

        # Use mkpath() to create the folder if it doesn't exist
        mkpath(folder_path)
    end

    # Function to save a plot as a PNG file in the specified folder
    function save_plot(plot, path, filename, format="png")
        # Create the full file path with the specified filename and format
        full_path = joinpath(path, string(filename, ".", format))
        
        # Save the plot as an image in the desired format
        savefig(plot, full_path)
    end
end

############ Load Data ############ 
begin
    # Load generation and load data from local saved location. The dataset has a time resolution of 15 minutes. The dataset is created using the given dataset which 
    # contains 4 representative daily profiles (1 per quarter), and noise is added so that each daily profile is different.

    df = CSV.read("yearly_data.csv", DataFrame)
end

############ Declare Parameters ############
begin
    # Time Horizon Parameters
    begin
        TimeStart = 1;
        TimeEnd = 8760 * 4;
    end
    # Energy Generation Parameters
    begin
        # Solar PV Parameters
        C_PV = 400 # [$/kW] Capital Cost of Solar PV  
        C_PV_OP = 10 # [$/(kW*YR)] Operational and Maintenance Cost of Solar PV
        η_PVIV = 0.96 # [1] PV(DC) to Home(AC) inverter efficiency

        # Wind Parameters
        C_W = 750 # [$/kW] Capital Cost of Wind Generation 
        C_W_OP = 45 # [$/(kW*YR)] Operational and Maintenance Cost of Wind Generation
    end        
    # Electrolyzer Parameters
    begin
        C_EL = 1000 # [$/kW]
        α_EL = 0.7 # electricity to hydrogen
        k_E2H = (1/0.7)/50 # [kwh electricity to kg hydrogen]
    end
    # Fuel Cell Parameters
    begin
        C_FC = 200 # [$/kW]
        α_FC = 0.75 # hydrogen to electricity
        k_H2E = (1/0.75)*33 # [kg hydrogen to kWh electricity]
    end
    # Storage Parameters
    begin
        L_ss = 0.01 # [/hr] short term leakage rate
        L_ls = 0.03/24 # [/hr] long term leakage rate
        β_l2g = 0.75 # liquid to gas efficiency
        β_g2l = 0.9 # gas to liquid efficiency

        C_l2g = 0 # [$/kg] liquid to gas conversion cost
        C_g2l = 2.75 # [$/kg] gas to liquid conversion cost

        C_ss = 0.33 # [$/kg] gas hydrogen
        C_ls = 1.2 # [$/kg] liquid hydrogen storage
        C_C_ss = 1000 # [$/kg] capacity cost of hydrogen gas storage
        C_C_ls = 1400 # [$/kg] capacity cost of hydrogen liquid storage
    end
    # Transmission & Distribution Parameters
    begin
        μ = 0.995 # transportation efficiency
        C_d = 10 # [$/kg] Distribution cost of hydrogen
    end
    # Economic Parameters
    begin
        Lifetime = 20 # [YR] 
        d = 0.03 # [1] Discount Rate
        CRF = (d*(1+d)^Lifetime)/((1+d)^Lifetime-1) # [1] Capital Recovery Factor
    end
    begin
    # Capacity Parameteres
        UB_WindSize = 500
        UB_ESize = Inf
    end
end

function Optimize(stepsize, Input)
    ########## Instructions  ##########
    begin
    end
    ########## Data Preparations  ##########  
    begin
        # Set timesteps 
        TIME = collect(TimeStart:1:TimeEnd); # Collect timesteps into a vector
        NumTime = length(TIME); # Number of timesteps, useful for indexing
        δt = stepsize/60 # [hr] Declare stepzize for the optimization program
    end  
    ########## Declare model  ##########
    begin
        # Define the model name and solver. In this case, model name is "m"
        # m = Model(Clp.Optimizer)
        # m = Model(Ipopt.Optimizer)
        # For Gurobi (note that sometimes Clp and Gurobi give slightly different results)
        begin
            # Set path to license (for those using Gurobi)
            ENV["GRB_LICENSE_FILE"] = "/Users/jimmy/gurobi.lic"
            m = Model(Gurobi.Optimizer)
        end
    end
    ######## Decision variables ########
    begin
        @variable(m, PV2R[1:NumTime] >= 0); # [kW] electrical power transfer from PV to residential load

        @variable(m, PV2I[1:NumTime] >= 0); # [kW] electrical power transfer from PV to industrial load

        @variable(m, W2R[1:NumTime] >= 0); # [kW] electrical power transfer from wind farm to residential load

        @variable(m, W2I[1:NumTime] >= 0); # [kW] electrical power transfer from wind to industrial load

        @variable(m, PV2E[1:NumTime] >= 0); # [kW] electrical power transfer from PV to electrolyzer

        @variable(m, W2E[1:NumTime] >= 0); # [kW] electrical power transfer from wind to electrolyzer

        @variable(m, E2F[1:NumTime] >= 0); # [kg] electrolyzer to fuel cell

        @variable(m, E2SS[1:NumTime] >= 0); # [kg] electrolyzer to short term storage
        
        @variable(m, E2I[1:NumTime] >= 0); # [kg] electrolyzer to industrial gas load

        @variable(m, F2R[1:NumTime] >= 0); # [kW] fuel cell to residential load

        @variable(m, F2I[1:NumTime] >= 0); # [kW] fuel cell to industrial load

        @variable(m, E2LS[1:NumTime] >= 0); # [kg] electrolyzer to long term storage

        @variable(m, SS2F[1:NumTime] >= 0); # [kg] hydrogen gas discharged from short term storage to fuel cell

        @variable(m, SS2I[1:NumTime] >= 0); # [kg] hydrogen gas discharged from short term storage to industrial gas load

        @variable(m, LS2F[1:NumTime] >= 0); # [kg] hydrogen liquid discharged from long term storage to fuel cell

        @variable(m, LS2I[1:NumTime] >= 0); # [kg] hydrogen liquid discharged from long term storage to industrial gas load

        @variable(m, UB_WindSize >= WindSize >= 0); # [kW] Wind Farm Power Capacity

        @variable(m, PVSize >= 0); # [kW] Solar PV Power Capacity

        @variable(m, SSSize >= 0); # [kg] Short Term Storage Energy Capacity

        @variable(m, LSSize >= 0); # [kg] Long Term Storage Energy Capacity

        @variable(m, UB_ESize >= ESize >= 0); # [kW] Electrolyzer Power Capacity (max input before efficiency)

        @variable(m, FSize >= 0); # [kW] Hydrogen Fuel Cell Capacity (max output after efficiency)

        @variable(m, InStorageSS[1:NumTime] >= 0); # [kg] Short term remaining storage

        @variable(m, InStorageLS[1:NumTime] >= 0); # [kg] Long term remaining storage

        @variable(m, PV2G[1:NumTime] >= 0); # [kW] electrical power transfer from PV to curtailment

        @variable(m, W2G[1:NumTime] >= 0); # [kW] electrical power transfer from wind farm to curtailment
    end
    ############ Objective Functions #############
    begin
        # Set single objective for minimizing annual total cost

        # Calculate Capital Cost [$]
        @expression(m, capital_cost, C_PV * PVSize + C_W * WindSize + C_FC * FSize + C_EL * ESize + C_C_ls * LSSize + C_C_ss * SSSize)
        
        # Calculate Yearly Fixed Operational Cost [$/YR]
        @expression(m, fixed_OM_cost, C_PV_OP * PVSize + C_W_OP * WindSize)
        
        # Calculate Yearly Short Run Marginal Cost [$/YR]
        @expression(m, short_run_marginal_cost, sum((InStorageSS[t] * C_ss + InStorageLS[t] * C_ls + LS2I[t] * C_d) for t=1:NumTime))

        # Calculate Conversion Cost [$/YR]
        @expression(m, conversion_cost, sum((E2LS[t] * C_g2l + (LS2F[t] + LS2I[t]) * C_l2g) for t=1:NumTime))

        # Levelized Cost over Lifetime [$/YR]
        @objective(m, Min, capital_cost*CRF + fixed_OM_cost + short_run_marginal_cost + conversion_cost);
    end
    ############# Expressions ############

    ############# Constraints ############
    begin
        # Short term storage initialization constraint
        @constraint(m, InStorageSS[1] == 0.5 * SSSize); # [kg] half full short term storage to start with
        
        @constraint(m, InStorageSS[NumTime] >= 0.5 * SSSize); # [kg] half full short term storage to end with

        # Long term storage initialization constraint
        @constraint(m, InStorageLS[1] == 0); # [kg] half full long term storage to start with
        
        # PV energy balance constraint, node at PV
        @constraint(m, [t=1:NumTime], Input[t, 10] * PVSize * 1000 ==  PV2E[t] + PV2R[t] + PV2I[t] + PV2G[t]); # [kW]

        # Wind energy balance constraint, node at wind farm
        @constraint(m, [t=1:NumTime], Input[t, 9] * WindSize * 1000 ==  W2E[t] + W2R[t] + W2I[t] + W2G[t]); # [kW]
    
        # Electrolyzer energy conservation constraint, node at electrolyzer, electrolyzer efficiency modeled
        @constraint(m, [t=1:NumTime], δt * (W2E[t] + PV2E[t]) * α_EL * k_E2H == E2F[t] + E2SS[t] + E2I[t] + E2LS[t]); # [kWh electricity to kg hydrogen]

        # Fuel Cell energy conservation constraint, node at fuel cell, fuel cell efficiency modeled
        @constraint(m, [t=1:NumTime], E2F[t] + SS2F[t] + LS2F[t] * β_l2g == δt * (F2R[t] + F2I[t])/(α_FC * k_H2E)); # [kg hydrogen to kWh electricity]

        # Short term storage conservation constraint, node at short term storage, leakage modeled
        @constraint(m, [t=1:NumTime-1], InStorageSS[t+1] == (InStorageSS[t] + E2SS[t] - SS2I[t] - SS2F[t]) * (1-L_ss)); # [kg hydrogen]

        # Long term storage conservation constraint, node at long term storage, leakage modeled
        @constraint(m, [t=1:NumTime-1], InStorageLS[t+1] == (InStorageLS[t] + E2LS[t] * β_g2l - LS2F[t] - LS2I[t]) * (1-L_ls)); # [kg hydrogen]

        # Short term storage capacity constraint, node at short term storage
        @constraint(m, [t=1:NumTime], InStorageSS[t] <= SSSize); # [kg hydrogen]

        # Long term storage capacity constraint, node at long term storage
        @constraint(m, [t=1:NumTime], InStorageLS[t] <= LSSize); # [kg hydrogen]

        # Residential electricity demand constraint, node at residential load
        @constraint(m, [t=1:NumTime], sum(Input[t, i] for i = 4:8) * 1000 ==  PV2R[t] + W2R[t] + F2R[t]); # [kW]

        # Industrial electricity demand constraint, node at industrial load
        @constraint(m, [t=1:NumTime], sum(Input[t, i] for i = 2:3) * 1000 ==  PV2I[t] + W2I[t] + F2I[t]); # [kW]

        # Industrial gas demand constraint, node at industrial load
        @constraint(m, [t=1:NumTime], Input[t, 11] == E2I[t] + SS2I[t] + LS2I[t] * β_l2g * μ); # [kg]

        # Electrolyzer power capacity constraint, node at electrolyzer
        @constraint(m, [t=1:NumTime], W2E[t] + PV2E[t] <= ESize); # [kW]

        # Fuel cell power capacity constraint, node at fuel cell
        @constraint(m, [t=1:NumTime], (F2R[t] + F2I[t]) <= FSize); # [kW]
    end
    ########### Solve  ##########
    optimize!(m); 
    ########### Model Results  ##########
    begin
        # Return system sizes and other scalar and time series data

        PV_Size = round(value.(PVSize), digits=2); # [kW]

        Wind_Size = round(value.(WindSize), digits=2); # [kW]

        E_Size = round(value.(ESize), digits=2); # [kW]

        F_Size = round(value.(FSize), digits=2); # [kW]

        SS_Size = round(value.(SSSize), digits=2); # [kg]

        LS_Size = round(value.(LSSize), digits=2); # [kg]
        
        ObjValue = objective_value(m); # [$] Levelized cost of system over lifetime

        InStorageSS_values = [round(value(InStorageSS[t]), digits=2) for t in TIME]
        InStorageLS_values = [round(value(InStorageLS[t]), digits=2) for t in TIME]
    end
    results_dict = Dict(
        "Costs" => ObjValue / 10^6, # Converted to millions USD for readability
        "Capacities" => Dict(
            "PV" => PV_Size,
            "Wind" => Wind_Size,
            "Electrolyzer" => E_Size,
            "Fuel Cell" => F_Size,
            "Short Term Storage" => SS_Size,
            "Long Term Storage" => LS_Size
        ),
        "Flows" => Dict(
            "InStorageSS" => InStorageSS_values,
            "InStorageLS" => InStorageLS_values,
            # Include other variables similarly...
        )
    )

    return results_dict
end


results = Optimize(15, df)

println()
println("Final Results:")
println(results["Capacities"])

in_storage_ss = results["Flows"]["InStorageSS"]
time_steps = collect(TimeStart:1:TimeEnd) 
using Dates
start_datetime = DateTime(2024, 1, 1, 0, 0)  # 2024-Jan-01 at 00:00
num_timesteps = length(time_steps)  # Ensure this matches with your TIME arra
timestamps = [start_datetime + Minute(15*(t-1)) for t in 1:num_timesteps]

using PlotlyJS

function plot_time_series(time, data, title, x_label, y_label)
    trace = scatter(x=time, y=data, mode="lines")
    layout = Layout(
        title=title, 
        xaxis=attr(title=x_label, tickformat="%Y-%m-%d %H:%M"),  # Format the datetime display
        yaxis=attr(title=y_label)
    )
    plot = Plot([trace], layout)
    return plot
end

# Assuming 'in_storage_ss' is already defined
plot_in_storage_ss = plot_time_series(timestamps, in_storage_ss, "InStorageSS Over Time", "Time", "Stored Hydrogen (kg)")

# To display the plot in a Jupyter notebook
display(plot_in_storage_ss)

# To save the plot as an HTML file
PlotlyJS.savefig(plot_in_storage_ss, "InStorageSS_Time_Series.html")
