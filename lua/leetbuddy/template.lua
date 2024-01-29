
local template_config = {
    ["python3"] = {
        ["code_tmpl_start"] = "# @lc code = start",
        ["code_tmpl_end"] = "# @lc code = end",
        ["code"] = [[
''' 
#
# # [%d.%s](https://leetcode.%s/problems/%s/description/)
#
# @lc app=leetcode.cn id=%d lang=%s slug=%s
#
# ## 状态
#
# %s (%0.2f%%)
#
# ## 问题描述
#
# %s
#
# ## 测试用例
#
# ```text
#   %s
# ```
#
'''
#
%s
#
%s
#
%s
#
if __name__ == "__main__":
    pass

        ]],
    },
    ["rust"] = {
        ["code_tmpl_start"] = "// @lc code = start",
        ["code_tmpl_end"] = "// @lc code = end",
        ["code"] = [[
/*!
 * # [%d.%s](https://leetcode.%s/problems/%s/description/)
 *
 * @lc app=leetcode.cn id=%d lang=%s slug=%s
 *
 * ## 状态
 *
 * %s (%0.2f%%)
 *
 * ## 问题描述 
 *
 * %s
 *
 * ## 测试用例
 *
 * ```text
 *  %s
 * ```
 */

use super::*;

%s
%s
%s

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test() {

    }
}
        ]],
    },
    ["java"] = {
        ["code_tmpl_start"] = "// @lc code = start",
        ["code_tmpl_end"] = "// @lc code = end",
        ["code"] = [[
/*!
 * # [%d.%s](https://leetcode.%s/problems/%s/description/)
 *
 * @lc app=leetcode.cn id=%d lang=%s slug=%s
 *
 * ## 状态
 *
 * %s (%0.2f%%)
 *
 * ## 问题描述
 *
 * %s
 *
 * ## 测试用例
 *
 * ```text
 * %s
 * ```
 */

%s
%s
%s

public static int main() {
    s = Solution::new()

    return 0;
}
        ]],
    },
    ["cpp"] = {
        ["code_tmpl_start"] = "// @lc code = start",
        ["code_tmpl_end"] = "// @lc code = end",
        ["code"] = [[
/*!
 * # [%d.%s](https://leetcode.%s/problems/%s/description/)
 *
 * @lc app=leetcode.cn id=%d lang=%s slug=%s
 *
 * ## 状态
 *
 * %s (%0.2f%%)
 *
 * ## 问题描述
 *
 * %s
 *
 * ## 测试用例
 *
 * ```text
 *   %s
 * ```
 */

using namespace std;

%s
%s
%s

int main() {
    return 0;
}
        ]],
    },
    ["c"] = {
        ["code_tmpl_start"] = "// @lc code = start",
        ["code_tmpl_end"] = "// @lc code = end",
        ["code"] = [[
/*!
 * # [%d.%s](https://leetcode.%s/problems/%s/description/)
 *
 * @lc app=leetcode.cn id=%d lang=%s slug=%s
 *
 * ## 状态
 *
 * %s (%0.2f%%)
 *
 * ## 问题描述
 *
 * %s
 *
 * ## 测试用例
 *
 * ```text
 *   %s
 * ```
 */

#include <stdio.h>

%s
%s
%s

int main() {
    return 0;
}
        ]],
    },
    ["go"] = {
        ["code_tmpl_start"] = "// @lc code = start",
        ["code_tmpl_end"] = "// @lc code = end",
        ["code"] = [[
/*!
 * # [%d.%s](https://leetcode.%s/problems/%s/description/)
 *
 * @lc app=leetcode.cn id=%d lang=%s slug=%s
 *
 * ## 状态
 *
 * %s (%0.2f%%)
 *
 * ## 问题描述
 *
 * %s
 *
 * ## 测试用例
 *
 * ```text
 *   %s
 * ```
 */

%s
%s
%s

        ]],
    },
}

return template_config
