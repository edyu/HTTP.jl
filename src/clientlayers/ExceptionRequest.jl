module ExceptionRequest

export exceptionlayer

using ..IOExtras, ..Messages, ..Exceptions

"""
    exceptionlayer(handler) -> handler

Throw a `StatusError` if the request returns an error response status.
"""
function exceptionlayer(handler)
    return function exceptions(stream; status_exception::Bool=true, timedout=nothing, logerrors::Bool=false, logtag=nothing, kw...)
        res = handler(stream; timedout=timedout, logerrors=logerrors, logtag=logtag, kw...)
        if status_exception && iserror(res)
            req = res.request
            req.context[:status_errors] = get(req.context, :status_errors, 0) + 1
            e = StatusError(res.status, req.method, req.target, res)
            if logerrors && (timedout === nothing || !timedout[])
                err = current_exceptions_to_string(CapturedException(e, catch_backtrace()))
                @error err type=Symbol("HTTP.StatusError") method=req.method url=req.url context=req.context logtag=logtag
            end
            throw(e)
        else
            return res
        end
    end
end

end # module ExceptionRequest
