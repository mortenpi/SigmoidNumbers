#iterators.jl - creating iterator convenience types for SigmoidNumbers.

import Base: iterate, size

increment(::Type{Sigmoid{N, ES, mode}}) where {N, ES, mode} = (@signbit) >> (N - 1)

@generated function next(x::Sigmoid{N, ES, mode}) where {N, ES, mode}
  inc = increment(Sigmoid{N, ES, mode})
  :(reinterpret(Sigmoid{N, ES, mode}, @u(x) + $inc))
end

@generated function prev(x::Sigmoid{N, ES, mode}) where {N, ES, mode}
  inc = increment(Sigmoid{N, ES, mode})
  :(reinterpret(Sigmoid{N, ES, mode}, @u(x) - $inc))
end

@generated function iterate(T::Type{Sigmoid{N, ES, mode}}, state=T(Inf)) where {N, ES, mode}
    last_element = reinterpret(Sigmoid{N, ES, mode}, (@signbit) - increment(Sigmoid{N, ES, mode}))
    quote
        state == $last_element && return nothing
        (state, next(state))
    end
end

size(T::Type{Sigmoid{N, ES, mode}}) where {N, ES, mode} = 1 << N

export prev
