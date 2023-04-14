-- handler.lua
local plugin = {
    PRIORITY = 35,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  local attribute = xmlgeneral.RouteByXPath (kong, soapEnvelope, plugin_conf.XPath, plugin_conf.XPathCondition)

  --kong.log.notice("RouteByXPath: " .. attribute)
end
  

return plugin