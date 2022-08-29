
module MyOptimisers
  using Flux
  using Flux.Optimise
  function ADAMExpDecay(; lr, decay, decaystep)
    Optimiser(ExpDecay(1.0, decay, decaystep), Flux.Optimise.ADAM(lr))
  end

  function ADAMClipped(; lr, clip)
    Optimiser(Flux.Optimise.ClipValue(clip), Flux.Optimise.ADAM(lr))
  end

  ADAM(; lr) = Flux.Optimise.ADAM(lr)

  RMSProp(; lr, rho=0.9) = Flux.Optimise.RMSProp(lr, rho)

  function RMSPropClipped(; lr, clip)
    Optimiser(Flux.Optimise.ClipValue(clip), Flux.Optimise.RMSProp(lr))
  end

  function RMSPropExpDecay(; lr, decay, decaystep)
    Optimiser(Flux.Optimise.RMSProp(lr), ExpDecay(1.0, decay, decaystep))
  end
end


function get_opt(s::Symbol)
  getproperty(MyOptimisers, s)
end