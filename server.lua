--[[
Modified by Andy Reischle

Based on 
XChip's NodeMCU IDE
]]--

srv=net.createServer(net.TCP) 
srv:listen(80, function(conn) 

   local rnrn=0
   local Status = 0
   local responseBytes = 0
   local method=""
   local url=""
   local vars=""

   conn:on("receive",function(conn, payload)
  
    if Status==0 then
        _, _, method, url, vars = string.find(payload, "([A-Z]+) /([^?]*)%??(.*) HTTP")
        -- print(method, url, vars)                          
    end
    
    print("Heap   : " .. node.heap())
    print("Payload: " .. payload)
    print("Method : " .. method)
    print("URL    : " .. url)
    print("Vars   : " .. vars  .. "\n\n\n")


    -- Check if wifi-credentials have been supplied
    if vars~=nil and parse_wifi_credentials(vars) then
        node.restart()
    end

    if url == "favicon.ico" then
        conn:send("HTTP/1.1 404 file not found")
        responseBytes = -1
        return
    end    

    -- Only support one sending one file
    url="index.html"
    responseBytes = 0
	
    conn:send("HTTP/1.1 200 OK\r\n\r\n")
	
  end)
  
  conn:on("sent",function(conn) 
    if responseBytes>=0 and method=="GET" then
        if file.open(url, "r") then            
            file.seek("set", responseBytes)
            local line=file.read(512)
            file.close()
            if line then
                conn:send(line)
                responseBytes = responseBytes + 512    

                if (string.len(line)==512) then
                    return
                end
            end
        end        
    end

    conn:close() 
  end)
end)
print("HTTP Server: Started")


function parse_wifi_credentials(vars)
    if vars == nil or vars == "" then
        return false
    end

    local _, _, node_id = string.find(vars, "node_id\=([^&]+)")
    local _, _, wifi_ssid = string.find(vars, "wifi_ssid\=([^&]+)")
    local _, _, wifi_password = string.find(vars, "wifi_password\=([^&]+)")

    if wifi_ssid == nil or wifi_ssid == "" or wifi_password == nil or node_id == nil or node_id == "" then
        return false
    end

    pwd_len = string.len(wifi_password)
    if pwd_len ~= 0 and (pwd_len < 8 or pwd_len > 64) then
        print("Password length should be between 8 and 64 characters")
        return false
    end

    print("New credentials received")
    print("-----------------------------")
    print("node_id       : " .. node_id)
    print("wifi_ssid     : " .. wifi_ssid)
    print("wifi_password : " .. wifi_password)

    file.open("wifi_credentials", "w+")
    file.writeline(wifi_ssid)
    file.writeline(wifi_password)
    file.writeline(node_id)
    file.flush()
    file.close()
    return true
end
