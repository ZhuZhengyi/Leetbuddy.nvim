local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local utils = require("leetbuddy.utils")
local split = require("leetbuddy.split")

local M = {}

local function show_daily_problem(problem)
    local question_slug = string.format("%04d-%s", problem["frontendQuestionId"], problem["titleSlug"])

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

function M.getDailyQuestion()
	local query = [[
        query questionOfToday {
          todayRecord {
            date
            userStatus
            question {
              questionId
              frontendQuestionId: questionFrontendId
              difficulty
              title
              titleCn: translatedTitle
              titleSlug
              paidOnly: isPaidOnly
              freqBar
              isFavor
              acRate
              status
              solutionNum
              hasVideoSolution
              topicTags {
                name
                nameTranslated: translatedName
                id
              }
              extra {
                topCompanyTags {
                  imgUrl
                  slug
                  numSubscribed
                }
              }
            }
            lastSubmission {
              id
            }
          }
        }
    ]]
	local response = curl.post(config.graphql_endpoint, {
		headers = headers,
		body = vim.json.encode({ operationName = "questionOfToday", query = query, variables = {} }),
	})
	local todayRecord = vim.json.decode(response["body"])["data"]["todayRecord"]

	if todayRecord ~= vim.NIL and todayRecord[1] ~= vim.NIL then
		if todayRecord[1]["question"] ~= vim.NIL then
			show_daily_problem(todayRecord[1]["question"])
		end
	end
end

return M
