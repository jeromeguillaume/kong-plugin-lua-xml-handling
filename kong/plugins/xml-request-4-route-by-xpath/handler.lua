-- handler.lua
local plugin = {
    PRIORITY = 72,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  -- Get Route By Path and check if the condition is satisfied
  local rcXpath = xmlgeneral.RouteByXPath (kong, soapEnvelope, plugin_conf.XPath, plugin_conf.XPathCondition, plugin_conf.XPathRegisterNs)
  -- If the condition is statsfied we change the Upstream
  if rcXpath then
      kong.service.set_upstream(plugin_conf.RouteToUpstream)
      kong.service.request.set_path(plugin_conf.RouteToPath)
      kong.log.notice("Upstream changed successfully")
  end
end

return plugin