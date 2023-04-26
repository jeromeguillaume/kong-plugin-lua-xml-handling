-- handler.lua
local plugin = {
    PRIORITY = 75,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  -- Apply XLST Transformation
  local soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformBefore)

  if errMessage ~= nil then
    -- Return a Fault code to Client
    return xmlgeneral.returnSoapFault (plugin.PRIORITY,
                                      plugin_conf,
                                      xmlgeneral.HTTPCodeSOAPFault,
                                      xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError,
                                      errMessage)
  end
  
  -- We did a successful XSLT transformation, so we change the body request
  kong.service.request.set_raw_body(soapEnvelope_transformed)

end

return plugin