module HarmonicPowerModels

    # import pkgs
    import JuMP
    import PowerModels
    import InfrastructureModels
    import Memento

    # import types
    import PowerModels: AbstractPowerModel, AbstractIVRModel
    import InfrastructureModels: ids, ref, var, con, sol, nw_ids, nws

    # pkg constants 
    const _PMs = PowerModels
    const _IMs = InfrastructureModels

    function __init__()
        global _LOGGER = Memento.getlogger(PowerModels)
    end

    # const 
    const nw_id_default = 0

    # funct
    sorted_nw_ids(pm) = sort(collect(nw_ids(pm)))

    # paths
    const BASE_DIR = dirname(@__DIR__)

    # include
    include("core/variable.jl")

    include("form/iv.jl")

    include("prob/run_hopf_iv")

    # export
    export BASE_DIR

    export run_hopf_iv

end
