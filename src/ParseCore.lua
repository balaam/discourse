if not Asset then
require("HigherOrder")
end

--
-- # Needs a rewrite.
--
-- The original architecture for this didn't really pan out for tags
-- and rather than go back and rethink instead I added on a bunch of hacks
--
-- "Here be dragons"
--

printf = function(...) print(string.format(...)) end -- <- need a util class

StrToArray = function(str)

    local t = {}

    for i = 1, #str do
        local c = str:sub(i,i)
        table.insert(t, c)
    end

    return t

end

ArrayEndsWith = function(a, b)

    local j = 0
    for i = #b, 1, -1 do

        if a[#a - j] ~= b[i] then
            return false
        end
        j = j + 1
    end

    return true

end

eMatch =
{
    Success = "Success",
    Failure = "Failure",
    HaltFailure = "HaltFailure",
    Ongoing = "Ongoing"
}

eTag =
{
    Short = "Short",
    Wide = "Wide",
    Cut = "Cut"
}

eTagState =
{
    Open = "Open",
    Close = "Close"
}

function IsWhiteSpace(byte)
    local whitespace = {' ', '\n', '\t'}
    for k, v in ipairs(whitespace) do
        if v == byte then
            return true
        end
    end

    return false
end

function IsEmptyString(str)

    for i = 1, #str do
        local c = str:sub(i,i)
        if not IsWhiteSpace(c) then
            return false
        end
    end

    return true
end

MaWhiteSpace = {}
MaWhiteSpace.__index = MaWhiteSpace
function MaWhiteSpace:Create(context)
    local this =
    {
        mId = "MaWhiteSpace",
        mName = "Space Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
    }

    setmetatable(this, self)
    return this
end

function MaWhiteSpace:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:AtEnd() then
        self.mError = "Expecting whitespace got end of file"
        self.mState = eMatch.Failure
       return
    end

    if not self.mContext:IsWhiteSpace() then
       local c = tostring(self.mContext:Byte())
       self.mError = "Looking for whitespace but got [" .. c .. "]"
       self.mState = eMatch.Failure
       return
    end

    -- if the next character is non-whitespace, return as success so far
    if self.mContext:PeekAtEnd() or
       not self.mContext:PeekIsWhiteSpace() then
       print("Whitespace sucess")
       self.mState = eMatch.Success
   end
end


MaEnd = {}
MaEnd.__index = MaEnd
function MaEnd:Create(context)
    local this =
    {
        mId = "MaEnd",
        mName = "End Matcher",
        mContext = context,
        mState = eMatch.Ongoing
    }

    setmetatable(this, self)
    return this
end

function MaEnd:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:AtEnd() then
        self.mState = eMatch.Success
    else
        self.mState = eMatch.Failure
    end
end

MaSpeaker = {}
MaSpeaker.__index = MaSpeaker
function MaSpeaker:Create(context)
    local this =
    {
        mId = "MaSpeaker",
        mName = "Speaker Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaSpeaker:GetName()
    return table.concat(self.mAccumulator)
end

function MaSpeaker:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if #self.mAccumulator == 0 then
        local expectedStart = self.mContext.cursor == 1
        or self.mContext:PrevByte() == "\n"

         if not expectedStart then
             self.mError = "Looking for speaker but must start on newline or first line of file."
             self.mState = eMatch.Failure
         end
    end

    if c == "\n" then
        self.mError = "Looking for speaker name but newline."
        self.mState = eMatch.Failure
        return
    end

    if self.mContext:AtEnd() then
        self.mError = "Unexpected end of file while execting speaker name."
        self.mState = eMatch.Failure
        return
    end

    table.insert(self.mAccumulator, c)

    if IsWhiteSpace(self.mAccumulator[1]) then
        self.mError = "Speaker name may not start with whitespace."
        self.mState = eMatch.Failure
        return
    end

    if c == ":" then

        local len = #self.mAccumulator
        if len == 1 then
            self.mError = "Speaker name must be at least one character."
            self.mState = eMatch.Failure
            return
        end

        if IsWhiteSpace(self.mAccumulator[len-1]) then
            self.mError = "Speaker name must not end in whitespace"
            self.mState = eMatch.Failure
            return
        end

        table.remove(self.mAccumulator) -- don't want ':' in the name
        self.mState = eMatch.Success
    end
end

MaSpeechLine = {}
MaSpeechLine.__index = MaSpeechLine
function MaSpeechLine:Create(context)
    local this =
    {
        mId = "MaSpeechLine",
        mName = "Speech Line Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaSpeechLine:GetLine()
    return table.concat(self.mAccumulator)
end

function MaSpeechLine:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if #self.mAccumulator > 0 then
        if c == '\n' or self.mContext:AtEnd()  then
            self.mState = eMatch.Success
            return
        end
    elseif self.mContext:AtEnd() then
        self.mError = "Expected line of speech got end of file."
        self.mState = eMatch.Failure
        return
    end

    table.insert(self.mAccumulator, c)

    if IsWhiteSpace(self.mAccumulator[1]) then
        self.mError = "Speech line may not start with whitespace."
        self.mState = eMatch.Failure
        return
    end
end

MaEmptyLine = {}
MaEmptyLine.__index = MaEmptyLine
function MaEmptyLine:Create(context)
    local this =
    {
        mId = "MaEmptyLine",
        mName = "Empty Speech Line Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {}
    }

    setmetatable(this, self)
    return this
end

function MaEmptyLine:Match()
    if self.mState ~= eMatch.Ongoing then
        return
    end

    if self.mContext:Byte() == '\n' and self.mContext:NextByte() == '\n' or
        self.mContext:Byte() == '\n' and self.mContext:PrevByte() == '\n' then
        self.mState = eMatch.Success
        return
    end

    self.mState = eMatch.Failure
end

-- This is not a standard matcher like the reset
-- It's used after the text has been broken into lines and is
-- full of hacks
MaTag = {}
MaTag.__index = MaTag
function MaTag:Create(context)
    local this =
    {
        mId = "MaTag",
        mName = "Tag Matcher",
        mContext = context,
        mState = eMatch.Ongoing,
        mAccumulator = {},
        mIsOpen = false, -- this for the parser to track where it is.
        mTagType = eTag.Short,
        mTagState = eTagState.Open,
        mIsCut = false,
        mLine = 1
    }

    setmetatable(this, self)
    return this
end

function  MaTag:MovedToNewLine()
    table.insert(self.mAccumulator, '\n')
end

function  MaTag:Reset()
    self.mIsOpen = false
    self.mState = eMatch.Ongoing
    self.mTagType = eTag.Short
    self.mTagState = eTagState.Open
    self.mAccumulator = {}
    self.mIsCut = false
    self.mLine = 1
end

function MaTag:StripTag(str)

    -- Remove outer brackers
    local start = 2
    if self.mTagState == eTagState.Close then
        start = start + 1 -- also strip the /
    end

    return string.sub(str, start, -2)
end

function MaTag:Match()

    if self.mState ~= eMatch.Ongoing then
        return
    end

    local c = self.mContext:Byte()

    if self.mIsCut then

        -- 2. Keep accumulating
        table.insert(self.mAccumulator, c)

        -- 3. Check for close tag if hit close brace
        if c == ">" then

            local endTag = string.format("</%s>", self.mTag)

            local match = ArrayEndsWith(
                self.mAccumulator,
                StrToArray(endTag))

            printf("In end match tag for cut: [%s] for [%s] [%s]", endTag, table.concat(self.mAccumulator), match)

            if match then
                self.mTagFull = table.concat(self.mAccumulator)
                self.mState = eMatch.Success
                self.mTagState = eTagState.Close
                return
            end
            -- else let it run to the end of the file
        end

        -- -- 1. At end? -> let the tag parser feed in the next
        -- if self.mContext:AtEnd() then
        --     print("END! current state: ", self.mState)
        --     self.mError = "Found end of file before close tag."
        --     self.mState = eMatch.HaltFailure
        --     return
        --end
        return
    end

    if self.mIsOpen then
        if c == '\n' then
            self:Reset()
            return
        end

        -- Hacky way to determine closing tags
        if #self.mAccumulator == 1 and c == "/" then
            self.mTagState = eTagState.Close
        end

        if c == '>' then
            self.mIsOpen = false
            if #self.mAccumulator > 1 then

                table.insert(self.mAccumulator, c)
                self.mTagFull = table.concat(self.mAccumulator)


                self.mTag = self:StripTag(self.mTagFull)
                printf("Tag matched [%s] [%s] [%s]", self.mTagFull, self.mTag, self.mTagState)

                local tagDef = self.mContext:GetTag(self.mTag)
                if tagDef then
                    self.mTagType = eTag[tagDef.type]

                    if self.mTagType == eTag.Short and self.mTagState == eTagState.Close then
                        self.mError = string.format("Short tag should never close [%s]", self.mTagFull)
                        self.mState = eMatch.HaltFailure
                        return
                    end

                    if self.mTagType == eTag.Cut then
                        -- Cut means we continue accumulating eveything until
                        -- we hit the matching tag
                        self.mIsOpen = false
                        self.mIsCut = true
                        self.mState = eMatch.Ongoing
                        return
                    end

                else
                    printf("Unknown tag [%s]", self.mTag)
                    PrintTable(self.mContext.tagTable)
                    self.mError = string.format("Unknown tag [%s]", self.mTagFull)
                    self.mState = eMatch.HaltFailure
                    return
                end

                self.mState = eMatch.Success
                return
            else
                self:Reset()
                return
            end
        end
        table.insert(self.mAccumulator, c)
    end

    if self.mContext:AtEnd() then
        self.mError = "Reading tag failed."
        self.mState = eMatch.Failure
        return
    end

    if c == "<" then
        self.mIsOpen = true
        self.mAccumulator = {}
        table.insert(self.mAccumulator, c)
    end

    -- self.mState = eMatch.Failure
end


-- Maybe these blocks have enter and exit functions?
ReaderActions =
{
    START =
    {
        { MaEnd,        "FINISH"      },
        { MaWhiteSpace, "START"       },
        { MaSpeaker,    "SPEECH_UNIT_START" }
    },
    SPEECH_UNIT_START =
    {
        { MaSpeechLine, "SPEECH_UNIT" },
        { MaWhiteSpace, "SPEECH_UNIT_START" },
    },
    SPEECH_UNIT =
    {
        { MaEmptyLine,  "SPEECH_UNIT" },
        { MaSpeaker,    "SPEECH_UNIT_START" },
        { MaSpeechLine, "SPEECH_UNIT" },
        { MaWhiteSpace, "SPEECH_UNIT" },
        { MaEnd,        "FINISH"      },
    },
    NOT_IMPLEMENTED = "NOT_IMPLEMENTED",
    FINISH = "FINISH"
}


function CreateContext(content, tagTable)
    local this =
    {
        content = content,
        cursor = 1,
        line_number = 1,
        column_number = 0,
        syntax_tree = {},
        isError = false,
        tagTable = tagTable or {},

        Byte = function(self)
            return self.content:sub(self.cursor, self.cursor)
        end,

        NextByte = function(self)
            local cursor = self.cursor + 1
            return self.content:sub(cursor, cursor)
        end,

        PrevByte = function(self)
            local cursor = self.cursor - 1
            return self.content:sub(cursor, cursor)
        end,

        AtEnd = function(self)
            return self.cursor > #self.content
        end,


        IsWhiteSpace = function(self)
            return IsWhiteSpace(self:Byte())
        end,

        PeekAtEnd = function(self)
            return (self.cursor + 1) > #self.content
        end,

        PeekIsWhiteSpace = function(self)
            return IsWhiteSpace(self:NextByte())
        end,

        AdvanceCursor = function(self)

            self.cursor = self.cursor + 1
            self.column_number = self.column_number + 1

            if self:Byte() == '\n' then
                self.line_number = self.line_number + 1
                self.column_number = 0
            end

        end,

        OpenSpeech = function(self, speaker)
            table.insert(self.syntax_tree,
            {
                speaker = speaker,
                lineList = {},
                text = ""
            })
        end,

        AddLine = function(self, line)
            local current = self.syntax_tree[#self.syntax_tree]
            table.insert(current.lineList, line)
        end,

        AddLineBreak = function(self)
            self:AddLine('\n')
        end,

        -- CloseAnyOpenTag = function(self)
        --     local current = self.syntax_tree[#self.syntax_tree]

        --     if not current then return end

        --     current.openTag = nil
        -- end,

        GetTag = function(self, id)
            return self.tagTable[id]
        end,

        ProcessTagsInBuffer = function(self, entryList, current)

            current.tags = current.tags or {}

            -- entryList is the list of text entries a person is saying.
            --
            -- Bob:
            -- <slow>Hello there
            --
            -- Mike</slow>
            --
            -- to this:
            --
            -- {
            --     "<slow>Hello there"
            --     "Mike</slow>"
            -- }
            -- Tags may run over lines
            print("processing tags")

            local tagStack = {}
            local push = function(v)
                table.insert(tagStack, v)
            end

            local pop = function(v)
                return table.remove(tagStack)
            end


            local refEntryList = {}
            for k, v in ipairs(entryList) do
                refEntryList[k] = {line = v}
            end

            local maTag
            local killCount = 0
            for index, entry in ipairs(refEntryList) do

                -- iterate through the line char by char
                local lineContext = CreateContext(entry.line, self.tagTable)

                if maTag == nil or maTag.mState ~= eMatch.Ongoing then
                    maTag = MaTag:Create(lineContext)
                else
                    -- Cut tag is reading mulitple lines.
                    maTag.mContext = lineContext
                end

                local doReadLine = maTag.mState == eMatch.Ongoing

                while doReadLine do
                    maTag:Match()
                    lineContext:AdvanceCursor()

                    if maTag.mState == eMatch.HaltFailure then
                        self.isError = true
                        self.errorLines = eMatch.mError
                    elseif maTag.mState == eMatch.Success and maTag.mTagType == eTag.Cut and maTag.mLine > 1 then

                        local m = string.format("^.*</%s>", maTag.mTag)
                        printf("Come to end of cut tag [%s][%s]", m, refEntryList[index].line)
                        printf("Cut tag [%s]", maTag.mTagFull)
                        -- For this line we need to remove everything before the closing tag
                        local lineTxt = string.gsub(refEntryList[index].line, m, "")
                        -- Space trimming, this may need to be a little cleverer, we'll see!
                        -- Trims space ... maybe first line only?

                        if maTag.doJoin and not IsEmptyString(lineTxt) then

                            local lineIndex = maTag.openLine
                            if refEntryList[lineIndex].kill then
                                lineIndex = lineIndex - 1
                            end

                            lineTxt = string.gsub(lineTxt, "^[\n ]+", "")

                            if not IsEmptyString(lineTxt) then
                                refEntryList[lineIndex].line = refEntryList[lineIndex].line .. lineTxt
                            end

                        else
                            refEntryList[index].line = string.gsub(lineTxt , "^[\n ]+", "")

                            if IsEmptyString(refEntryList[index].line) then
                                refEntryList[index].kill = true
                            end
                        end

                        table.insert(current.tags,
                        {
                            line = maTag.openLine,
                            offset = maTag.offset,
                            id = maTag.mTag,
                            op = "open",
                            data = maTag.mTagFull
                        })

                        maTag:Reset()

                    elseif maTag.mState == eMatch.Success then
                        -- printf("Success [%s][%s][%s]", maTag.mTag, maTag.mTagState, EscNewline(maTag.mTagFull) )


                        local isWide = maTag.mTagType == eTag.Wide
                        local isShort = maTag.mTagType == eTag.Short
                        local isCut = maTag.mTagType == eTag.Cut
                        local isOpen = maTag.mTagState == eTagState.Open
                        local isClose = maTag.mTagState == eTagState.Close

                        -- 1. Remove it
                        -- This is all a bit hard coded for now
                        -- Worry about storing this data later
                        local startIndex = 1

                        local openMatch = "[ \n]*%s"

                        if isWide then

                            -- if there are line breaks it's ok to trim,
                            -- otherwise not
                            openMatch = "[\n]*%s[ \n]*"
                        end

                        local tag = string.format(openMatch, maTag.mTagFull)


                        -- 1. b Removing cut tag is special because you want to remove
                        -- the data inbetween and that needs escaping

                        if maTag.mTagType == eTag.Cut then
                            tag = string.format("<%s>.*</%s>", maTag.mTag,
                                                maTag.mTag)

                            -- If the cut tag is on the same line
                            -- then leave the whitespace alone
                            -- If it's over a linebreak the trim the preceeding line

                            if string.find(entry.line, "[ ]*\n" .. tag) or
                             string.find(entry.line, tag .. "\n[ ]*" )then
                                print("NO SPACE BEFORE TAG----------")
                                tag = string.format("[ \n]*<%s>.*</%s>", maTag.mTag, maTag.mTag)
                            end

                        end

                        local i, j = string.find(entry.line, tag, startIndex, false)

                        -- Debug
                        local lineData = "Error tag stripped failed!"
                        if i ~= nil and j ~= nil then
                            lineData = entry.line:sub(i, j)
                        else
                            printf("Looking to strip [%s] from [%s]",
                                  tag,
                                  entry.line)
                        end

                        printf("Tag: i:[%s] j:[%s] lineData:[%s]", i, j, lineData)

                        -- EndDebug

                        local data = ""
                        if maTag.mTagType == eTag.Cut then
                            -- This for what a cut is all on one line
                            -- Need to strip the tags but this ~ok~ for now

                            PrintTable(refEntryList)

                            local source = refEntryList[index].line
                            local tagsM = string.format("<%s>.*</%s>", maTag.mTag, maTag.mTag)
                            local i, j = source:find(tagsM)


                            printf("Stripping data [%s] [%s]", maTag.mTag, source)

                            local triml = #maTag.mTag + 2 -- <>
                            local trimr = #maTag.mTag + 3 -- </>
                            data = source:sub(i + triml, j - trimr)
                        end

                        -- How many new lines in this tag?
                        refEntryList[index].line = refEntryList[index].line:gsub(tag, "", 1)

                        -- Space trimming, this may need to be a little cleverer, we'll see!
                        -- Trims space ... maybe first line only?
                        refEntryList[index].line = string.gsub(refEntryList[index].line , "^[\n ]+", "")

                        -- Gets the line number
                        -- Have to be careful with kill and so on here
                        local line = index
                        if isOpen then
                            line =line - killCount
                        end
                        -- Again if we kill or trim this is going to change
                        local offset = i - 1

                        if IsEmptyString(refEntryList[index].line) then
                            refEntryList[index].kill = true
                            killCount = killCount + 1


                            if isOpen and line > 1 then
                                line = line - 1
                                offset = #refEntryList[line].line
                            end
                        end

                        print("WIDE? ", tag.mTag == eTag.Wide)
                        if (isShort or isWide) and isOpen then

                            table.insert(current.tags,
                            {
                                line = line,
                                offset = offset,
                                id = maTag.mTag,
                                op = "open",
                                data = nil
                            })

                        end

                        -- There's a cut tag that's been opened and closed
                        -- on the first line
                        if isCut and isClose then
                            -- Don't care about pushing and popping because
                            -- cut tags are really just a very long short tag
                            table.insert(current.tags,
                            {
                                line = line,
                                offset = offset,
                                id = maTag.mTag,
                                op = "open", -- no need to put in a close
                                data = data
                            })
                        end

                        if isWide then     -- Was it an opening or a closing tag?
                            if isOpen then
                                push
                                {
                                    name = maTag.mTag,
                                    line = line,
                                    offset = offset
                                }
                            else

                                local top = pop() or {}
                                if top.name ~= maTag.mTag then
                                    self.isError = true
                                    local errorStr = string.format("Unexpected closing tag [%s] expected [%s]",  maTag.mTag, top.name)
                                    print(errorStr)
                                    self.errorLines = errorStr
                                    return
                                end

                                print("Found close tag", line, offset)

                                if offset == 0 then
                                    line = line - 1
                                    offset = (#refEntryList[line].line)
                                end

                                -- Let's add the close tag
                                table.insert(current.tags,
                                {
                                    line = line,
                                    offset = offset - 1,
                                    id = maTag.mTag,
                                    op = "close",
                                    data = nil, -- only cut tags have data
                                })
                            end
                        end

                        maTag:Reset()
                    end



                    if maTag.mTagType == eTag.Cut and
                        maTag.mState == eMatch.Ongoing and
                        lineContext:AtEnd() then

                        PrintTable(refEntryList)
                        -- 1. Remove the start of the tag from the line
                        if maTag.mLine == 1 then

                            -- Change it to <tag>.*
                            -- we're moving on to a newline so everything after the tag
                            -- needs stripping for this line
                            -- <%s>.*
                            maTag.doJoin = false
                            local m = string.format("<%s>.*", maTag.mTag)
                            local i, j = refEntryList[index].line:find(m, 1)
                            maTag.offset = i - 1
                            maTag.openLine = index
                            refEntryList[index].line = refEntryList[index].line:gsub(m, "", 1)
                            refEntryList[index].line = string.gsub(refEntryList[index].line , "^[\n ]+", "")
                            if IsEmptyString(refEntryList[index].line) then
                                refEntryList[index].kill = true
                                -- deciding the offset here is tricker...
                            else
                                print("SETTING JOIN TO TRUEEEEEEEE!!")
                                maTag.doJoin = true
                            end
                        else
                            -- Kill any lines between cut tags
                            refEntryList[index].kill = true
                        end

                        maTag.mLine = maTag.mLine + 1
                        maTag:MovedToNewLine()
                        doReadLine = false
                    else
                        doReadLine = maTag.mState == eMatch.Ongoing
                    end

                end

            end

            entryList = {}
            for k, v in ipairs(refEntryList) do
                if not v.kill then
                    table.insert(entryList, v.line)

                    for i, j in ipairs(current.tags) do
                        if j.op == "close" and j.line == k then
                            j.line = #entryList
                        end
                    end

                else
                    -- Any close tags on this line?
                    -- Move them up!
                    for i, j in ipairs(current.tags) do

                        if j.op == "close" and j.line == k then
                            j.line = #entryList
                            j.offset = (#entryList[#entryList]) - 1
                        end
                        -- end
                    end
                end
            end

            if next(tagStack) then

                self.isError = true
                self.errorLines = string.format("Unclosed tag [%s]",  next(tagStack))
            end

            return entryList
        end,

        CloseAnyOpenSpeech = function(self)
            local current = self.syntax_tree[#self.syntax_tree]

            if not current then return end

            -- self:CloseAnyOpenTag()

            -- Avoid double spaces
            for k, v in ipairs(current.lineList) do
                if v:sub(-1) == " " then
                    current.lineList[k] = current.lineList[k]:sub(1, -2)
                end
            end

            -- Trim trailing newlines
            for i = #current.lineList, 1, -1 do
                local v = current.lineList[i]
                if v == '\n' then
                    table.remove(current.lineList)
                else
                    break
                end
            end

            current.text = {}
            local buffer = ""

            for k, v in ipairs(current.lineList) do

                if buffer == "" or buffer:sub(-1) == '\n' or v:sub(-1) == '\n' then

                    -- Two spaces are a new entry
                    if v == '\n' then

                        if buffer ~= "" then

                            if buffer:sub(-1) == '\n' then
                                buffer = buffer:sub(1, -2)
                            end
                            table.insert(current.text, buffer)
                            buffer = ""
                        end

                    else
                        buffer = buffer .. v
                    end
                else
                    buffer = buffer .. '\n' .. v
                end

            end

            table.insert(current.text, buffer)
            current.text = self:ProcessTagsInBuffer(current.text, current)
            current.lineList = nil

        end
    }
    return this
end

Reader = {}
Reader.__index = Reader
function Reader:Create(matchDef, context)
    local this =
    {
        mMatchList = {},
        mMatchActionList = {},
        mContext = context,
    }

    for k, v in ipairs(matchDef) do
        this.mMatchList[k] = v[1]:Create(context)
        this.mMatchActionList[k] = v[2]
    end

    setmetatable(this, self)
    return this
end

function Reader:GetMatchers()
    return self.mMatchList
end

function Reader:IsFinished()

    if (not next(self:GetMatchers())) or   -- 1. The matcher list is empty
        self:ReadFailed() or            -- 2. All matches have failed -> error
        self:FoundMatch() then          -- 3. One match has passed
        return true
    end

    return false
end

function Reader:ReadFailed()
    local onlyFailsRemain = not Any(self:GetMatchers(),
        function(match)
            local state = match.mState
            return state == eMatch.Ongoing or state == eMatch.Success
        end)

    local haltingFailure = Any(self:GetMatchers(),
                            function(match)
                                return match.mState == eMatch.HaltFailure
                            end)

    return onlyFailsRemain or haltingFailure
end

function Reader:FoundMatch()
    return self:FindMatch() ~= nil
end

function Reader:FindMatch()
      for k, v in ipairs(self:GetMatchers()) do
        local state = v.mState
        if state == eMatch.Success then
            return v
        end
    end
    return nil
end

function Reader:GetMatchAction(match)
    for k, v in ipairs(self:GetMatchers()) do
        if v == match then
            return self.mMatchActionList[k]
        end
    end
    return nil
end

function Reader:Step()
    local context = self.mContext
    for k, v in ipairs(self:GetMatchers()) do
        local result = v:Match()
    end
end

function Reader:GetError()

    local lines = {}

    for k, v in ipairs(self:GetMatchers()) do
        if v.mError ~= nil and v.mError ~= "" then
            table.insert(lines, "Possible error: " .. v.mError)
        end
    end

    return lines
end


function ProcessMatch(match, context)

    if match.mId == "MaSpeaker" then
        context:CloseAnyOpenSpeech()
        local name = match:GetName()
        context:OpenSpeech(name)
        printf("name: [%s]", name)
    elseif match.mId == "MaEmptyLine" then
        context:AddLineBreak()
    elseif match.mId == "MaSpeechLine" then
        local line = match:GetLine()
        context:AddLine(line)
        printf("line: [%s]", line)
    elseif match.mId == "MaEnd" then
        context:CloseAnyOpenSpeech()
    end
end

function DoParse(data, tagTable)

    if data == nil then
        print("No data passed into DoParse")
        return
    end

    local context = CreateContext(data, tagTable)
    local reader = Reader:Create(ReaderActions.START, context)

    while reader ~= nil do
        reader:Step()
        while not reader:IsFinished() do
            context:AdvanceCursor()
            reader:Step()
        end


        if reader:ReadFailed() then
            print("Reader failed")
            context.errorLines = reader:GetError()
            context.isError = true
            reader = nil
        elseif reader:FoundMatch() then
            local match = reader:FindMatch()
            printf("Found match %s", match.mName)
            ProcessMatch(match, context)
            local action = reader:GetMatchAction(match)

            if action == "FINISH" then
                print("Finished read.")
                reader = nil
            elseif action == "NOT_IMPLEMENTED" then
                print("Not implemented, ending here.")
                reader = nil
            else
                reader = Reader:Create(ReaderActions[action], context)
                context:AdvanceCursor()
                print("Reader", action)
            end
        end

    end

    PrintTable(context.syntax_tree)

    return context.syntax_tree,
    {
        isError = context.isError,
        errorLines = context.errorLines,
        lastLine = context.line_number
    }
end