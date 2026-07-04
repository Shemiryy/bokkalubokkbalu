-- printbook.lua
-- Prints a text file as a ComputerCraft printed book.
--
-- Usage:
--   printbook <filename> [title]
--
-- Printer requirements:
--   - Paper
--   - Ink
--   - String (to make a printed book)

local WIDTH = 25
local HEIGHT = 21

local args = { ... }

if #args < 1 then
    print("Usage: printbook <filename> [title]")
    return
end

local filename = args[1]
local title = args[2] or "Printed Book"

local printer = peripheral.find("printer")
if not printer then
    error("No printer found.")
end

local file = fs.open(filename, "r")
if not file then
    error("Cannot open file: " .. filename)
end

-- Read the entire file
local text = file.readAll()
file.close()

-- Normalize line endings
text = text:gsub("\r\n", "\n")

local lines = {}

-- Wrap a paragraph into WIDTH-character lines.
local function wrapParagraph(paragraph)
    if paragraph == "" then
        table.insert(lines, "")
        return
    end

    local current = ""

    for word in paragraph:gmatch("%S+") do
        if #word > WIDTH then
            if current ~= "" then
                table.insert(lines, current)
                current = ""
            end

            local i = 1
            while i <= #word do
                table.insert(lines, word:sub(i, i + WIDTH - 1))
                i = i + WIDTH
            end
        else
            if current == "" then
                current = word
            elseif #current + 1 + #word <= WIDTH then
                current = current .. " " .. word
            else
                table.insert(lines, current)
                current = word
            end
        end
    end

    if current ~= "" then
        table.insert(lines, current)
    end
end

-- Preserve blank lines.
for paragraph in (text .. "\n"):gmatch("(.-)\n") do
    wrapParagraph(paragraph)
end

local lineIndex = 1
local firstPage = true

while lineIndex <= #lines do
    while not printer.newPage() do
        print("Printer needs paper and ink.")
        print("Press Enter once refilled.")
        read()
    end

    if firstPage then
        printer.setPageTitle(title)
        firstPage = false
    end

    for y = 1, HEIGHT do
        if lineIndex > #lines then
            break
        end

        printer.setCursorPos(1, y)
        printer.write(lines[lineIndex])
        lineIndex = lineIndex + 1
    end

    printer.endPage()
end

print("Done!")
