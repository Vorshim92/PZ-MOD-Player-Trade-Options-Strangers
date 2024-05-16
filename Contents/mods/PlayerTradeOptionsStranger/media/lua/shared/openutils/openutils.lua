--
-- Copyright (c) 2023 outdead.
-- Use of this source code is governed by the MIT license
-- that can be found in the LICENSE file.
--

-- openutils contains shared defines.
openutils = {
    Version = "0.4.1", -- in semantic versioning (http://semver.org/)
    Color = {
        White = "<RGB:1,1,1>",
        Red = "<RGB:1,0,0>"
    },
    Role = {
        ["admin"] = 5, ["moderator"] = 4, ["overseer"]= 3, ["gm"] = 2, ["observer"] = 1, ["none"] = 0,
    },
}

-- ObjectLen returns count of elements in list.
function openutils.ObjectLen(items)
    local count = 0
    for _, item in pairs(items) do
        count = count + 1
    end

    return count
end