-- handler.lua
local plugin = {
    PRIORITY = 45,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()
  
  -- If the plugin is defined with XSD SOAP schema
  if plugin_conf.xsdSoapSchema then
    -- Get SOAP envelope from the request
    local soapEnvelope = kong.request.get_raw_body()
    -- Validate the SOAP XML with its schema
    local errMessage, err = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelope, plugin_conf.xsdSoapSchema)
    
    if err ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin_conf, xmlgeneral.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
    end
  end
  
  -- If the plugin is defined with XSD API schema
  --[[if plugin_conf.xsdApiSchema then
  
    -- Validate the API XML (included in the <soap:envelope>) with its schema
    local errMessage, err = xmlgeneral.XMLValidateWithXSD (plugin_conf, 2, soapEnvelope, plugin_conf.xsdApiSchema)
    if err ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin_conf, xmlgeneral.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
    end
  end
]]
end

return plugin