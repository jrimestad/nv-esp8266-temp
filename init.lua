function run_setup()
    wifi.setmode(wifi.SOFTAP)
    cfg={}
    cfg.ssid="SetupNodeSensor-" .. node.flashid()
    wifi.ap.config(cfg)

    print("Opening WiFi credentials portal")
    dofile ("dns-liar.lua")
    dofile ("server.lua")
end

function read_wifi_credentials()
    local wifi_ssid
    local wifi_password
    local node_id

    if file.open("wifi_credentials", "r") then
        wifi_ssid = file.read("\n")
        wifi_ssid = string.format("%s", wifi_ssid:match( "^%s*(.-)%s*$" ))
        wifi_password = file.read("\n")
        wifi_password = string.format("%s", wifi_password:match( "^%s*(.-)%s*$" ))
        node_id = file.read("\n")
        node_id = string.format("%s", node_id:match( "^%s*(.-)%s*$" ))
        file.close()
    end

    if wifi_ssid ~= nil and wifi_ssid ~= "" and wifi_password ~= nil and node_id ~= nil and node_id ~= "" then
        return wifi_ssid, wifi_password, node_id
    end
    return nil, nil, nil
end

blue_on = true
function toggle_blue()
    if blue_on then
        gpio.write(led_blue, gpio.LOW)
    else
        gpio.write(led_blue, gpio.HIGH)
    end

    blue_on = not blue_on
end

function try_connecting(wifi_ssid, wifi_password)
    wifi.setmode(wifi.STATION)
    wifi.sta.config(wifi_ssid, wifi_password)

    tmr.alarm(0, 500, 1, function()
        if wifi.sta.getip()==nil then
          toggle_blue()
          print("Connecting to AP...")
        else
          tmr.stop(1)
          tmr.stop(0)
          print("Connected as: " .. wifi.sta.getip())

          gpio.write(led_red, gpio.HIGH)
          gpio.write(led_blue, gpio.HIGH)

          dofile("main.lua")
        end
    end)

    tmr.alarm(1, 5000, 0, function()
        if wifi.sta.getip()==nil then
            tmr.stop(0)
            print("Failed to connect to \"" .. wifi_ssid .. "\"")
            run_setup()
        end
    end)
end


led_red = 0
led_blue = 4
gpio.mode(led_red, gpio.OUTPUT, gpio.PULLUP)
gpio.mode(led_blue, gpio.OUTPUT, gpio.PULLUP)
gpio.write(led_red, gpio.LOW)
gpio.write(led_blue, gpio.LOW)

wifi_ssid, wifi_password, node_id = read_wifi_credentials()
if wifi_ssid ~= nil and wifi_password ~= nil then
    print("")
    print("Retrieved stored WiFi credentials")
    print("---------------------------------")
    print("wifi_ssid     : " .. wifi_ssid)
    print("wifi_password : " .. wifi_password)
    print("")
    try_connecting(wifi_ssid, wifi_password)
else
    run_setup()
end
