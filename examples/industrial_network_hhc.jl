################################################################################
# HarmonicPowerModels.jl                                                       #
# Extension package of PowerModels.jl for Steady-State Power System            #
# Optimization with Power Harmonics.                                           #
# See http://github.com/timmyfaraday/HarmonicPowerModels.jl                    #
################################################################################
# Authors: Tom Van Acker, Hakan Ergun                                          #
################################################################################
# Changelog:                                                                   #
################################################################################

# using pkgs
using HarmonicPowerModels, PowerModels
using Hypatia
using Ipopt 

# pkg cte
const PMs = PowerModels
const HPM = HarmonicPowerModels

# set the solver
solver_soc = Hypatia.Optimizer
solver_nlp = Ipopt.Optimizer

# read-in data 
path = joinpath(HPM.BASE_DIR,"test/data/matpower/industrial_network_hhc.m")
data = PMs.parse_file(path)

# define the set of considered harmonics
H = [1, 3, 5, 7, 9, 13]

# solve HHC problem -- NLP
hdata_nlp = HPM.replicate(data, H=H)
results_hhc_nlp = HPM.solve_hhc(hdata_nlp, dHHC_NLP, solver_nlp)

# solve HHC problem -- SOC 
hdata_soc = HPM.replicate(data, H=H)
results_hhc_soc = HPM.solve_hhc(hdata_soc, dHHC_SOC, solver_soc, solver_nlp)

# validate results
print("======== Validating results ==================")
# Objective NLP vs SOC
print("Objective NLP: ", results_hhc_nlp["objective"], " Objective SOC: ", results_hhc_soc["objective"], " Gap: ", (1 - results_hhc_soc["objective"] / results_hhc_nlp["objective"])*100, "%", "\n")
# Nodal voltages NLP vs SOC
print("======== Nodal voltages ==================")
for (n, nw) in results_hhc_soc["solution"]["nw"]
    print("Harmonic Order ,",n, ":","\n")
    if n ≠ "1"
        for (b, bus) in results_hhc_nlp["solution"]["nw"][n]["bus"]
            vmsoc = results_hhc_soc["solution"]["nw"][n]["bus"][b]["vm"]
            print("Bus ", b,": vm nlp = ", round(bus["vm"], digits = 6), ", vm soc = ", round(vmsoc, digits = 6), ", diff = ", round(bus["vm"] - vmsoc, digits = 6),"\n")
        end
    end 
end
# Check delta transformer currents
H0 = ["3" "9"]
print("======== Transformer currents for 3x Harmonics ==================", "\n")
for h in H0
    print("Harmonic Order ", h, "\n")
    for (x, xfmr) in results_hhc_nlp["solution"]["nw"][h]["xfmr"]
        print("Type: ", hdata_nlp["nw"][h]["xfmr"][x]["vg"], ", Total current from side: ", round(xfmr["crt_fr"] + xfmr["cit_fr"]im, digits = 6), ", Total current to side: ", round(xfmr["crt_to"] + xfmr["cit_to"]im, digits = 6), "\n")
    end
end

# Recalculate currents through voltage differences and compare:
print("======== Compare calculated currents with results ==================", "\n")
for h in H
    print("Harmonic Order ", h, "\n")
    print("Branch currents: ", "\n")
    for (b, rbranch) in results_hhc_nlp["solution"]["nw"]["$h"]["branch"]
        branch = hdata_nlp["nw"]["$h"]["branch"][b]
        fbus = branch["f_bus"]
        tbus = branch["t_bus"] 
        vr_fr = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$fbus"]["vr"]
        vi_fr = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$fbus"]["vi"]
        vr_to = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$tbus"]["vr"]
        vi_to = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$tbus"]["vi"]

        v_fr = (vr_fr + (vi_fr)im)
        v_to = (vr_to + (vi_to)im)

        csh_fr = v_fr * (branch["g_fr"] + branch["b_fr"]im)
        csh_to = v_to * (branch["g_to"] + branch["b_to"]im)
        cs_fr = (v_fr - v_to) / (branch["br_r"] + (branch["br_x"])im)
        cs_to = (v_to - v_fr) / (branch["br_r"] + (branch["br_x"])im)
        c_fr = cs_fr + csh_fr 
        c_to = cs_to + csh_to 

        print("Branch ", b, ", Series current from side calculated: ", round(cs_fr, digits = 6), "\n")
        print("Branch ", b, ", Series current from side results: ", round(rbranch["csr_fr"] + rbranch["csi_fr"]im, digits = 6), "\n")
        print("Branch ", b, ", Total current  from side calculated: ", round(c_fr, digits = 6), ", Total current to side calculated: ", round(c_to, digits = 6), "\n")
        print("Branch ", b, ", Total current  from side results: ", round(rbranch["cr_fr"] + rbranch["ci_fr"]im, digits = 6), ",    Total current to side results: ", round(rbranch["cr_to"] + rbranch["ci_to"]im, digits = 6),"\n")
    end

    print("Transformer quantities: ", "\n")
    for (x, rxfmr) in results_hhc_nlp["solution"]["nw"]["$h"]["xfmr"]
        xfmr = hdata_nlp["nw"]["$h"]["xfmr"][x]
        fbus = xfmr["f_bus"]
        tbus = xfmr["t_bus"] 
        vr_fr = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$fbus"]["vr"]
        vi_fr = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$fbus"]["vi"]
        vr_to = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$tbus"]["vr"]
        vi_to = results_hhc_nlp["solution"]["nw"]["$h"]["bus"]["$tbus"]["vi"]

        v_fr = (vr_fr + (vi_fr)im)
        v_to = (vr_to + (vi_to)im)

        er = (vr_to * xfmr["tr"] + vi_to * xfmr["ti"]) / (xfmr["tr"]^2 + xfmr["ti"]^2) # @HAKAN: this is not correct, should be the internal xfmr voltage
        ei = (vi_to * xfmr["tr"] - vr_to * xfmr["ti"]) / (xfmr["tr"]^2 + xfmr["ti"]^2) 
        e = (er + (ei)im) 

        print("XFMR ", x, ", Excitation voltage calculated: ", round(e, digits = 6), "\n")
        print("XFMR ", x, ", Excitation voltage results: ", round(rxfmr["ert"] + (rxfmr["eit"])im, digits = 6), "\n")

        csh = e / xfmr["rsh"]
        cst = (v_fr - e) / (xfmr["r1"]+ xfmr["r2"] + xfmr["xsc"]im)
        ct = cst + csh

        vt = v_fr - cst * (xfmr["r1"]+ xfmr["r2"])

        print("XFMR ", x, ", Internal voltage calculated: ", round(vt, digits = 6), "\n")
        print("XFMR ", x, ", Internal voltage results: ", round(rxfmr["vrt_fr"] + (rxfmr["vit_fr"])im, digits = 6), "\n")

        print("XFMR ", x, ", Total current calculated: ", round(ct, digits = 6), "\n")
        print("XFMR ", x, ", Total current results: ", round(rxfmr["crt_fr"] + (rxfmr["cit_fr"])im, digits = 6), "\n")

        print("XFMR ", x, ", Series current calculated: ", round(cst, digits = 6), "\n")
        print("XFMR ", x, ", Series current results: ", round(rxfmr["csrt_fr"] + (rxfmr["csit_fr"])im, digits = 6), "\n")
    end
end