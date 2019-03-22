module GitLab

using ..GitForge
using ..GitForge:
    @json,
    DoNothing,
    Endpoint,
    Forge,
    JSON,
    OnRateLimit,
    RateLimiter,
    HEADERS,
    ORL_RETURN

using Dates
using HTTP
using JSON2

export GitLabAPI, OAuth2Token, PersonalAccessToken

const DEFAULT_URL = "https://gitlab.com/api/v4"

abstract type AbstractToken end

"""
    NoToken() -> NoToken

Represents no authentication.
Only public data will be available.
"""
struct NoToken <: AbstractToken end

"""
    OAuth2Token(token::AbstractString) -> OAuth2Token

An [OAuth2 bearer token](https://docs.gitlab.com/ce/api/#oauth2-tokens).
"""
struct OAuth2Token <: AbstractToken
    token::String
end

"""
    PersonalAccessToken(token::AbstractString) -> PersonalAccessToken

A [private access token](https://docs.gitlab.com/ce/api/#personal-access-tokens).
"""
struct PersonalAccessToken <: AbstractToken
    token::String
end

auth_headers(::NoToken) = []
auth_headers(t::OAuth2Token) = ["Authorization" => "Bearer $(t.token)"]
auth_headers(t::PersonalAccessToken) = ["Private-Token" => t.token]

"""
    GitLabAPI(;
        token::AbstractToken=NoToken(),
        url::AbstractString="$DEFAULT_URL",
        on_rate_limit::OnRateLimit=ORL_RETURN,
    ) -> GitLabAPI

Create a GitLab API client.

## Keywords
- `token::AbstractToken=NoToken()`: Authorization token (or lack thereof).
- `url::AbstractString="$DEFAULT_URL"`: Base URL of the target GitLab instance.
- `on_rate_limit::OnRateLimit=ORL_RETURN`: Behaviour on exceeded rate limits.
"""
struct GitLabAPI <: Forge
    token::AbstractToken
    url::String
    orl::OnRateLimit
    rl::RateLimiter

    function GitLabAPI(;
        token::AbstractToken=NoToken(),
        url::AbstractString=DEFAULT_URL,
        on_rate_limit::OnRateLimit=ORL_RETURN,
    )
        return new(token, url, on_rate_limit, RateLimiter())
    end
end

GitForge.base_url(g::GitLabAPI) = g.url
GitForge.request_headers(g::GitLabAPI, ::Function) = [HEADERS; auth_headers(g.token)]
GitForge.postprocessor(::GitLabAPI, ::Function) = JSON
GitForge.rate_limit_check(g::GitLabAPI, ::Function) = GitForge.rate_limit_check(g.rl)
GitForge.on_rate_limit(g::GitLabAPI, ::Function) = g.orl
GitForge.rate_limit_wait(g::GitLabAPI, ::Function) = GitForge.rate_limit_wait(g.rl)
GitForge.rate_limit_period(g::GitLabAPI, ::Function) = GitForge.rate_limit_period(grl)
GitForge.rate_limit_update!(g::GitLabAPI, ::Function, r::HTTP.Response) =
    GitForge.rate_limit_update!(g.rl, r)

include("users.jl")

end