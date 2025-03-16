-- preparedpiano

---@diagnostic disable: undefined-global, lowercase-global, duplicate-set-field

SCRIPT_NAME = "preparedpiano"
local _grid = include 'lib/_grid'
local _dm = include 'device_manager/lib/_device_manager' -- install from https://github.com/illges/device_manager
local _pacifist = include 'pacifist_dev/lib/_pacifist' -- install from https://github.com/illges/pacifist_dev
local _key = include 'lib/key'

engine.name = 'PolyPerc'

pianokeys = {}
keystates = {}
message_count = 0
local PLAY=0; local CONFIGURE=1
mode = PLAY
focus = nil


function init()
    message = SCRIPT_NAME
    dm = _dm.new({adv=false, debug=true})
    mft = _pacifist:new({devices=dm.devices, debug=false})
    g=_grid:new()

    for i=1,127 do
        table.insert(pianokeys, _key.new(i))
        table.insert(keystates, 0)
    end

    screen_dirty = true
    grid_dirty = true
    screen_redraw_clock()
    grid_redraw_clock()
end

function screen_redraw_clock()
    screen_drawing=metro.init()
    screen_drawing.time=0.1
    screen_drawing.count=-1
    screen_drawing.event=function()
        if message_count>0 then
            message_count=message_count-1
        else
            message = SCRIPT_NAME
            screen_dirty = true
            focus = nil
        end
        if screen_dirty == true then
            redraw()
            screen_dirty = false
        end
    end
    screen_drawing:start()
end

function set_message(msg, count)
    message = msg
    message_count = count and count or 20
    screen_dirty = true
    grid_dirty=true
end

function grid_redraw_clock()
    grid_drawing=metro.init()
    grid_drawing.time=0.1
    grid_drawing.count=-1
    grid_drawing.event=function()
        mft:activity_countdown()
        if grid_dirty == true then
            g:grid_redraw()
            redraw_mft()
            grid_dirty = false
        end
    end
    grid_drawing:start()
end

function enc(e, d)
    turn(e, d)
    if e == 1 then
    elseif e == 2 then
        pianokeys[focus]:delta_ch(d)
    elseif e == 3 then
        pianokeys[focus]:delta_div(d)
    end
    screen_dirty = true
end

function turn(e, d)
    set_message("encoder " .. e .. ", delta " .. d)
end

function key(k, z)
    if z == 0 then return end
    press_down(k)
    if k == 2 then
        mode = 1 - mode
    elseif k ==3 then
        mode = 1 - mode
    end
    screen_dirty = true
end

function press_down(i)
    set_message("press down " .. i)
end

function redraw()
    screen.clear()
    screen.aa(1)
    screen.font_face(1)
    screen.font_size(8)
    screen.level(15)
    screen.move(64, 5)
    screen.text_center((mode==PLAY and "PLAY" or "CONFIGURE").." mode")
    if focus==nil then
        screen.level(15)
        screen.move(64, 32)
        screen.text_center(message)
        screen.pixel(0, 0)
        screen.pixel(127, 0)
        screen.pixel(127, 63)
        screen.pixel(0, 63)
    else
        pianokeys[focus]:redraw()
    end
    screen.fill()
        screen.update()
end

function redraw_mft()
    --mft:all(0)
    for i=1,16 do
        mft:led(i, mft.color[i]) --color is optional
        mft:send(i, mft.ind[i])
    end
end

function mft_enc(n,d)
    set_message("mft enc "..n.." turned")
    mft.last_turned = n
    mft.enc_activity_count = 15
    mft.activity_count = 15
    mft:delta_color(n,d)
    if n<9 then
        mft.ind[n] = util.clamp(mft.ind[n]+d,0,127)
    else
        mft.ind[n] = util.wrap(mft.ind[n]+d,0,127)
    end
    screen_dirty = true
    grid_dirty=true
end

function mft_key(n,z)
    local on = z==1
    mft.momentary[n] = on and 1 or 0
    if on then
        set_message("mft key "..n.." pressed")
        mft.last_pressed = n
        mft.key_activity_count = 15
        mft.activity_count = 15
        if n>=1 and n<=4 then
            mft:set_color(n,64)
        elseif n>=5 and n<=8 then
            mft:toggle_color(n,1,64)
        elseif n>=9 and n<=16 then
            mft:delta_color(n,10)
        elseif n==17 then
        elseif n==18 then
        elseif n==19 then
        elseif n==20 then
        elseif n==21 then
        elseif n==22 then
        end
    else
        if n>=1 and n<=4 then
            mft:toggle_color(n,1)
        end
    end
    screen_dirty = true
    grid_dirty=true
end

function midi_event_note_on(d)
    keystates[d.note] = 1
    focus = d.note
    if mode==PLAY then
        set_message(pianokeys[d.note].message)
        pianokeys[d.note].clock_id = clock.run(arp, d, pianokeys[d.note])
        --play_note(d)
    end
end

function midi_event_note_off(d)
    keystates[d.note] = 0
    local key = pianokeys[d.note]
    if mode==PLAY then
        if key.clock_id ~= nil then clock.cancel(key.clock_id) end
        dm:device_out():note_off(key.note, key.vel, key.ch)
    end
end

function play_note(d)
    dm:device_out():note_on(d.note, 75, d.ch)
end

function arp(d, key)
    for i=1,key.fb do
        --dm:device_out():note_on(key.note, key.vel, key.ch)
        play_note_clocked(d, key)
        clock.sleep(clock.get_beat_sec()/key.rep_div*4)
    end
end

function play_note_clocked(d, key)
    dm:device_out():note_on(key.note, key.vel, key.ch)
    clock.run(
        function()
            clock.sleep(0.1)
            dm:device_out():note_off(key.note, key.vel, key.ch)
        end
    )
end

function midi_event_start(d) end

function midi_event_stop(d) end

function midi_event_cc(d) end

function r() ----------------------------- execute r() in the repl to quickly rerun this script
    norns.script.load(norns.state.script) -- https://github.com/monome/norns/blob/main/lua/core/state.lua
end

function cleanup() --------------- cleanup() is automatically called on script close

end