---@mod rest-nvim.client.httpie rest.nvim HTTPie command builder
---
---@brief [[
---
--- HTTPie command builder for copying HTTPie-compatible commands
---
---@brief ]]

local httpie = {}

local utils = require("rest-nvim.utils")

---@private
local builder = {}

---@private
local function escape_shell(str)
    return vim.fn.shellescape(str)
end

---@private
local function title_case(str)
    return string.gsub(" " .. str, "%W%l", string.upper):sub(2)
end

---@param header table<string,string[]>
---@return string[] args
function builder.headers(header)
    local args = {}
    for key, values in pairs(header) do
        for _, value in ipairs(values) do
            table.insert(args, title_case(key) .. ":" .. value)
        end
    end
    return args
end

---@param cookies rest.Cookie[]
---@return string[] args
function builder.cookies(cookies)
    return vim.iter(cookies)
        :map(function(cookie)
            return cookie.name .. "=" .. cookie.value
        end)
        :totable()
end

---@param body string
---@return string[] args
function builder.json_body(body)
    if not body then
        return {}
    end
    return { "--json", body }
end

---@param body string
---@return string[] args
function builder.form_body(body)
    if not body then
        return {}
    end
    local args = { "--form" }
    local query_pairs = vim.split(body, "&")
    for _, pair in ipairs(query_pairs) do
        local key, value = pair:match("([^=]+)=?(.*)")
        if key then
            table.insert(args, key .. "=" .. value)
        end
    end
    return args
end

---@param body string
---@return string[] args
function builder.raw_body(body)
    if not body then
        return {}
    end
    return { "--raw", body }
end

---@param file string
---@return string[] args
function builder.file_body(file)
    if not file then
        return {}
    end
    return { "--raw", "@" .. file }
end

---@param req rest.Request
---@return string[] args
function builder.build_args(req)
    local args = {}

    vim.list_extend(args, builder.headers(req.headers))
    vim.list_extend(args, builder.cookies(req.cookies))

    if req.body then
        if req.body.__TYPE == "external" then
            if req.body.data.content then
                vim.list_extend(args, builder.raw_body(req.body.data.content))
            else
                vim.list_extend(args, builder.file_body(req.body.data.path))
            end
        elseif req.body.__TYPE == "json" then
            vim.list_extend(args, builder.json_body(req.body.data))
        elseif req.body.__TYPE == "xml" then
            vim.list_extend(args, builder.raw_body(req.body.data))
        elseif req.body.__TYPE == "graphql" then
            vim.list_extend(args, builder.json_body(req.body.data))
        elseif req.body.__TYPE == "raw" then
            local content_type = req.headers["content-type"] and req.headers["content-type"][1]
            if content_type and content_type:match("application/x-www-form-urlencoded") then
                vim.list_extend(args, builder.form_body(req.body.data))
            else
                vim.list_extend(args, builder.raw_body(req.body.data))
            end
        end
    end

    return args
end

---Generate HTTPie command equivalent to given request
---@param req rest.Request
---@return string command
function builder.build_command(req)
    local args = builder.build_args(req)
    local escaped_args = vim.iter(args):map(escape_shell):join(" ")
    local method = req.method:upper()

    return string.format("http %s %s %s", method, escape_shell(req.url), escaped_args)
end

httpie.builder = builder

return httpie
