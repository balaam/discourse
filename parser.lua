#!/opt/local/bin/lua

package.path = package.path .. ";./src/?.lua"
require("ParseCore")
require("PrintTable")

--
-- Simple parser
--
--
-- Step 1. No name, simple dialog box parser.
--
--
-- [Hello]  -> tree: { { text = "Hello" } }
--
-- [Hello -> error: Line 1: Expected closing square bracket, to match (0,1).
--
-- Hello] -> error: Line 1: Unexpected closing bracket (6,7).
--
-- Hello -> error: Unexpected symbol 'Hello' (0,5). Perhaps you missed a ':'?
--
-- Step 2. Significant whitespace, name attribution
--
-- Jeff:
--  [Hello]    -- 4 spaces
--  [Goodbye]  -- 1 tab - no tabs, spaces only?
-- [Don't you goodbye me] -- back to base
-- ->
-- {
--    { speaker = "jeff", text = "Hello" },
--    { speaker = "jeff", text = "Goodbye" },
--    { text = "Don't you goodbye me" },
-- }
-- Question how would you do interruptions?
-- ["Goodbye", skip_wait]
-- ["Hello", skip_wait_after:0.8]
-- In this case the transitions would continue to play
-- but the progress of the conversation would advance
-- to the next instruction
--
--
-- ["Why did I bring you<tag:face/> here, you ask? Why to show you my machine!"]
-- -> on tag "face" run action face(speaker, player)
-- -> on finish run action script("start_machine")

-- start_state = read until alpha or open bracket or eof
-- raise as error through context that gives line number and column
-- error expected speaker id or dilaog found [x]
-- when this happens insert a new child table
-- and pass it on to read_speaker or read_speaker_table

if not arg[1] then
    print "Need a filename as an argument."
    return
end

local f = io.open(arg[1], "rb")
local content = f:read("*all")
f:close()

local context = DoParse(content)

print("Number of lines ", context.line_number)
PrintTable(context)
