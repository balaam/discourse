#!/opt/local/bin/lua

package.path = package.path .. ";../src/?.lua"
require("PrintTable")
require("ParseCore")
require("TestHelper")

-- Guidelines
-- Cuts should have no effect at all
-- Once a cut is removed the text should be as if was parsed without the tags

tests =
{
    {
        name = "Empty string gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse(""), testTable)
        end
    },
    {
        name = "Empty line gives empty syntax tree",
        test = function()
            local testTable = {}
            return AreTablesEqual(DoParse("\n"), testTable)
        end
    },
    {
         name = "Speaker with no text gives error.",
         test = function()
             local tree, result = DoParse("null:")
             return result.isError == true
         end
    },
    {
         name = "Speaker with name and line creates syntax tree representation.",
         test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
         end
    },
    {
        name = "Speaker name may not have space between name and colon",
        test = function()
            local tree, result = DoParse("null :Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not have tab between name and colon",
        test = function()
            local tree, result = DoParse("null\t:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speaker name may not contain newline",
        test = function()
            local tree, result = DoParse("nu\nll:Hello")
            return result.isError == true
        end,
    },
    {
        name = "Speech may contain colon",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello Altar: Destroyer of Worlds."} }}
            local parsedTable = DoParse("null:Hello Altar: Destroyer of Worlds.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end,
    },
    {
        name = "Speech needs a speaker",
        test = function()
            local tree, result = DoParse("Hello")
            return result.isError == true
        end
    },
    {
        name = "Speaker mame may contain space",
        test = function()
            local testTable = {{speaker = "Mr null", text = {"Hello"} }}
            local parsedTable = DoParse("Mr null:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading newline in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null:\nHello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Ignore leading whitespace in speech",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }}
            local parsedTable = DoParse("null: Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Single line breaks are preserved.",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark\nthat's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Extra space after speech line break is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"It was really dark\nthat's why we didn't see him."} }}
            local parsedTable = DoParse("null:It was really dark \n that's why we didn't see him.")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Trailing newlines are removed",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello", "Goodbye"} }}
            local parsedTable = DoParse("null:Hello\n\nGoodbye\n\n\n")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "A script can have multiple speakers",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello\nbob:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Space between multiple speakers is ignored",
        test = function()
            local testTable = {{speaker = "null", text = {"Hello"} }, {speaker = "bob", text = {"Hello"} }}
            local parsedTable = DoParse("null:Hello\n\n\nbob:Hello")
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    -- {
    --     name = "quick test",
    --     test = function()
    --         local tree, result = DoParse("Bob:\nHello\n\nThis is more test yo yo yo")
    --         return result.isError == false
    --     end
    -- },
    {
        name = "Unregistered tag throws error",
        test = function()

            local tree, result = DoParse("Bob:\nHello<null>")
            return result.isError == true
        end
    },
    {
        name = "Tag at end of line isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null>", tagTable)

            -- This test doesn't care about the tag data
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Two tags at end of line aren't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHello<null><null>", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Embedded tag isn't included in speech",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:\nHel<null>lo", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed",
        test = function()
        local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>Hello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part as tag is removed including space",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob: <null>Hello", tagTable)
            local testTable = DoParse("Bob: Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "First speech part before newline as tag is removed",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local testTable = {{speaker = "Bob", text = {"Hello"} }}
            local parsedTable = DoParse("Bob:<null>\nHello", tagTable)
            StripTable(parsedTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>", tagTable)
            local testTable = DoParse("Bob:\nHello\n\n\n\n", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "All space is trimmed before and after tag",
        test = function()
            local tagTable = { ["null"] = { type = "Short" }}
            local parsedTable = DoParse("Bob:\nHello\n\n\n\n<null>\n\n\n\nWorld", tagTable)
            local testTable = DoParse("Bob:\nHello\n\n\n\n\n\n\n\nWorld", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Wide tags are remove from final text",
        test = function()
            local tagTable = { ["wide"] = { type = "Wide" }}
            local parsedTable = DoParse("Bob:<wide>Hello World</wide>", tagTable)
            local testTable = DoParse("Bob: Hello World", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan wide-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Orphan short-close tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Short" }}
            local tree, result = DoParse("bob:</slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Unclosed tag gives error, even with nested tags",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow><slow>Hello</slow>", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Nested wide tags work",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local parsedTable = DoParse("bob:<slow><slow>Hello</slow></slow>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Short tag nested in Wide tags",
        test = function()
            local tagTable =
            {
                ["slow"] = { type = "Wide" },
                ["null"] = { type = "Short" }
            }
            local parsedTable = DoParse("bob:<slow><null>Hello</slow>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Cut script", --date between tags is removed
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }
            local parsedTable = DoParse("bob:<script>Words go here</script>Hello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)

        end
    },
    {
        name = "Multi-line cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:\n<script>\n\nWords go here\n\n</script>\nHello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multiline start same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello<script>\nWords go here\n\n</script>", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")

            PrintTable(parsedTable)
            PrintTable(testTable)

            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:<script>\nWords go here\n\n</script>Hello", tagTable)
            local testTable = DoParse("bob:Hello", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Multi-line end same line as text cut script",
        test = function()
            local tagTable =
            {
                ["script"] = { type = "Cut" },
            }

            local parsedTable = DoParse("bob:Hello\n\n<script>post text box script</script>\n\nGoodbye", tagTable)
            local testTable = DoParse("bob:Hello\n\nGoodbye", tagTable)
            StripTable(parsedTable, "tags")
            StripTable(testTable, "tags")
            return AreTablesEqual(parsedTable, testTable)
        end
    },
    {
        name = "Unclosed tag gives error",
        test = function()
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse("bob:<slow>Hello", tagTable)
            return result.isError == true
        end
    },
    {
        name = "Tag at start of a line is at offset 0",
        test = function()


            local testText = "bob:<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}


            --Hello Wor
            --123456789

            -- Tag position
            --*Hello Wo
            -- 0 offset

            --Hello Wor*
            -- 9 offset

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Tag at end of a line is at offset 0",
        test = function()


            local testText = "bob:Hello<null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging",
        test = function()


            local testText = "bob:   <null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with pre-newline",
        test = function()


            local testText = "bob:   \n<null>Hello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Front tag offset is correct in regards to line merging with post-newline",
        test = function()


            local testText = "bob:   <null>\nHello"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)

            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][0] or {}

            return tagEntry[1].id == "null"
        end
    },
    {
        name = "New line should be stripped with trailing tag", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()


            local testText = "bob:Hello\n <null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

           -- I PrintTable(tree)
            return tree[1].text[1] == "Hello"
        end
    },
    {
        name = "All newlines before inner short tag are stripped", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()

            -- Hello          Hello
            -- <null>    -->  World
            -- World

            local testText = "bob:Hello\n <null>\nWorld"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

           -- I PrintTable(tree)
            return tree[1].text[1] == "Hello\nWorld"
        end
    },
    {
        name = "Trailing tag should give correct index", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()
            local testText = "bob:Hello\n<null>"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}
            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Inner short tags should give correct index", -- !! REPEAT THIS TEST WITH INLINE CUT
        test = function()
            local testText = "bob:Hello\n<null>\nWorld"
            local tagTable = { ["null"] = { type = "Short" }}
            local tree, result = DoParse(testText, tagTable)

            local _, firstEntry = next(tree)
            --PrintTable(tree)
            local strLength = #("Hello")
            local tagLookup = FormatTags(firstEntry.tags)
            local tagEntry = tagLookup[1][strLength] or {}
            return tagEntry[1].id == "null"
        end
    },
    {
        name = "Both wide tags are added to the tag table",
        test = function()
            local testText = "bob:<slow>Hello</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)

            local openTag, closeTag = GetFirstTagPair("slow", tree)
            local doTagsExist = (openTag ~= nil) and (closeTag ~= nil)
            return doTagsExist
        end,
    },
    {
        name = "Wide tag marksup twoword oneliner",
        test = function()
            local txt = "bob:<slow>Hello</slow> World"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello"
        end,
    },
    {
        name = "Wide tag marksup full oneliner",
        test = function()
            local txt = "bob:<slow>Hello World</slow>"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello World"
        end,
    },
    {
        name = "Wide tag marksup full oneliner nested",
        test = function()
            local txt = "bob:<slow><red>Hello World</red></slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Wide tag marksup full two-liner one page",
        test = function()
            local txt = "bob:<slow>Hello\nWorld</slow>"
            local text1 = GetTextInFirstWideTag(txt, {"slow"}, "slow")

            return text1 == "Hello\nWorld"
        end,
    },
    {
        name = "Wide tag marksup full two pages", -- really starting too need some helpers...
        test = function()
            local testText = "bob:<slow>Hello\n\nWorld</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)
            local openTag, closeTag = GetFirstTagPair("slow", tree)

            local s = openTag.offset + 1
            local e = closeTag.offset + 1

            local isOpenTagOnLineOne = openTag.line == 1
            local isCloseTagOnLineTwo = closeTag.line == 2
            local isOpenTagOffsetAtStart = s == 1
            local isCloseOffsetAtEndOfWorld = e == #"World"

            return isCloseTagOnLineTwo and isOpenTagOnLineOne
                    and isOpenTagOffsetAtStart
                    and isCloseOffsetAtEndOfWorld
        end,
    },
    {
        name = "Wide tag respects line folding", -- really starting too need some helpers...
        test = function()
            local testText = "bob:<slow>Hello\n\n\nWorld</slow>"
            local tagTable = { ["slow"] = { type = "Wide" }}
            local tree, result = DoParse(testText, tagTable)
            local openTag, closeTag = GetFirstTagPair("slow", tree)

            local s = openTag.offset + 1
            local e = closeTag.offset + 1

            local isOpenTagOnLineOne = openTag.line == 1
            local isCloseTagOnLineTwo = closeTag.line == 2
            local isOpenTagOffsetAtStart = s == 1
            local isCloseOffsetAtEndOfWorld = e == #"World"

            return isCloseTagOnLineTwo and isOpenTagOnLineOne
                    and isOpenTagOffsetAtStart
                    and isCloseOffsetAtEndOfWorld
        end,
    },
    {
        name = "Wide tag marksup full oneliner nested with line break",
        test = function()

            local txt = "bob:<slow>\n<red>Hello World</red></slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Nexted Wide tag with two line breaks",
        test = function()

            -- bob:<slow>
            -- <red>Hello World</red>
            -- </slow>

            local txt = "bob:<slow>\n<red>Hello World</red>\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            PrintCompare(text1, text2)
            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    {
        name = "Nexted Wide tag with line break per tag",
        test = function()

            local txt = "bob:<slow>\n<red>\nHello World\n</red>\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            PrintCompare(text1, "Hellow World")
            PrintCompare(text2, "Hellow World")
            return text1 == "Hello World" and
                  text2 == "Hello World"
        end,
    },
    -- {
    --     name = "Nexted Wide tag with line break per tag and continuing text",
    --     test = function()

    --         local txt = "bob:<slow>\n<red>\nHello\n</red>\n</slow> World"
    --         local tags = {"slow", "red"}

    --         local text1 = GetTextInFirstWideTag(txt, tags, "slow")
    --         local text2 = GetTextInFirstWideTag(txt, tags, "red")

    --         return text1 == "Hello" and
    --               text2 == "Hello"
    --     end,
    -- },
    {
        name = "Nexted Wide tag with continuing text",
        test = function()

            local txt = "bob:<slow><red>Hello</red></slow> World"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello" and
                  text2 == "Hello"
        end,
    },
    {
        name = "Nested Wide tag with double line break per tag",
        test = function()

            local txt = "bob:<slow>\n\n<red>\n\nHello World\n\n</red>\n\n</slow>"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test tricky nested tags",
        test = function()

            --
            -- Bob:Yoyo
            -- <slow>
            --
            -- <red>
            -- Hello World
            -- </red>
            --
            -- </slow> lolo

            --
            -- I'm ok with this being the table
            -- {
            --    "Yoyo",
            --    "Hello World"
            --    "lolo"
            -- }
            --
            --

            local txt = "bob:Yoyo\n<slow>\n\n<red>\n\nHello World\n\n</red>\n\n</slow> lolo"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            printf("<slow>%s</slow><red>%s</red>", text1, text2)
            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test less  tricky nested tags",
        test = function()

            --
            -- Bob:Yoyo
            --
            -- <slow><red>Hello World</red></slow>
            --
            -- lolo

            --
            -- I'm ok with this being the table
            -- {
            --    "Yoyo",
            --    "Hello World"
            --    "lolo"
            -- }
            --
            --

            local txt = "bob:Yoyo\n\n<slow><red>Hello World</red></slow>\n\n lolo"
            local tags = {"slow", "red"}

            local text1 = GetTextInFirstWideTag(txt, tags, "slow")
            local text2 = GetTextInFirstWideTag(txt, tags, "red")

            return text1 == "Hello World" and text2 == "Hello World"
        end,
    },
    {
        name = "Test cut tag gets written into tag table",
        test = function()
            local txt = "bob:<script>Test();</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- PrintTable(firstEntry.tags)

            local hasOpenTag = firstEntry.tags[1].id == "script" and
                                firstEntry.tags[1].op == "open"
            return hasOpenTag
        end,
    },
    {
        name = "Test multi-line cut tag gets written into tag table",
        test = function()
            local txt = "bob:<script>\nif globals['test'] then\n\nTest();\n\nend\n</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- PrintTable(firstEntry.tags)

            local hasOpenTag = firstEntry.tags[1].id == "script" and
                                firstEntry.tags[1].op == "open"
            return hasOpenTag
        end,
    },
    {
        -- This fine but actually has a slightly different error
        name = "Test embedded multi-line cut tag gets written into tag table",
        test = function()
            local txt = "bob:Hello\n<script>\nif globals['test'] then\n\nTest();\n\nend\n</script> World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)
            -- up until here should be a simple macro

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- PrintTable(firstEntry.tags)

            local hasOpenTag = firstEntry.tags[1].id == "script" and
                                firstEntry.tags[1].op == "open"
            return hasOpenTag
        end,
    },
    {
        name = "Test embedded multi-line cut correctly slices lines",
        test = function()
            local txt = "bob:Hello\n<script>\nif globals['test'] then\n\nTest();\n\nend\n</script> World"
            local txtB = "bob:Hello\n World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)
            local treeB, result = DoParse(txtB, tagTable)

            local _, firstEntry = next(tree)
            local _, firstEntryB = next(treeB)


            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline(firstEntry.text[1]),
            --                      EscNewline(firstEntryB.text[1]))
            return firstEntry.text[1] == firstEntryB.text[1]
        end,
    },
    {
        name = "Test inline cut tag at start of line for correct position.",
        test = function()
            local txt = "bob:<script>Test();</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- PrintTable(firstEntry.tags)
            return "Test();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Test inline cut tag at end of line for correct position.",
        test = function()
            local txt = "bob:Hello World<script>Test();</script>"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- PrintTable(firstEntry.tags)
            return "Test();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Test inline cut tag at end of line for correct position with newline.",
        test = function()
            local txt = "bob:Hello World\n<script>Test();</script>"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            return "Test();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Test inline cut tag at inside line for correct position.",
        test = function()
            local txt = "bob:Hello <script>Test();</script>World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            return "Test();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Test inline cut tag at inside line for correct position with newline.",
        test = function()
            local txt = "bob:Hello <script>Test();</script>\nWorld"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            return "Test();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Test inline cut tag at inside line for correct text with newline.",
        test = function()
            local txt = "bob:Hello <script>Test();</script>\nWorld"
            local txtB = "bob:Hello \nWorld"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)
            local treeB, result = DoParse(txtB, tagTable)

            local _, firstEntry = next(tree)
            local _, firstEntryB = next(treeB)

            return firstEntry.text[1] == firstEntryB.text[1]
        end,
    },
    {
        name = "Test inline cut gives correct text.",
        test = function()
            local txt = "bob:Hello <script>Test();</script>World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))
            return "Hello World" == firstEntry.text[1]
        end,
    },
    {
        name = "Normal in game use.",
        test = function()
            local txt = "bob:<script>\nif global['something'] then\n    wizards_key();\nend\n</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))
            return "Hello World" == firstEntry.text[1]
        end,
    },
    {
        name = "Normal in game use, newline script",
        test = function()
            local txt = "bob:\n<script>\nif global['something'] then\n    wizards_key();\nend\n</script>Hello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))
            return "Hello World" == firstEntry.text[1]
        end,
    },
    {
        name = "Normal in game use, newline speech",
        test = function()
            local txt = "bob:<script>\nif global['something'] then\n    wizards_key();\nend\n</script>\nHello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))
            return "Hello World" == firstEntry.text[1]
        end,
    },
    {
        name = "Normal in game use, newline speech, newline script",
        test = function()
            local txt = "bob:\n<script>\nif global['something'] then\n    wizards_key();\nend\n</script>\nHello World"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            if not next(firstEntry.tags or {}) then
                print("Empty tag table")
                return false
            end

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))
            return "Hello World" == firstEntry.text[1]
        end,
    },
    {
        name = "Also normal ingame use",
        test = function()
            local txt = "bob:\nHello\n\nDidn't expect to see you here. <script>DoSomething();</script>"
            local tagTable = { ["script"] = { type = "Cut" }}
            local tree, result = DoParse(txt, tagTable)

            local _, firstEntry = next(tree)

            PrintTable(firstEntry)

            -- printf("A:[%s]\nB:[%s]", EscNewline("Hello World"),
            --                      EscNewline(firstEntryB.text[1]))

            -- The trim on the second line isn't great here but it probably doesn't matter...
            return "DoSomething();" == firstEntry.tags[1].data
        end,
    },
    {
        name = "Wide tag problem from game",
        test = function()
            local txt = "Major:\nSo, in conclusion...<pause>\n\nHead north to the mine.\n\nFind the <red>skull ruby</red>.\n\n"
            local tagTable =
            {
                ["red"] = { type = "Wide" },
                ["pause"] = { type = "Short" }
            }
            local tree, result = DoParse(txt, tagTable)
            local _, firstEntry = next(tree)

            PrintCompare(firstEntry.text[3], "Find the skull ruby.")
            return firstEntry.text[3] == "Find the skull ruby."
        end
    },
    {
        name = "Incorrect game tag placement",
        test = function()
        local txt = "Speaker:\nHello, <pause>\nHere's the <red>Dungeon Key</red>."
        local tagTable =
        {
            ["red"] = { type = "Wide" },
            ["pause"] = { type = "Short"}
        }
        local tree, result = DoParse(txt, tagTable)
        local _, firstEntry = next(tree)


    -- This from the game
    -- F   1   nil
    -- i   2   nil
    -- n   3   nil
    -- d   4   nil
    --     5   nil
    -- t   6   nil
    -- h   7   nil
    -- e   8   nil
    --     9   nil
    -- s   10  color
    -- k   11  color
    -- u   12  color
    -- l   13  color
    -- l   14  color
    --     15  color
    -- r   16  color
    -- u   17  color
    -- b   18  color
    -- y   19  nil
    -- .   20  nil

    -- This is from the test
    -- 1   F
    -- 2   i
    -- 3   n
    -- 4   d
    -- 5
    -- 6   t
    -- 7   h
    -- 8   e
    -- 9
    -- 10  s   *
    -- 11  k
    -- 12  u
    -- 13  l
    -- 14  l
    -- 15
    -- 16  r
    -- 17  u
    -- 18  b
    -- 19  y   *
    -- 20  .

            -- Pretty horribly test that just matches the first and last
            -- characters the tag lands on.
            local matchCount = 1
            local foundD = false
            local foundY = false

            -- Debug print this line)
            for i = 1, #firstEntry.text[1] do

                local tagMark = ""
                for k, v in ipairs(firstEntry.tags) do
                    if (v.offset+1) == i then
                        tagMark = "*"

                        if matchCount == 2 then
                            foundD = (firstEntry.text[1]:sub(i,i) == 'D')
                        elseif matchCount == 3 then
                            foundY = (firstEntry.text[1]:sub(i,i) == 'y')
                        end

                        matchCount = matchCount + 1
                    end
                end

                print(i, firstEntry.text[1]:sub(i,i), tagMark)
            end

            return foundD and foundY
        end
    }


    -- #Cut
    --
    -- Test this:
    -- Bob:
    -- Hello
    --
    -- Didn't expect to see you here. <script>blah</script>

    -- Then let's start using in anger
    -- 1. Color
    -- 2. Pause
    -- 3. Slow / Fast
    -- 4. Visualise cut and short tag positions...? Maybe, if it makes sense

    -- Later:
    -- cut between text boxes, it should be an entry on it's own, without text
    -- A script that's run between textboxes
    -- Double space <some script stuff> double space
    -- In this case maybe the tag itself can check for \n\n before it starts
    -- ^ do this add an annotation "After close"
    -- an annotation or even force the text to change to seomthing like
    --
    -- bob: hello
    -- bob: goodbye
    --
    -- or maybe this would work
    --
    -- script: <script>big ass script</script>


    -- often "tag[ ]*\n[ \n]*" is the correct strip, must contain a newline
    -- really it's the tag alone, or that match
    -- maybe drop through both, left, right, alone tag and see which matches is best
    -- or is that mustn't ...

    -- First up:
    -- Slow text
    -- Fast text
    -- Pause
    -- Color text
    -- Shaking text
    -- Couple of transistions 0 - 2s or whatever
    --    - Fade
    --    - Fade and fall
    --    - Rotate
    --    - Fall and bounce back
    -- Reintegration
}

RunTests(tests)