local toml = require("toml")
local f = fs.open("/etc/repo.toml","r")
local repos = toml.decode(f.readAll())
f.close()
local args = {...}
local cmd = args[1]
local function sync()
    local pkgs = {}
    print("sync",textutils.serialise(repos))
    for key, value in pairs(repos) do
        print(key,value.url)
        local r = http.get(value.url.."packs.toml")
        local pk = toml.decode(r.readAll())
        for k, v in pairs(pk) do
            if v.location == "local" then
                v.url = value.url..k..".toml"
            end
            local R = http.get(v.url)
            local pak = toml.decode(R.readAll())
            if not pkgs[key.."."..k] then
                pkgs[key.."."..k] = pak.package
            end
            if not pkgs[k] then
                pkgs[k] = pak.package
            end
        end
    end
    local f = fs.open("/var/cyclone/pkgs.toml","wb")
    f.write(toml.encode(pkgs))
    f.close()
end
local function add()
    local f = fs.open("/etc/repo.toml","w")
    repos[args[2]] = {url=args[3]}
    f.write(toml.encode(repos))
    f.close()
end
local function install()
    local f = fs.open("/var/cyclone/pkgs.toml","r")
    local pkgs = toml.decode(f.readAll())
    f.close()
    local pk = pkgs[args[2]]
    print(pk.addr)
    local fa = fs.open("/usr/"..pk.type.."/"..args[2]..".lua","w")
    local R = http.get(pk.addr)
    fa.write(R.readAll())
    fa.close()

end
if cmd == "-S" then
    sync()
elseif cmd == "-A" then
    add()
elseif cmd == "-I" then
    install()
else
    printWarning("Invalid Command")
end
