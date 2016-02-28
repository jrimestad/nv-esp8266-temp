local dht_pin = 4


local http = require 'http'
local dht = require 'dht'
print("hello, " .. node_id)

function getTemperature()
    status, temp, humi, temp_dec, humi_dec = dht.read(dht_pin)

    if status == dht.OK then
        print("Temp: " .. temp .. " deg C")
        return temp
    elseif status == dht.ERROR_CHECKSUM then
        print( "DHT Checksum error." )
    elseif status == dht.ERROR_TIMEOUT then
        print( "DHT timed out." )
    end
end

function reportSensors()

    temp = getTemperature()
    if temp == nil then
        return
    end

    -- Turn LED on while we send the data
    gpio.write(led_blue, gpio.LOW)

    http.post(
        "http://api.thingspeak.com/update.json",
        "Content-Type: application/json\r\n",
        "{\"api_key\":\"J2JMDOASRENKAN1Y\",\"" .. node_id .. "\":" .. temp .. "}",
        function(code, data)
            if (code >= 0) then
                print("ThingSpeak return: (" .. code .. "):\r\n" .. data)
                gpio.write(led_blue, gpio.HIGH)
            end
        end)
end



-- Enable manual reading using GPIO-7
gpio.mode(7, gpio.INT)
gpio.trig(7, "down", reportSensors)

-- Trigger automatic reading every 60 seconds
tmr.alarm(0, 60*1000, tmr.ALARM_AUTO, reportSensors)

-- Reset this sensor node to default state using GPIO-8
gpio.mode(8, gpio.INT)
gpio.trig(8, "down", function()
    file.remove("wifi_credentials")
    print("Reset complete. Restarting...")
    node.restart()
end)

reportSensors()

