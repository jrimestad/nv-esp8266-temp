local http = require 'http'
print("hello, " .. node_id)

function getTemperature()
    local id = 0
    local sda = 2
    local scl = 1
    return dofile("tmp102.lua").read(id, sda, scl)
end

function dweetSensors()
    gpio.write(led_blue, gpio.LOW)

    http.post(
        "http://dweet.io/dweet/for/" .. node_id,
        'Content-Type: application/json\r\n',
        "{\"flashid\":" .. node.flashid() .. ", \"temp_f\":" .. getTemperature() .. "}",
        function(code, data) 
            if (code >= 0) then
                print("dweet return (" .. code .. "):\r\n" .. data)
                gpio.write(led_blue, gpio.HIGH)
            end
        end)
end

gpio.mode(7, gpio.INT)
gpio.trig(7, "down", dweetSensors)

tmr.alarm(0, 60*1000, tmr.ALARM_AUTO, dweetSensors)

gpio.mode(8, gpio.INT)
gpio.trig(8, "down", function()
    file.remove("wifi_credentials")
    print("Reset complete. Restarting...")
    node.restart()
end)

dweetSensors()

