local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local utils = require("leetbuddy.utils")
local split = require("leetbuddy.split")
local question = require("leetbuddy.question")

local M = {}

local function show_random_problem(slug)
    local problem = question.fetch_question_data(slug)
    local question_slug = string.format("%04d-%s", problem["questionFrontendId"], slug)

    local code_path = utils.get_code_file_path(question_slug, config.language)
    local test_case_path = utils.get_test_case_path(question_slug)

	if split.get_results_buffer() then
		vim.api.nvim_command("LBClose")
	end

	if not utils.file_exists(code_path) then
		vim.api.nvim_command(":silent !touch " .. code_path)
		vim.api.nvim_command(":silent !touch " .. test_case_path)
		vim.api.nvim_command("edit! " .. code_path)
		vim.api.nvim_command("LBReset")
	else
		vim.api.nvim_command("edit! " .. code_path)
	end
	vim.api.nvim_command("LBSplit")
	vim.api.nvim_command("LBQuestion")
end

function M.getRandomQuestion()
    vim.cmd("silent !LBCheckCookies")
    local variables = {
        categorySlug = "",
        filters = nil,
    }
	local query = [[
        query problemsetRandomFilteredQuestion($categorySlug: String!, $filters: QuestionListFilterInput) {
            problemsetRandomFilteredQuestion(categorySlug: $categorySlug, filters: $filters)
    }
    ]]
	local response = curl.post(config.graphql_endpoint, {headers = headers, body = vim.json.encode({ operationName = "problemsetRandomFilteredQuestion", query = query, variables = variables }) })
	local resp_json = vim.json.decode(response["body"])
    if resp_json == nil or resp_json["data"] == nil then
        if config.debug then
            print("Response from " .. config.graphql_endpoint)
            utils.P(response)
        end
        return
    end
    local data = resp_json["data"]
    if data ~= nil  then
        show_random_problem(data["problemsetRandomFilteredQuestion"])
    end
end

return M
