local M = {}
local utils = require("leetbuddy.utils")
local i18n = require("leetbuddy.config").domain
local is_cn = i18n == "cn"

local info = {
    exe = { cn = "执行中", com = "Executing", },
    res = { cn = "结果", com = "Results", },
    pc = { cn = "通过测试用例数", com = "Passed Cases" },
    acc = { cn = "通过", com = "Accepted", },
    testc = { cn = "测试用例", com = "Test Case", },
    totc = { cn = "测试用例总数", com = "Total Cases", },
    inc = { cn = "输入", com = "Input", },
    out = { cn = "输出", com = "Out", },
    exp = { cn = "预期的", com = "Expected", },
    stdo = { cn = "标准输出", com = "Std Output" },
    mem = { cn = "内存消耗", com = "Memory"},
    rt = { cn = "执行用时", com = "Runtime"},
    r_err = { cn = "执行出错", com = "Runtime Error"},
    tl_err = { cn = "超出时间限制", com = "Time Limit Exceeded"},
    wrong_ans_err = { cn = "解答错误", com = "Wrong Answer"},
    failed = { cn = "失败的", com = "Failed"},
    f_case_in = { cn = "失败测试用例输入", com = "Failed Case Input"},
    exp_out = { cn = "预期输出", com = "Expected Output"},
}

M.info = info

local function get_status_msg(msg)
  if not is_cn then
    return msg
  end
  if msg == "Accepted" then
    return info["acc"][i18n]
  elseif msg == "Runtime Error" then
    return info["r_err"][i18n]
  elseif msg == "Time Limit Exceeded" then
    return info["tl_err"][i18n]
  elseif msg == "Wrong Answer" then
    return info["wrong_ans_err"][i18n]
  else
    return msg
  end
end

function M.display_results(is_executing, buffer, json_data, method, input_path)
  local results = {}

  local function insert(output)
    table.insert(results, output)
  end

  local function insert_table(t)
    for i = 1, #t do
      insert(t[i])
    end
  end

  if is_executing then
    insert(info["exe"][i18n] .. "...")
  else
    insert(info["res"][i18n])
    insert("")
    if method == "test" then
      if json_data["run_success"] then
        if json_data["correct_answer"] then
          insert(info["pc"][i18n] .. ": " .. json_data["total_testcases"])
          insert(info["acc"][i18n] .. " ✔️ ")
        else
          insert(
            string.format(
                "%s: %d / %s: %d",
               info["pc"][i18n],
               json_data["total_correct"],
               info["failed"][i18n], 
               (json_data["total_testcases"] - json_data["total_correct"])
            )
          )
          insert("")

          local test_case_inputs = utils.split_test_case_inputs(input_path, json_data["total_testcases"])
          for i = 1, json_data["total_testcases"] do
            if json_data["code_answer"][i] ~= json_data["expected_code_answer"][i] then
              insert(info["testc"][i18n] .. ": #" .. i .. " ❌ ")

              local failing_test_input = table.concat(test_case_inputs[i], ", ")
              insert(info["inc"][i18n] .. ": " .. failing_test_input)
              insert(info["out"][i18n].. ": " .. json_data["code_answer"][i])
              insert(info["exp"][i18n] .. ": " .. json_data["expected_code_answer"][i])
              local std = utils.split_string_to_table(json_data["std_output_list"][i])

              if #std > 0 then
                insert(info["stdo"][i18n] .. ": ")
                insert_table(std)
              end
              insert("")
            end
          end
          insert("")
          for i = 1, json_data["total_testcases"] do
            if json_data["code_answer"][i] == json_data["expected_code_answer"][i] then
              insert(
                string.format("%s:# %d: %s %s",
                info["testc"][i18n],
                  i,
                  json_data["code_answer"][i],
                  " ✔️ "
              ))
            end
          end
        end
        insert("")
        insert(info["mem"][i18n] .. ": " .. json_data["status_memory"])
        insert(info["rt"][i18n] .. ": " .. json_data["status_runtime"])
      else
        insert(get_status_msg(json_data["status_msg"]))
        insert(json_data["runtime_error"])
        insert("")

        local std_output = json_data["std_output_list"]
        if std_output ~= nil then
            insert(info["testc"][i18n] .. ": #" .. #std_output .. " ❌ ")
        end

        local std = utils.split_string_to_table(std_output[#std_output])

        if #std > 0 then
          insert(info["stdo"][i18n] .. ": ")
          insert_table(std)
        end
      end
      insert("")
    else
      -- Submit
      local success = json_data["total_correct"] == json_data["total_testcases"]

      if success then
        insert(info["pc"][i18n] .. ": " .. json_data["total_correct"])
        insert(info["acc"][i18n] .. " ✔️ ")
        insert("")
        insert(info["mem"][i18n] .. ": " .. json_data["status_memory"])
        insert(info["rt"][i18n] .. ": " .. json_data["status_runtime"])
      else
        insert(get_status_msg(json_data["status_msg"]))

        if json_data["run_success"] then
          insert(
            string.format("%s: %d / %s: %d",
                info["totc"][i18n],
                json_data["total_testcases"],
                info["failed"][i18n],
                json_data["total_testcases"] - json_data["total_correct"]
          ))
          insert("")
        else
          insert(json_data["runtime_error"])
          insert("")
        end
        insert(info["f_case_in"][i18n] .. ": ")
        insert_table(utils.split_string_to_table(json_data["last_testcase"]))

        -- Add failed testcase to input.txt
        -- if input_path ~= nil then
        --   local input_file = io.open(input_path, "r")
        --   local fileContent = input_file:read("*a")
        --   input_file:close()
        --
        --   if not string.find(fileContent, json_data["last_testcase"]) then
        --     -- Append the string to the end of the file
        --     input_file = io.open(input_path, "a")
        --     input_file:write(json_data["last_testcase"])
        --     input_file:close()
        --     print(json_data["last_testcase"] .. " added to the test inputs")
        --   end
        -- end

        insert("")
        insert(info["exp_out"][i18n] .. ": " .. json_data["expected_output"])
        insert(info["out"][i18n].. ": " .. json_data["code_output"])

        local std = utils.split_string_to_table(json_data["std_output"])
        if #std > 0 then
          insert(info["stdo"][i18n] .. ": ")
          insert_table(std)
        end
      end
    end
  end
  vim.api.nvim_buf_set_lines(buffer, 0, -1, true, results)
end

return M
