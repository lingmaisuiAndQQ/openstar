
local config = {}
local cjson_safe = require "cjson.safe"

--- config.json 文件绝对路径 [需要自行根据自己服务器情况设置]
local config_json = "/opt/openresty/openstar/base.json"

--- 将全局配置参数存放到共享内存（config_dict）中
local config_dict = ngx.shared.config_dict
local host_dict = ngx.shared.host_dict

--- 读取文件（全部读取）
--- loadjson()调用
local function readfile(_filepath)
    -- local fd = assert(io.open(_filepath,"r"),"readfile io.open error")
    local fd = io.open(_filepath,"r")
    if fd == nil then return end
    local str = fd:read("*a") --- 全部内容读取
    fd:close()
    return str
end

--- 载入JSON文件
--- loadConfig()调用
local function loadjson(_path_name)
	local x = readfile(_path_name)
	local json = cjson_safe.decode(x) or {}
	return json
end

--- 载入config.json全局基础配置
--- 唯一一个全局函数
function loadConfig()

	config.base = loadjson(config_json)
	local _basedir = config.base.jsonPath or "./"
	
	config.realIpFrom_Mod = loadjson(_basedir.."realIpFrom_Mod.json")
	--config.ip_Mod = loadjson(_basedir.."ip_Mod.json")
	config.host_method_Mod = loadjson(_basedir.."host_method_Mod.json")
	config.rewrite_Mod = loadjson(_basedir.."rewrite_Mod.json")
	config.app_Mod = loadjson(_basedir.."app_Mod.json")
	config.referer_Mod = loadjson(_basedir.."referer_Mod.json")
	config.url_Mod = loadjson(_basedir.."url_Mod.json")
	config.header_Mod = loadjson(_basedir.."header_Mod.json")
	config.useragent_Mod = loadjson(_basedir.."useragent_Mod.json")	
	config.cookie_Mod = loadjson(_basedir.."cookie_Mod.json")
	config.args_Mod = loadjson(_basedir.."args_Mod.json")
	config.post_Mod = loadjson(_basedir.."post_Mod.json")
	config.network_Mod = loadjson(_basedir.."network_Mod.json")
	config.replace_Mod = loadjson(_basedir.."replace_Mod.json")
	--- 2016年8月30日增加 denyHost_Mod
	if config.base.sayHtml.state == "on" then
		config.denyHost_Mod = loadjson(_basedir.."denyHost_Mod.json")
	end
	
	for k,v in pairs(config) do
		v = cjson_safe.encode(v)
		config_dict:safe_set(k,v,0)
	end

	--- 将ip_mod放入 ip_dict 中
	if config.base["ip_Mod"] == "on" then
		local tb_ip_mod = loadjson(_basedir.."ip_Mod.json")
		local _dict = ngx.shared["ip_dict"]
		for i,v in ipairs(tb_ip_mod) do
			if v.action == "allow" then
				_dict:safe_set(v.ip,"allow",0)
				--- key 存在会覆盖 lru算法关闭
			elseif v.action == "deny" then
				_dict:safe_set(v.ip,"deny",0)
			else
				_dict:safe_set(v.ip,"log",0)
			end
		end
	end

	--- 读取host规则json 到host_dict
	local host_tb = loadjson(_basedir.."hostJson.json")
	for i,v in ipairs(host_tb) do
		local host,state = v[1],v[2] or "off"
		if host ~= nil then
			host_dict:safe_set(host,state,0)
			local tmp = loadjson(_basedir.."host_json/"..host..".json")
			tmp = cjson_safe.encode(tmp)
			host_dict:safe_set(host.."_HostMod",tmp,0)
		end
	end

end

loadConfig()
