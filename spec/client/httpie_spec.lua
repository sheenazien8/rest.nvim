---@diagnostic disable: invisible
---@module 'luassert'

require("spec.minimal_init")

local Context = require("rest-nvim.context").Context
local httpie = require("rest-nvim.client.httpie")
local builder = httpie.builder

describe("httpie builder", function()
    it("from GET request", function()
        local ctx = Context:new()
        local cmd = builder.build_command({
            context = ctx,
            method = "GET",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
        })
        assert.matches("http GET 'http://localhost:8000'", cmd)
    end)

    it("from GET request with headers", function()
        local ctx = Context:new()
        local cmd = builder.build_command({
            context = ctx,
            method = "GET",
            url = "http://localhost:8000",
            headers = {
                ["x-foo"] = { "bar" },
                ["accept"] = { "application/json" },
            },
            cookies = {},
            handlers = {},
        })
        assert.matches("http GET 'http://localhost:8000'", cmd)
        assert.matches("X-Foo:bar", cmd)
        assert.matches("Accept:application/json", cmd)
    end)

    it("from POST request with json body", function()
        local ctx = Context:new()
        local json_text = '{"string": "foo", "number": 100, "array": [1, 2, 3], "json": {"key": "value"}}'
        local cmd = builder.build_command({
            context = ctx,
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "json",
                data = json_text,
            },
        })
        assert.matches("http POST 'http://localhost:8000'", cmd)
        assert.matches("--json", cmd)
        assert.matches(json_text, cmd)
    end)

    it("from POST request with raw body", function()
        local ctx = Context:new()
        local raw_body = "field1=value1&field2=value2"
        local cmd = builder.build_command({
            context = ctx,
            method = "POST",
            url = "http://localhost:8000",
            headers = {},
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "raw",
                data = raw_body,
            },
        })
        assert.matches("http POST 'http://localhost:8000'", cmd)
        assert.matches("--raw", cmd)
        assert.matches(raw_body, cmd)
    end)

    it("from POST request with form body", function()
        local ctx = Context:new()
        local form_body = "field1=value1&field2=value2"
        local cmd = builder.build_command({
            context = ctx,
            method = "POST",
            url = "http://localhost:8000",
            headers = {
                ["content-type"] = { "application/x-www-form-urlencoded" },
            },
            cookies = {},
            handlers = {},
            body = {
                __TYPE = "raw",
                data = form_body,
            },
        })
        assert.matches("http POST 'http://localhost:8000'", cmd)
        assert.matches("--form", cmd)
    end)

    it("from GET request with cookies", function()
        local ctx = Context:new()
        local cmd = builder.build_command({
            context = ctx,
            method = "GET",
            url = "http://localhost:8000",
            headers = {},
            cookies = {
                {
                    name = "session",
                    value = "abc123",
                    domain = "localhost",
                },
                {
                    name = "user",
                    value = "john",
                    domain = "localhost",
                },
            },
            handlers = {},
        })
        assert.matches("http GET 'http://localhost:8000'", cmd)
        assert.matches("session=abc123", cmd)
        assert.matches("user=john", cmd)
    end)
end)
