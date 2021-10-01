using Pkg
Pkg.activate("./")
# load pkgs
using Ipopt, HarmonicPowerModels, PowerModels
using JuMP #avoids problems with Revise

# pkg const
const _PMs = PowerModels
const _HPM = HarmonicPowerModels

# path to the data
path = joinpath(_HPM.BASE_DIR,"test/data/matpower/case_basf_simplified.m")
# path = joinpath(_HPM.BASE_DIR,"test/data/matpower/case_basf.m")

# transformer excitation data
exc_1 = Dict("voltage_harmonics" => [1,3],
            "current_harmonics" => [1,3],
            "N" => 50,
            "current_type" => :rectangular,
            "excitation_type" => :sigmoid,
            "inom" => 0.4,
            "ψmax" => 0.5,
            "voltage_type" => :rectangular,
            "dv" => [0.1,0.1],
            "vmin" => [-1.1,-1.1],
            "vmax" => [1.1,1.1],
            "dθ" => [π/5,π/5],
            "θmin" => [0.0,0.0],
            "θmax" => [2π,2π])

exc_2 = Dict("voltage_harmonics" => [1,3],
            "current_harmonics" => [1,3],
            "N" => 50,
            "current_type" => :rectangular,
            "excitation_type" => :sigmoid,
            "inom" => 0.4,
            "ψmax" => 0.5,
            "voltage_type" => :rectangular,
            "dv" => [0.1,0.1],
            "vmin" => [-1.1,-1.1],
            "vmax" => [1.1,1.1],
            "dθ" => [π/5,π/5],
            "θmin" => [0.0,0.0],
            "θmax" => [2π,2π])

xfmr_exc = Dict("1" => exc_1, "2" => exc_2)

# load data
data  = _PMs.parse_file(path)

vmmin = 0.8
for (b,branch) in data["branch"]
    branch["c_rating"] = branch["rate_a"]/vmmin
end
for (d,load) in data["load"]
    load["c_rating"] = abs(load["pd"] + im* load["qd"])/vmmin
end
for (g,gen) in data["gen"]
    gen["c_rating"] = abs(gen["pmax"] + im* gen["qmax"])/vmmin
end

hdata = _HPM.replicate(data, xfmr_exc=exc_1)
# hdata = _HPM.replicate(data)

# set the solver
solver = Ipopt.Optimizer


#solve power flow
resultpf = run_hpf_iv(hdata, _PMs.IVRPowerModel, solver)
@assert resultpf["termination_status"] == LOCALLY_SOLVED
_HPM.append_indicators!(resultpf, hdata)

println("Harmonic 5")
_PMs.print_summary(resultpf["solution"]["nw"]["3"])
println("Harmonic 3")
_PMs.print_summary(resultpf["solution"]["nw"]["2"])
println("Harmonic 1")
_PMs.print_summary(resultpf["solution"]["nw"]["1"])


##
# solve the hopf
# result = run_hopf_iv(hdata, _PMs.IVRPowerModel, solver)
pm = _PMs.instantiate_model(hdata, _PMs.IVRPowerModel, _HPM.build_hopf_iv; ref_extensions=[_HPM.ref_add_xfmr!]);
result = optimize_model!(pm, optimizer=solver, solution_processors=[ _HPM.sol_data_model!])
@assert result["termination_status"] == LOCALLY_SOLVED
_HPM.append_indicators!(result, hdata)


pg = result["solution"]["nw"]["1"]["gen"]["1"]["pg"]


println("Harmonic 5")
_PMs.print_summary(result["solution"]["nw"]["3"])
println("Harmonic 3")
_PMs.print_summary(result["solution"]["nw"]["2"])
println("Harmonic 1")
_PMs.print_summary(result["solution"]["nw"]["1"])
result["objective"]
result["termination_status"]

##
# original cost 65.01954705548785