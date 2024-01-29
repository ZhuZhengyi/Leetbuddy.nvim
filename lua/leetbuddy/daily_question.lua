local curl = require("plenary.curl")
local config = require("leetbuddy.config")
local headers = require("leetbuddy.headers")
local reload = require("leetbuddy.reset")
local utils = require("leetbuddy.utils")

local M = {}

function M.getDailyQuestion()
    local query = config.domain == "cn" and [[
        query questionOfToday {
            todayRecord {
                date
                question {
                    questionFrontendId
                    titleSlug
                }
            }
        }
    ]] or [[
        query questionOfToday {
            activeDailyCodingChallengeQuestion: todayRecord {
                date
                question {
                    questionFrontendId
                    titleSlug
                }
            }
        }
    ]]
	local response = curl.post(config.graphql_endpoint, {
		headers = headers,
		body = vim.json.encode({ operationName = "questionOfToday", query = query, variables = {} }),
	})

    local ok, data = pcall(vim.json.decode, response["body"])
    if not ok then
        utils.Debug("cookies decode error: " .. response)
        return
    end
    local todayRecord = data["data"]["todayRecord"]

	if todayRecord ~= vim.NIL and todayRecord[1] ~= vim.NIL then
		if todayRecord[1]["question"] ~= vim.NIL then
            local question_data = todayRecord[1]["question"]
            reload.start_problem(question_data["titleSlug"])
		end
	end
end

return M
