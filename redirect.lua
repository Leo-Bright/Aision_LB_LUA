---
--- Created by oilbeater.
--- DateTime: 17/8/17 上午10:35
---
--

local cjson = require "cjson"
local dsl = require "dsl"

local policies = ngx.shared.http_policy:get(ngx.var.server_port)

if(policies) then
    policies = cjson.decode(policies)
    for _, policy in ipairs(policies) do
        if(policy ~= cjson.null and policy["rule"] ~= cjson.null) then
            local match, err = dsl.eval(policy["rule"])
            if(match) then
                ngx.var.upstream = policy["upstream"]
                return
            end

            if(err ~= nil ) then
                ngx.log(ngx.ERR, "eval dsl %s failed %s", cjson.encode(policy["rule"]), err)
            end
        end
    end

    -- return 404 if no rule match
    if(ngx.var.upstream == "default") then
        ngx.status = 404
        ngx.say("Resource not found")
    end
else
    -- no policies on this port
    ngx.status = 404
    ngx.say("Resource not found")
end
