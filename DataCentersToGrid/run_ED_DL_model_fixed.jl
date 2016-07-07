# Julia script
# - solve economid dispatch model for fixed dispatchable load solutions
# Kibaek Kim - ANL/MCS 01112015

using CPLEX,JuMP;

SEASON      = ARGS[1];
penetration = float(ARGS[2]);
scenario    = parse(Int,ARGS[3]);
numDispatchables = 20; #parse(Int,ARGS[4]);
DLoadShedPenalty = 0;

nScenarios = 1000;

# scale penetration level to account for the additional data center load
original_penetration = penetration;
penetration = penetration * (655+96) / 655;

include("ZC_data.jl");

penetration = original_penetration;

# read dispatchable load solution
InstallDispatchableValues = readdlm("/home/kibaekkim/ZCCloudResults/DispatchableLoads/$SEASON-$penetration-$numDispatchables-$DLoadShedPenalty-Solution.csv");
InstallDispatchable = Dict{AbstractString,Float64}();
for i = 1:length(BUSES)
	setindex!(InstallDispatchable, InstallDispatchableValues[i], BUSES[i]);
end

include("ED_DL_model_fixed.jl");

status = solve(m);

if status == :Optimal

    # File name
    filename = "/home/kibaekkim/ZCCloudResults/FixedDispatchables/$SEASON-$penetration-$numDispatchables-$DLoadShedPenalty-$scenario";

    # Save Objective Value
    fp = open("$filename-Objval.csv", "w");
    print(fp, getObjectiveValue(m));
    close(fp);

    # Save Gen0 and Gen
    fp = open("$filename-Gen.csv", "w");
    for i in GENERATORS
        print(fp, getValue(Gen0[i]));
        for t in PERIODS
            print(fp, ",", getValue(Gen[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);
    
    # Save LoadShed
    fp = open("$filename-Loadshed.txt", "w");
    for i in LOADS
        print(fp, getValue(LoadShed[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getValue(LoadShed[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);
   
    # Save ImportCurtailment
    fp = open("$filename-ImportCurtailment.txt", "w");
    for i in IMPORTS
        print(fp, getValue(ImportCurtailment[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getValue(ImportCurtailment[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);

    # Save RenewableCurtailment
    fp = open("$filename-RenewableCurtailment.txt", "w");
    for i in REGENERATORS
        print(fp, getValue(RenewableCurtailment[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getValue(RenewableCurtailment[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);

    # Save WindCurtailment
    fp = open("$filename-WindCurtailment.txt", "w");
    for i in WINDS
        print(fp, getValue(WindCurtailment[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getValue(WindCurtailment[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);

    # Save DLoad
    fp = open("$filename-DLoad.txt", "w");
    for i in BUSES
        print(fp, getValue(DLoad[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getValue(DLoad[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);

    # Save LMP
    fp = open("$filename-LMP.txt", "w");
    for i in BUSES
        print(fp, getDual(POWER_BALANCE[i,1]));
        for t in 2:nPeriods
            print(fp, ",", getDual(POWER_BALANCE[i,t]));
        end
        print(fp, "\n");
    end
    close(fp);
end
