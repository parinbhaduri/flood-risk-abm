import InteractiveDynamics
import Agents

function Agents.step!(abmobs::ABMObservable, n, agents_first = true; kwargs...)
    model, adf, mdf = abmobs.model, abmobs.adf, abmobs.mdf
    Agents.step!(model[], abmobs.agent_step!, abmobs.model_step!, n, agents_first; kwargs...)
    notify(model)
    abmobs.s[] = abmobs.s[] + n # increment step counter
    if Agents.should_we_collect(abmobs.s, model[], abmobs.when)
        if !isnothing(abmobs.adata)
            Agents.collect_agent_data!(adf[], model[], abmobs.adata, abmobs.s[])
            notify(adf)
        end
        if !isnothing(abmobs.mdata)
            Agents.collect_model_data!(mdf[], model[], abmobs.mdata, abmobs.s[])
            notify(mdf)
        end
    end
    return nothing
end

##Create ABM video
function anim_video(file, model, agent_step!, model_step! = Agents.dummystep;
    spf = 1, framerate = 30, frames = 300,  title = "", showstep = true,
    figure = (resolution = (600, 600),), axis = NamedTuple(),
    recordkwargs = (compression = 20,), kwargs...
)
    """Modification of Interactive Dynamics abmvideo function using modified
    Agents.step! function"""
    
    # add some title stuff
    s = Observable(0) # counter of current step
    if title ≠ "" && showstep
        t = lift(x -> title*", step = "*string(x), s)
    elseif showstep
        t = lift(x -> "step = "*string(x), s)
    else
        t = title
    end
    axis = (title = t, titlealign = :left, axis...)

    fig, ax, abmobs = abmplot(model;
    add_controls = false, agent_step!, model_step!, figure, axis, kwargs...)

    resize_to_layout!(fig)

    record(fig, file; framerate, recordkwargs...) do io
        for j in 1:frames-1
            recordframe!(io)
            Agents.step!(abmobs, spf, false)
            s[] += spf; s[] = s[]
        end
        recordframe!(io)
    end
    return nothing
end