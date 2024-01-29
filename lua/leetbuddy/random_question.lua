local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local utils = require("leetbuddy.utils")
local reload = require("leetbuddy.reset")

local M = {}

function M.getRandomQuestion()
    vim.cmd("silent !LBCheckCookies")

    local variables = {
        categorySlug = "",
        filters = nil,
    }
    local query = config.domain == "cn" and [[
        query problemsetRandomFilteredQuestion(
            $categorySlug: String!,
            $filters: QuestionListFilterInput
        ) {
            problemsetRandomFilteredQuestion(
                categorySlug: $categorySlug,
                filters: $filters
            )
        }
    ]] or [[
        query problemsetRandomFilteredQuestion(
            $categorySlug: String!,
            $filters: QuestionListFilterInput
        ) {
            problemsetRandomFilteredQuestion(
                categorySlug: $categorySlug,
                filters: $filters
            )
        }
    ]]
	local response = curl.post(
        config.graphql_endpoint,
        {
            headers = headers,
            body = vim.json.encode({
                operationName = "problemsetRandomFilteredQuestion",
                query = query,
                variables = variables
            })
        }
    )
    local ok, resp_json = pcall(vim.json.decode, response["body"])
    if not ok then
        utils.Debug("getRandomQuestion decode error: " .. response)
        return
    end
    if resp_json == nil or resp_json["data"] == nil then
        if config.debug then
            print("Response from " .. config.graphql_endpoint)
            utils.P(response)
        end
        return
    end

    local slug = resp_json["data"]["problemsetRandomFilteredQuestion"]
    reload.start_problem(slug)
end

return M
