-- handler.lua
local plugin = {
    PRIORITY = 50,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  local soapEnvelope_transformed, errMessage, err = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransform)

  if err ~= nil then
    -- Return a Fault code to Client
    return xmlgeneral.returnSoapFault (plugin_conf, xmlgeneral.HTTPCodeSOAPFault, "XSLT transformation failed", errMessage)
  end
  
  -- We did a successful XSLT transformation, so we change the body request
  kong.service.request.set_raw_body(soapEnvelope_transformed)

end
  

return plugin