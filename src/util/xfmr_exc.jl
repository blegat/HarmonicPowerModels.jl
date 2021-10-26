################################################################################
#  Copyright 2021, Frederik Geth, Tom Van Acker                                #
################################################################################
# HarmonicPowerModels.jl                                                       #
# An extention package of PowerModels.jl for Harmonic (Optimal) Power Flow     #
# See http://github.com/timmyfaraday/HarmonicPowerModels.jl                    #
################################################################################

"""
    HarmonicPowerModels.magnetic_flux_density_polar(E::Vector{<:Real}, θ::Vector{<:Real}, ω::Vector{<:Real}, t::Vector{<:Real}, A::Real, Vbase::Real)

Function to determine the time-domain magnetic flux density B(t) for a given
time-vector `t` and core surface `A`, based on the frequency-domain excitation 
voltage in polar form, given by `E`, `θ`, `ω` and `Vbase`.

```math 
\begin{align}
    B(t) = \sum_{h \in H} \frac{Vbase \cdot |E_h|}{A \cdot ω_h} ⋅ \cos(\omega_h ⋅ t + \theta_h)
\end{align}
```

"""
magnetic_flux_density_polar(E::Vector{<:Real}, θ::Vector{<:Real}, ω::Vector{<:Real}, 
                            t::Vector{<:Real}, A::Real, Vbase::Real) = 
    sum(Vbase .* E[h] ./ ω[h] ./ A .* cos.(ω[h] .* t .+ θ[h]) for h in 1:length(E))

"""
    HarmonicPowerModels.magnetic_flux_density_rectangular(Ere::Vector{<:Real}, Eim::Vector{<:Real}, ω::Vector{<:Real}, t::Vector{<:Real}, A::Real, Vbase::Real)

Function to determine the time-domain magnetic flux density B(t) for a given
time-vector `t` and core surface `A`, based on the frequency-domain excitation 
voltage in rectangular form, given by `Ere`, `Eim`, `ω` and `Vbase`. 

This dispatches to `magnetic_flux_density_polar(hypot.(Ere,Eim), atan.(Eim,Eim), ω, t, A, Vbase)`.
"""
magnetic_flux_density_rectangular(Ere::Vector{<:Real}, Eim::Vector{<:Real}, ω::Vector{<:Real}, 
                                  t::Vector{<:Real}, A::Real, Vbase::Real) =
    magnetic_flux_density_polar(hypot.(Ere, Eim), atan.(Eim, Ere), ω, t, A, Vbase)

""
function sample_voltage_rectangular(E_harmonics, dE, E_min, E_max, dθ, θ_min, θ_max)
    S = reduce(vcat,[[E_min[ni]:dE[ni]:E_max[ni],θ_min[ni]:dθ[ni]:θ_max[ni]] 
                      for (ni,nh) in enumerate(E_harmonics)])
    R = [1:length(s) for s in S]
    return S, R
end

""
function sample_voltage_rectangular(E_harmonics, dEre, Ere_min, Ere_max, dEim, Eim_min, Eim_max)
    S = reduce(vcat,[[Ere_min[ni]:dEre[ni]:Ere_max[ni],Eim_min[ni]:dEim[ni]:Eim_max[ni]] 
                      for (ni,nh) in enumerate(E_harmonics)])
    R = [1:length(s) for s in S]
    return S, R
end

"""
    HarmonicPowerModels.sample_xfmr_excitation(data::Dict{String, <:Any}, xfmr_exc::Dict{String, <:Any})

This function creates anonymous functions which wrap a spline model of the 
exitation current. As inputs it takes either the rectangular or polar 
coordinates of the excitation voltage of transformer x ∈ 𝓧:
    `E^{re}_{h,x}, E^{im}_{h,x}, ∀ h ∈ 𝓗ᵉ,`
        or
    `E_{h,x}, θ_{h,x}, ∀ h ∈ 𝓗ᵉ,`
and outputs either the rectangular or polar coordinates of the exictation 
current of tranformer x ∈ 𝓧:
    `I^{exc,re}_{h,x}, I^{exc,im}_{h,x}, ∀ h ∈ 𝓗ⁱ,`
        or
    `I^{exc}_{h,x}, φ^{exc}_{h,x}, ∀ h ∈ 𝓗ⁱ,`
where 𝓗ᵉ and 𝓗ⁱ denote the set of excitation voltage and current harmonics, 
respectively.

All excitation models are stored in a dictionary `xfmr_exc`, where xfmr-id => an 
excitation model is a dictionary consisting of three types of input:
- General input, including:
    - E_formulation         :: Symbol       -- chosen excitation voltage formulation, i.e., :rectangular or :polar
    - I_formulation         :: Symbol       -- chosen excitation current formulation, i.e., :rectangular or :polar
    - E_harmonics           :: Vector{Int}  -- set of excitation voltage harmonics
    - I_harmonics           :: Vector{Int}  -- set of excitation current harmonics
- Magnetization model input, including:
    - BH_curve              :: Function     -- anonymous function for the inversed BH-curve [T // A-turns/m]
    - mean_path             :: Real         -- mean magnetic path [m]
    - core_surface          :: Real         -- core surface [m²]
- Excitation voltage input, depending on the chosen E_formulation:
    if E_formulation == :rectangular
    - dEre                  :: Vector{Real} -- step of the real excitation voltage [pu] for each excitation voltage harmonic  
    - Ere_min               :: Vector{Real} -- minimum real excitation voltage [pu] for each excitation voltage harmonic
    - Ere_max               :: Vector{Real} -- maximum real excitation voltage [pu] for each excitation voltage harmonic
    - dEim                  :: Vector{Real} -- step of the imaginary excitation voltage [pu] for each excitation voltage harmonic
    - Eim_min               :: Vector{Real} -- minimum imaginary excitation voltage [pu] for each excitation voltage harmonic 
    - Eim_max               :: Vector{Real} -- maximum imaginary excitation voltage [pu] for each excitation voltage harmonic 
    if E_formulation == :polar
    - dE                    :: Vector{Real} -- step of the excitation voltage magnitude [pu] for each excitation voltage harmonic
    - dE_min                :: Vector{Real} -- minimum excitation voltage magnitude [pu] for each excitation voltage harmonic
    - dE_max                :: Vector{Real} -- maximum excitation voltage magnitude [pu] for each excitation voltage harmonic
    - dθ                    :: Vector{Real} -- step of the excitation voltage phase angle [rad] for each excitation voltage harmonic 
    - dθ_min                :: Vector{Real} -- minimum excitation voltage phase angle [rad] for each excitation voltage harmonic
    - dθ_max                :: Vector{Real} -- maximum excitation voltage phase angle [rad] for each excitation voltage harmonic
"""
function sample_xfmr_excitation(data::Dict{String, <:Any}, xfmr_exc::Dict{Int, Dict{String, <:Any}})
    # interpolation method 
    method = _INT.BSpline(_INT.Cubic(_INT.Line(_INT.OnGrid())))
    # reversed harmonics dictionary
    reverse_harmonics = Dict(value => key for (key, value) in data["harmonics"])

    # enumerate over all xfmr excitation models
    for (nx, exc) in enumerate(xfmr_exc)
        # define the necessary time parameters
        ω  = (2.0 * pi * freq) .* exc["E_harmonics"]
        dt = (1 / (100 * _HPM.freq * maximum(exc["I_harmonics"])))
        t  = 0.0:dt:(5.0 / _HPM.freq)

        # define the decomposition structure, see https://github.com/JuliaDynamics/SignalDecomposition.jl  
        fq = _SDC.Sinusoidal(freq .* exc["I_harmonics"])

        # sample the excitation voltage
        if exc["E_formulation"] == :polar
            S, R = sample_voltage_polar(exc["E_harmonics"], exc["dE"], exc["E_min"], exc["E_max"],
                                                            exc["dθ"], exc["θ_min"], exc["θ_max"])
        elseif exc["E_formulation"] == :rectangular
            S, R = sample_voltage_rectangular(exc["E_harmonics"], exc["dEre"], exc["Ere_min"], exc["Ere_max"],
                                                                  exc["dEim"], exc["Eim_min"], exc["Eim_max"])
        else 
            error("E_formulation ∉ [:polar, :rectangular] for xfmr $nx")
        end

        # initialize dictionaries for excitation current, where:
        # I_formulation == :polar => a = magnitude, b = phase angle
        # I_formulation == :rectangular => a = real, b = imaginary
        Ia = Dict(nh => zeros(R...) for nh in exc["I_harmonics"])
        Ib = Dict(nh => zeros(R...) for nh in exc["I_harmonics"])

        # loop to sample the excitation current
        @showprogress for nr in Iterators.product(R...)
            sample = [S[ni][ns] for (ni,ns) in enumerate(nr)]

            # determine the xfmr magnetic flux density B(t) based on the 
            # excitation voltage sample.
            if exc["E_formulation"] == :polar
                E, θ = sample[1:2:end], sample[2:2:end]
                B = magnetic_flux_density_polar(E, θ, ω, t, exc["core_surface"])
            elseif exc["E_formulation"] == :rectangular
                Ere, Eim = sample[1:2:end], sample[2:2:end]
                B = magnetic_flux_density_rectangular(Ere, Eim, ω, t, exc["core_surface"])
            end

            # determine the excitation current iᵉ(t) [pu] based on the magnetic 
            # field intensity H(t) = BH(B(t)) [A-turns/m] and the mean magnetic path. 
            i_exc = exc["mean_path"] .* exc["BH-curve"].(B) ./ Abase

            # decompose the excitation current iᵉ(t) into its frequency components
            _SDC.decompose(t, i_exc, fq)

            # translate the frequency components to the required excitation 
            # current formulation
            if exc["I_formulation"] == :polar
                # NOTE -- angle convention is reversed -> introduce minus-sign 
                # for the phase angle
                I, φ = fq.A[2:end], -fq.φ[2:end]
                for (ni,nh) in enumerate(exc["I_harmonics"])
                    Ia[nh][nr...], Ib[nh][nr...] = I[ni], φ[ni]
                end
            elseif exc["I_formulation"] == :rectangular
                # NOTE -- angle convention is reversed -> introduce minus-sign 
                # for the phase angle
                Ire, Iim = fq.A[2:end] .* sin.(-fq.φ[2:end]), fq.A[2:end] .* cos.(-fq.φ[2:end])
                for (ni,nh) in enumerate(current_harmonics)
                    Ia[nh][nr...], Ib[nh][nr...] = Ire[ni], Iim[ni]
                end
            else
                error("I_formulation ∉ [:polar, :rectangular] for xfmr $nx")
            end
        end

        # fill the xfmr data structure, enumerating over all harmonics
        for nw in keys(data["nw"]) 
            # shortcut for the xfmr data
            xfmr = data["nw"][nw]["xfmr"]["$nx"]

            # determine the ni and nh
            nh = data["harmonics"][nw]
            ni = findfirst(x->x==nh, exc["E_harmonics"])
               
            # general data
            xfmr["I_formulation"] = exc["I_formulation"]
            xfmr["E_formulation"] = exc["E_formulation"]
            xfmr["I_harmonics_ntws"] = [parse(Int,reverse_harmonics[nc]) for nc in exc["I_harmonics"]]
            xfmr["E_harmonics_ntws"] = [parse(Int,reverse_harmonics[nv]) for nv in exc["E_harmonics"]]

            # excitation current data
            if nh in exc["I_harmonics"]
                xfmr["EXC_A"]  = _INT.extrapolate(_INT.scale(_INT.interpolate(Ia[nh], method), S...), _INT.Line())
                xfmr["EXC_B"]  = _INT.extrapolate(_INT.scale(_INT.interpolate(Ia[nh], method), S...), _INT.Line())
                xfmr["INT_A"]  = (x...) -> xfmr["EXC_A"](x...)
                xfmr["INT_B"]  = (x...) -> xfmr["EXC_B"](x...)
                xfmr["GRAD_A"] = (x...) -> _INT.gradient(xfmr["EXC_A"], x...)
                xfmr["GRAD_B"] = (x...) -> _INT.gradient(xfmr["EXC_B"], x...)
            end
                    
            # excitation voltage data 
            if nh in exc["E_harmonics"]
                if exc["E_formulation"] == :polar
                    xfmr["emt_min"], xfmr["emt_max"] = exc["E_min"][ni], exc["E_max"][ni]
                    xfmr["eat_min"], xfmr["eat_max"] = exc["θ_min"][ni], exc["θ_max"][ni]
                elseif exc["E_formulation"] == :rectangular
                    xfmr["ert_min"], xfmr["ert_max"] = exc["Ere_min"][ni], exc["Ere_max"][ni] 
                    xfmr["eit_min"], xfmr["eit_max"] = exc["Eim_min"][ni], exc["Eim_max"][ni]
                end
            else
                if exc["E_formulation"] == :polar
                    # TODO: take data from fr-bus voltage limits
                    xfmr["emt_min"], xfmr["emt_max"] = 0.0, 1.1
                    xfmr["eat_min"], xfmr["eat_max"] = 0.0, 2π
                elseif exc["E_formulation"] == :rectangular
                    # TODO: take data from fr-bus voltage limits
                    xfmr["ert_min"], xfmr["ert_max"] = -1.1, 1.1 
                    xfmr["eit_min"], xfmr["eit_max"] = -1.1, 1.1
                end
            end
        end
    end
end