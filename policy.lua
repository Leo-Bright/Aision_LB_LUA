---
--- Created by oilbeater.
--- DateTime: 17/8/21 上午10:40
---

local cjson = require "cjson"
local dsl   = require "dsl"

local method = ngx.var.request_method

if(method == "GET") then
    ngx.header["content-type"] = "application/json"
    local policies = ngx.shared.http_policy:get("all_policies")
    if(policies) then
        ngx.print(ngx.shared.http_policy:get("all_policies"))
    else
        ngx.print("{}")
    end
elseif(method == "PUT") then
    ngx.req.read_body()
    ngx.header["content-type"] = "application/json"
    local data = ngx.req.get_body_data()
    if(data == nil) then
        ngx.status = 400
        ngx.print("no request body")
        return
    end
    local all_ports_policies = cjson.decode(data)
    ngx.shared.http_policy:set("all_policies", cjson.encode(all_ports_policies))

    --split policies by port to decrease json operation overhead
    --parse raw dsl to ast to decrease overhead
    for port, policies in pairs(all_ports_policies)
    do
        for _, policy in ipairs(policies)
        do
            if(policy ~= cjson.null and policy["rule"] ~= cjson.null) then
                policy["rule"] = dsl.generate_ast(policy["rule"])

            end
        end
        ngx.shared.http_policy:set(port, cjson.encode(policies))
    end
    ngx.print(data)
    return

else
    ngx.log(ngx.ERR, string.format("%s is not support", method))
    ngx.status = 501
    ngx.print("Method not support")
    return
end