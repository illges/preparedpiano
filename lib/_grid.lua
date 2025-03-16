---@diagnostic disable: undefined-global, lowercase-global

local _grid = {}

function _grid:new(args)
    local self=setmetatable({},{
      __index=_grid
    })
    local args=args==nil and {} or args

    self.g=grid.connect()
    self.g.key=function(x,y,z)
      self:grid_key(x,y,z)
    end

    self.momentary = self:init_grid_momentary()
    self.visual = self:init_grid_visual()
    
    return self
end

function _grid:init_grid_momentary()
  local momentary = {}
  for x = 1,16 do -- for each x-column (16 on a 128-sized grid)...
      momentary[x] = {} -- create a table that holds...
      for y = 1,8 do -- each y-row (8 on a 128-sized grid)!
        momentary[x][y] = 0 -- the state of each key is 'off'
      end
  end
  return momentary
end

function _grid:init_grid_visual()
  local visual={}
  for x=1,16 do
      visual[x]={}
      for y=1,8 do
          visual[x][y]=0
      end
  end
  return visual
end

function _grid:grid_key(x,y,z)
    local on = z==1
    self.momentary[x][y] = on and 1 or 0

    if on then
      set_message('grid ('..x..','..y..") : ON")
    else
      set_message('grid ('..x..','..y..") : OFF", 4)
    end

    screen_dirty = true
    grid_dirty = true
end

function _grid:get_grid_visuals()
  for x=1,16 do
    for y=1,8 do
      -- visual[x][y]=visual[x][y]-2
      -- if visual[x][y]<0 then
      --     visual[x][y]=0
      -- end
      self.visual[x][y]=0
    end
  end

  for x = 1,16 do
    for y = 1,8 do
      if self.momentary[x][y] == 1 then self.visual[x][y] = 15 end
    end
  end
end

function _grid:grid_redraw()
  self:get_grid_visuals()
  self.g:all(0)
  for x=1,16 do
      for y=1,8 do
          if self.visual[x][y]~=0 then
            self.g:led(x,y,self.visual[x][y])
          end
      end
  end
  self.g:refresh()
end

return _grid
