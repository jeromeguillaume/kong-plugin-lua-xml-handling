-- handler.lua
local plugin = {
    PRIORITY = 50,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  -- Enables buffered proxying (due to 'xml-response-1-transform-xslt-before' plugin)
  -- kong.service.request.enable_buffering()

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  local soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransform)

  if errMessage ~= nil then
    -- Return a Fault code to Client
    return xmlgeneral.returnSoapFault (plugin_conf,
                                      xmlgeneral.HTTPCodeSOAPFault,
                                      xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError,
                                      errMessage)
  end
  
  -- We did a successful XSLT transformation, so we change the body request
  kong.service.request.set_raw_body(soapEnvelope_transformed)

end
--[[
function plugin:header_filter(plugin_conf)
  kong.response.clear_header("Content-Length")
end

function plugin:body_filter(plugin_conf)
  local soapEnvelope = kong.service.response.get_raw_body()
  kong.log.notice("soapEnvelope: " .. soapEnvelope)
  kong.response.set_raw_body("Prout")
end
]]
return plugin