--
-- Call PrintTable on a table to print a nicely formated lua table to the console.
-- The print table can also be overloaded with a different type of printer to output the table in a new representation
-- like a blob.
--


local TabSize     = 4
local DataType    =
{
    Key         = "Key",
    Value       = "Value",
    ArrayEntry  = "ArrayEntry",
}

DefaultPrinter = {}
--
-- value    -   the current type being written out
-- stack    -   the stack of tables, representing the position in the data structure that the
--              printer is printing.
-- output   -   the table of strings that represents the output (better the basic string concatination)
-- datatype -   the type of value being in, a key, value or array entry.
--              [key]   - an object that points to a value in a table
--              [value] - an object that is indexed by a key object
--              [array entry] -     if keys in a table are consecutive numbers starting from 1 lua
--                                  optimizes the table and the keys are not explicitly stored.
--
function DefaultPrinter:_printType(value, stack, output, dataType)
    if dataType ~= DataType.Value then
        table.insert(output, string.rep(" ", #stack * TabSize))
    end

    if dataType == DataType.Key then
        table.insert(output, string.format("[%s]", tostring(value)))
    else
        table.insert(output, tostring(value))
        table.insert(output, ",\n")
    end
end

DefaultPrinter.number       = DefaultPrinter._printType
DefaultPrinter['function']  = DefaultPrinter._printType
DefaultPrinter.boolean      = DefaultPrinter._printType
DefaultPrinter.thread       = DefaultPrinter._printType

function DefaultPrinter:string(str, ...)
    self:_printType(string.format('%q', str), ...)
end

function DefaultPrinter:userdata(value, stack, output, dataType)
    -- An extra look up will be needed here using Type instead of type
    self:_printType(value, stack, output, dataType)
end

function DefaultPrinter:OpenTable(t, stack, output, dataType)

    if not next(t) then
        -- Empty table
        if dataType ~= DataType.Value then
            table.insert(output, string.rep(" ", #stack * TabSize))
        end

        if dataType == DataType.Key then
            table.insert(output, "[{")
        else
            table.insert(output, "{")
        end
        return
    end

    if dataType == DataType.Value then
        table.insert(output, "\n")
    end
    table.insert(output, string.rep(" ", #stack * TabSize))
    if dataType == DataType.Key then
        table.insert(output, "[")
    end
    table.insert(output, "{\n")
end

function DefaultPrinter:CloseTable(t, stack, output, dataType)
    if next(t) then
        table.insert(output, string.rep(" ", #stack * TabSize))
    end
    table.insert(output, "}")
    if dataType == DataType.Key then
        table.insert(output, "]")
    else
        table.insert(output, ",\n")
    end
end

function DefaultPrinter:KeyPairAssign(output)
    table.insert(output, " = ")
end

function DefaultPrinter:HitLoop(t, stack, output, dataType)
    table.insert(output, "[LOOP]\n")
end


function IterTable(t, stack, output, dataType, printer)

    local _stack    = stack or {}
    local _data     = output or {}
    local _dataType = dataType or DataType.Value
    local _printer  = printer or DefaultPrinter
    _printer.table  = function(self, ...) IterTable(...) end

    -- Do a check for recursion
    for _, v in ipairs(_stack) do
        if v == t then
            _printer:HitLoop(v, _stack, _data, DataType.ArrayEntry, _printer)
            return
        end
    end

    _printer:OpenTable(t, _stack, _data, _dataType)
    -- Push table to visited-stack
    table.insert(_stack, t)

    local _ipairsKey = {}
    for k, v in ipairs(t) do
        _ipairsKey[k] = v
        _printer[type(v)](_printer, v, _stack, _data, DataType.ArrayEntry, _printer)
    end

    for k, v in pairs(t) do
        if _ipairsKey[k] ~= v then
            _printer[type(k)](_printer, k, _stack, _data, DataType.Key, _printer)
            _printer:KeyPairAssign(_data)
            _printer[type(v)](_printer, v, _stack, _data, DataType.Value, _printer)
        end
    end

    table.remove(_stack)
    _printer:CloseTable(t, _stack, _data, _dataType)

    if not next(_stack) then
        return table.concat(_data)
    end
end

function PrintTable(t)
    print(IterTable(t, nil, nil, DefaultPrinter))
end

--PrintTable({{},{{}},{{},{},{}}})