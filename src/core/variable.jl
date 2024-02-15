################################################################################
# HarmonicPowerModels.jl                                                       #
# Extension package of PowerModels.jl for Steady-State Power System            #
# Optimization with Power Harmonics.                                           #
# See http://github.com/timmyfaraday/HarmonicPowerModels.jl                    #
################################################################################
# Authors: Tom Van Acker, Frederik Geth, Hakan Ergun                           #
################################################################################
# Changelog:                                                                   #
################################################################################

# bus
""
function variable_bus_voltage_real(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    vr = _PMs.var(pm, nw)[:vr] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_vr",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "vr_start", 1.0)
    )

    if bounded
        for (i, bus) in _PMs.ref(pm, nw, :bus)
            JuMP.set_lower_bound(vr[i], -bus["vmax"])
            JuMP.set_upper_bound(vr[i],  bus["vmax"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :bus, :vr, _PMs.ids(pm, nw, :bus), vr)
end

""
function variable_bus_voltage_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    vi = _PMs.var(pm, nw)[:vi] = JuMP.@variable(pm.model,
        [i in _PMs.ids(pm, nw, :bus)], base_name="$(nw)_vi",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :bus, i), "vi_start")
    )

    if bounded
        for (i, bus) in _PMs.ref(pm, nw, :bus)
            JuMP.set_lower_bound(vi[i], -bus["vmax"])
            JuMP.set_upper_bound(vi[i],  bus["vmax"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :bus, :vi, _PMs.ids(pm, nw, :bus), vi)
end

# branch
""
function variable_branch_current_real(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    cr = _PMs.var(pm, nw)[:cr] = JuMP.@variable(pm.model,
        [(l,i,j) in _PMs.ref(pm, nw, :arcs)], base_name="$(nw)_cr",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "cr_start")
    )

    if bounded
        for (l,i,j) in _PMs.ref(pm, nw, :arcs)
            branch = _PMs.ref(pm, nw, :branch, l)
            JuMP.set_lower_bound(cr[(l,i,j)], -branch["c_rating"])
            JuMP.set_upper_bound(cr[(l,i,j)],  branch["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :branch, :cr_fr, :cr_to, _PMs.ref(pm, nw, :arcs_from), _PMs.ref(pm, nw, :arcs_to), cr)
end
""
function variable_branch_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    ci = _PMs.var(pm, nw)[:ci] = JuMP.@variable(pm.model,
        [(l,i,j) in _PMs.ref(pm, nw, :arcs)], base_name="$(nw)_ci",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "ci_start")
    )

    if bounded
        for (l,i,j) in _PMs.ref(pm, nw, :arcs)
            branch = _PMs.ref(pm, nw, :branch, l)
            JuMP.set_lower_bound(ci[(l,i,j)], -branch["c_rating"])
            JuMP.set_upper_bound(ci[(l,i,j)],  branch["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :branch, :ci_fr, :ci_to, _PMs.ref(pm, nw, :arcs_from), _PMs.ref(pm, nw, :arcs_to), ci)
end
""
function variable_branch_series_current_real(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    csr = _PMs.var(pm, nw)[:csr] = JuMP.@variable(pm.model,
        [l in _PMs.ids(pm, nw, :branch)], base_name="$(nw)_csr",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "csr_start", 0.0)
    )

    if bounded
        for (b, branch) in _PMs.ref(pm, nw, :branch)
            JuMP.set_lower_bound(csr[b], -branch["c_rating"])
            JuMP.set_upper_bound(csr[b],  branch["c_rating"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :branch, :csr_fr, _PMs.ids(pm, nw, :branch), csr)
end
""
function variable_branch_series_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=nw_id_default, bounded::Bool=true, report::Bool=true)
    csi = _PMs.var(pm, nw)[:csi] = JuMP.@variable(pm.model,
        [l in _PMs.ids(pm, nw, :branch)], base_name="$(nw)_csi",
        start=_PMs.comp_start_value(_PMs.ref(pm, nw, :branch, l), "csi_start", 0.0)
    )

    if bounded
        for (b, branch) in _PMs.ref(pm, nw, :branch)
            JuMP.set_lower_bound(csi[b], -branch["c_rating"])
            JuMP.set_upper_bound(csi[b],  branch["c_rating"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :branch, :csi_fr, _PMs.ids(pm, nw, :branch), csi)
end

# filter
""
function variable_filter_current_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    crf = _PMs.var(pm, nw)[:crf] = JuMP.@variable(pm.model,
            [f in _PMs.ids(pm, nw, :filter)], base_name="$(nw)_crf",
            start=_PMs.comp_start_value(_PMs.ref(pm, nw, :filter, f), "crf_start", 0.0)
    )
    
    if bounded
        for (f, filter) in _PMs.ref(pm, nw, :filter)
            JuMP.set_lower_bound(crf[f], -filter["c_rating"])
            JuMP.set_upper_bound(crf[f],  filter["c_rating"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :filter, :crf, _PMs.ids(pm, nw, :filter), crf)
end
""
function variable_filter_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cif = _PMs.var(pm, nw)[:cif] = JuMP.@variable(pm.model,
            [f in _PMs.ids(pm, nw, :filter)], base_name="$(nw)_cif",
            start=_PMs.comp_start_value(_PMs.ref(pm, nw, :filter, f), "cif_start", 0.0)
    )
    
    if bounded
        for (f, filter) in _PMs.ref(pm, nw, :filter)
            JuMP.set_lower_bound(cif[f], -filter["c_rating"])
            JuMP.set_upper_bound(cif[f],  filter["c_rating"])
        end
    end

    report && _PMs.sol_component_value(pm, nw, :filter, :cif, _PMs.ids(pm, nw, :filter), cif)
end

# xfmr 
""
function variable_transformer_voltage_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    vrt = _PMs.var(pm, nw)[:vrt] = JuMP.@variable(pm.model, 
            [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_vrt",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "vrt_start", 1.0)
    )

    if bounded
        for (t, i, j) in _PMs.ref(pm, nw, :xfmr_arcs)
            vrt_min = - _PMs.ref(pm, nw, :bus, i)["vmax"] * _PMs.ref(pm, nw, :bus, i)["ihdmax"]
            vrt_max =   _PMs.ref(pm, nw, :bus, i)["vmax"] * _PMs.ref(pm, nw, :bus, i)["ihdmax"]

            JuMP.set_lower_bound(vrt[(t, i, j)], vrt_min)
            JuMP.set_upper_bound(vrt[(t, i, j)], vrt_max)
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :vrt_fr, :vrt_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), vrt)
end
""
function variable_transformer_voltage_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    vit = _PMs.var(pm, nw)[:vit] = JuMP.@variable(pm.model,
        [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_vit",
        start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "vit_start", 0.0)
    )

    if bounded
        for (t, i, j) in _PMs.ref(pm, nw, :xfmr_arcs)
            vit_min = - _PMs.ref(pm, nw, :bus, i)["vmax"] * _PMs.ref(pm, nw, :bus, i)["ihdmax"]
            vit_max =   _PMs.ref(pm, nw, :bus, i)["vmax"] * _PMs.ref(pm, nw, :bus, i)["ihdmax"]

            JuMP.set_lower_bound(vit[(t, i, j)], vit_min)
            JuMP.set_upper_bound(vit[(t, i, j)], vit_max)
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :vit_fr, :vit_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), vit)
end
""
function variable_transformer_voltage_excitation_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true, epsilon::Float64=1E-6)
    ert = _PMs.var(pm, nw)[:ert] = JuMP.@variable(pm.model,
            [t in _PMs.ids(pm, nw, :xfmr)], base_name="$(nw)_ert",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "ert_start", 0.0)
    )

    if bounded
        for (t, xfmr) in _PMs.ref(pm, nw, :xfmr)
            if haskey(xfmr, "ert_min")
                JuMP.set_lower_bound(ert[t], xfmr["ert_min"] + epsilon)
                JuMP.set_upper_bound(ert[t], xfmr["ert_max"] - epsilon)
            else
                JuMP.set_lower_bound(ert[t], -_PMs.ref(pm, nw, :bus, xfmr["f_bus"])["vmax"])
                JuMP.set_upper_bound(ert[t],  _PMs.ref(pm, nw, :bus, xfmr["f_bus"])["vmax"])
            end
        end
    end

    report && _PMs.sol_component_value(pm, nw, :xfmr, :ert, _PMs.ids(pm, nw, :xfmr), ert)
end
""
function variable_transformer_voltage_excitation_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true, epsilon::Float64=1E-6)
    eit = _PMs.var(pm, nw)[:eit] = JuMP.@variable(pm.model,
            [t in _PMs.ids(pm, nw, :xfmr)], base_name="$(nw)_eit",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "eit_start", 0.0)
    )

    if bounded
        for (t, xfmr) in _PMs.ref(pm, nw, :xfmr)
            if haskey(xfmr, "ert_min")
                JuMP.set_lower_bound(eit[t], xfmr["eit_min"] + epsilon)
                JuMP.set_upper_bound(eit[t], xfmr["eit_max"] - epsilon)
             else
                JuMP.set_lower_bound(eit[t], -_PMs.ref(pm, nw, :bus, xfmr["f_bus"])["vmax"])
                JuMP.set_upper_bound(eit[t],  _PMs.ref(pm, nw, :bus, xfmr["f_bus"])["vmax"])
            end
        end
    end

    report && _PMs.sol_component_value(pm, nw, :xfmr, :eit, _PMs.ids(pm, nw, :xfmr), eit)
end

""
function variable_transformer_current_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    crt = _PMs.var(pm, nw)[:crt] = JuMP.@variable(pm.model,
            [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_crt",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "crt_start", 0.0)
    )

    if bounded
        for (t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)
            xfmr = _PMs.ref(pm, nw, :xfmr, t)
            JuMP.set_lower_bound(crt[(t,i,j)], -xfmr["c_rating"])
            JuMP.set_upper_bound(crt[(t,i,j)],  xfmr["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :crt_fr, :crt_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), crt)
end
""
function variable_transformer_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cit = _PMs.var(pm, nw)[:cit] = JuMP.@variable(pm.model,
            [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_cit",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "cit_start", 0.0)
    )

    if bounded
        for (t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)
            xfmr = _PMs.ref(pm, nw, :xfmr, t)
            JuMP.set_lower_bound(cit[(t,i,j)], -xfmr["c_rating"])
            JuMP.set_upper_bound(cit[(t,i,j)],  xfmr["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :cit_fr, :cit_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), cit)
end
""
function variable_transformer_current_series_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    csrt = _PMs.var(pm, nw)[:csrt] = JuMP.@variable(pm.model,
            [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_csrt",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "csrt_start", 0.0)
    )

    if bounded
        for (t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)
            xfmr = _PMs.ref(pm, nw, :xfmr, t)
            JuMP.set_lower_bound(csrt[(t,i,j)], -xfmr["c_rating"])
            JuMP.set_upper_bound(csrt[(t,i,j)],  xfmr["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :csrt_fr, :csrt_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), csrt)
end
""
function variable_transformer_current_series_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    csit = _PMs.var(pm, nw)[:csit] = JuMP.@variable(pm.model,
            [(t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)], base_name="$(nw)_csit",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "csit_start", 0.0)
    )

    if bounded
        for (t,i,j) in _PMs.ref(pm, nw, :xfmr_arcs)
            xfmr = _PMs.ref(pm, nw, :xfmr, t)
            JuMP.set_lower_bound(csit[(t,i,j)], -xfmr["c_rating"])
            JuMP.set_upper_bound(csit[(t,i,j)],  xfmr["c_rating"])
        end
    end

    report && _IMs.sol_component_value_edge(pm, _PMs.pm_it_sym, nw, :xfmr, :csit_fr, :csit_to, _PMs.ref(pm, nw, :xfmr_arcs_from), _PMs.ref(pm, nw, :xfmr_arcs_to), csit)
end
""
function variable_transformer_current_magnetizing_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cmrt = _PMs.var(pm, nw)[:cmrt] = JuMP.@variable(pm.model,
            [t in _PMs.ids(pm, nw, :xfmr)], base_name="$(nw)_cmrt",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "cmrt_start", 0.0)
    )

    ## bounds are needed

    report && _PMs.sol_component_value(pm, nw, :xfmr, :cmrt, _PMs.ids(pm, nw, :xfmr), cmrt)
end
""
function variable_transformer_current_magnetizing_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cmit = _PMs.var(pm, nw)[:cmit] = JuMP.@variable(pm.model,
            [t in _PMs.ids(pm, nw, :xfmr)], base_name="$(nw)_cmit",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :xfmr, t), "cmit_start", 0.0)
    )

    ## bounds are needed

    report && _PMs.sol_component_value(pm, nw, :xfmr, :cmit, _PMs.ids(pm, nw, :xfmr), cmit)
end

# load 
""
function variable_load_current_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    crd = _PMs.var(pm, nw)[:crd] = JuMP.@variable(pm.model,
            [d in _PMs.ids(pm, nw, :load)], base_name="$(nw)_crd",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :load, d), "crd_start", 0.0)
    )

    if bounded
        for (d, load) in _PMs.ref(pm, nw, :load)
            c_rating = load["c_rating"]
            JuMP.set_lower_bound(crd[d], -c_rating)
            JuMP.set_upper_bound(crd[d],  c_rating)
        end
    end

    report && _PMs.sol_component_value(pm, nw, :load, :crd, _PMs.ids(pm, nw, :load), crd)
end
""
function variable_load_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cid = _PMs.var(pm, nw)[:cid] = JuMP.@variable(pm.model,
            [d in _PMs.ids(pm, nw, :load)], base_name="$(nw)_cid",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :load, d), "cid_start", 0.0)
    )

    if bounded
        for (d, load) in _PMs.ref(pm, nw, :load)
            c_rating = load["c_rating"]
            JuMP.set_lower_bound(cid[d], -c_rating)
            JuMP.set_upper_bound(cid[d],  c_rating)
        end
    end

    report && _PMs.sol_component_value(pm, nw, :load, :cid, _PMs.ids(pm, nw, :load), cid)
end
""
function variable_load_current_magnitude(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cmd = _PMs.var(pm, nw)[:cmd] = JuMP.@variable(pm.model,
            [d in _PMs.ids(pm, nw, :load)], base_name="$(nw)_cmd",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :load, d), "cmd_start", 0.0)
    )

    if bounded
        for (d, load) in _PMs.ref(pm, nw, :load)
            c_rating = load["c_rating"]
            JuMP.set_lower_bound(cmd[d], 0.0)
            JuMP.set_upper_bound(cmd[d], c_rating)
        end
    end

    report && _PMs.sol_component_value(pm, nw, :load, :cmd, _PMs.ids(pm, nw, :load), cmd)
end

# generator 
""
function variable_gen_current_real(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    crg = _PMs.var(pm, nw)[:crg] = JuMP.@variable(pm.model,
            [g in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_crg",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, g), "crg_start", 0.0)
    )

    if bounded
        for (g, gen) in _PMs.ref(pm, nw, :gen)
            c_rating = gen["c_rating"]
            JuMP.set_lower_bound(crg[g], -c_rating)
            JuMP.set_upper_bound(crg[g],  c_rating)
        end
    end

    report && _PMs.sol_component_value(pm, nw, :gen, :crg, _PMs.ids(pm, nw, :gen), crg)
end
""
function variable_gen_current_imaginary(pm::_PMs.AbstractPowerModel; nw::Int=fundamental(pm), bounded::Bool=true, report::Bool=true)
    cig = _PMs.var(pm, nw)[:cig] = JuMP.@variable(pm.model,
            [g in _PMs.ids(pm, nw, :gen)], base_name="$(nw)_cig",
            start = _PMs.comp_start_value(_PMs.ref(pm, nw, :gen, g), "cig_start", 0.0)
    )

    if bounded
        for (g, gen) in _PMs.ref(pm, nw, :gen)
            c_rating = gen["c_rating"]
            JuMP.set_lower_bound(cig[g], -c_rating)
            JuMP.set_upper_bound(cig[g],  c_rating)
        end
    end

    report && _PMs.sol_component_value(pm, nw, :gen, :cig, _PMs.ids(pm, nw, :gen), cig)
end