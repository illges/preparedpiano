---@diagnostic disable: undefined-global, lowercase-global

local key = {}
key.__index = key

function key.new(n)
    local self = setmetatable({}, key)
    self.note = n
    self.name = "" -- gtodo
    self.freq = n -- todo
    self.message = "piano key "..self.note.." pressed"
    self.clock_id = nil

    self.vel = 75
    self.ch = 1
    self.fb = 24
    self.rep_div = 4
    return self
end

function key:delta_div(d)
    self.rep_div = util.clamp(self.rep_div+d,1,128)
end

function key:delta_ch(d)
    self.ch = util.clamp(self.ch+d,1,16)
end

function key:redraw()
    screen.level(15)
    screen.move(64, 25)
    screen.text_center(self.message)
    screen.move(64, 35)
    screen.text_center("div: "..self.rep_div)
    screen.move(64, 45)
    screen.text_center("ch: "..self.ch)
end

function key:print()
    print("piano key "..self.note.." pressed")
end

return key