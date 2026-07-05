
-- reader.lua
-- Simple ComputerCraft e-reader (browser + reader)

local mon = peripheral.find("monitor")
if mon then term.redirect(mon) mon.setTextScale(0.5) end

local function mount()
  for _,s in ipairs(rs.getSides()) do
    if disk.isPresent(s) then return disk.getMountPath(s), disk.getLabel(s) or "Disk" end
  end
  if fs.exists("disk") then return "disk","Disk" end
  return nil,nil
end

local function wrap(text,w)
  local out={}
  for line in (text.."\n"):gmatch("(.-)\n") do
    if line=="" then table.insert(out,"")
    else
      local cur=""
      for word in line:gmatch("%S+") do
        if cur=="" then cur=word
        elseif #cur+#word+1<=w then cur=cur.." "..word
        else table.insert(out,cur) cur=word end
      end
      if cur~="" then table.insert(out,cur) end
    end
  end
  return out
end

local function browser(root,label)
  local cwd=root
  local sel=1
  while true do
    local entries=fs.list(cwd)
    table.sort(entries,function(a,b)
      local da,db=fs.isDir(fs.combine(cwd,a)),fs.isDir(fs.combine(cwd,b))
      if da~=db then return da end
      return a:lower()<b:lower()
    end)
    local w,h=term.getSize()
    term.clear() term.setCursorPos(1,1)
    print(label)
    print(cwd:sub(#root+1)=="" and "/" or cwd:sub(#root+1))
    for i=1,math.min(#entries,h-3) do
      if i==sel then write(">") else write(" ") end
      local e=entries[i]
      if fs.isDir(fs.combine(cwd,e)) then print("["..e.."]") else print(e) end
    end
    local ev,k=os.pullEvent()
    if ev=="key" then
      if k==keys.up then sel=math.max(1,sel-1)
      elseif k==keys.down then sel=math.min(#entries,sel+1)
      elseif k==keys.backspace then
        if cwd~=root then cwd=fs.getDir(cwd) sel=1 end
      elseif k==keys.enter and entries[sel] then
        local p=fs.combine(cwd,entries[sel])
        if fs.isDir(p) then cwd=p sel=1
        else
          local f=fs.open(p,"r")
          local txt=f.readAll() f.close()
          local lines=wrap(txt,w)
          local top=1
          while true do
            term.clear() term.setCursorPos(1,1)
            print(entries[sel])
            for i=1,h-2 do
              term.setCursorPos(1,i+1)
              write(lines[top+i-1] or "")
            end
            term.setCursorPos(1,h)
            write(("Line %d/%d"):format(top,#lines))
            local e2,k2=os.pullEvent()
            if e2=="key" then
              if k2==keys.down then top=math.min(#lines,top+1)
              elseif k2==keys.up then top=math.max(1,top-1)
              elseif k2==keys.pageDown then top=math.min(#lines,top+h-2)
              elseif k2==keys.pageUp then top=math.max(1,top-(h-2))
              elseif k2==keys.home then top=1
              elseif k2==keys["end"] then top=math.max(1,#lines-h+2)
              elseif k2==keys.backspace then break end
            elseif e2=="disk_eject" then return end
          end
        end
      end
    elseif ev=="disk_eject" then return
    end
  end
end

while true do
  local path,label=mount()
  if not path then
    term.clear() term.setCursorPos(1,1)
    print("Insert floppy disk...")
    local e=os.pullEvent()
    if e=="disk" then
    end
  else
    browser(path,label)
  end
end
