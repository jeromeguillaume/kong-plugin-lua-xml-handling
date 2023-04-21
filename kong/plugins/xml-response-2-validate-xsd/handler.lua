-- handler.lua
local plugin = {
    PRIORITY = 25,
    VERSION = "1.0.0",
  }

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
  
  -- Enables buffered proxying, which allows plugins to access Service body and response headers at the same time
  -- Mandatory calling 'kong.service.response.get_raw_body()' in 'header_filter' phase
  kong.service.request.enable_buffering()
end

------------------------------------------------------------------------------------------------------------------
-- Executed for each chunk of the response body received from the upstream service.
-- Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk.
-- This function can be called multiple times
------------------------------------------------------------------------------------------------------------------
function plugin:body_filter(plugin_conf)

  kong.log.notice("RESPONSE2 - body_filter")
  if kong.response.get_header ("X-Fault-Code") == "on" then
    kong.log.notice("RESPONSE2 - Stop process")
    return
  end

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  kong.log.notice("xml-response-2-validate-xsd, response")  

  -- Get SOAP envelope from the Response
  local soapEnvelope = kong.service.response.get_raw_body ()
  if not soapEnvelope then
    kong.log.notice("'kong.response.get_raw_body()' returns a nil Body")
    return
  end

  -- If the plugin is defined with XSD SOAP schema
  if plugin_conf.xsdSoapSchema then
    -- Validate the SOAP XML with its schema
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelope, plugin_conf.xsdSoapSchema)
    
    if errMessage ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin_conf, xmlgeneral.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
    end
  end
  
  -- If the plugin is defined with XSD API schema
  if plugin_conf.xsdApiSchema then
  
    -- Validate the API XML (included in the <soap:envelope>) with its schema
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 2, soapEnvelope, plugin_conf.xsdApiSchema)
    
    if errMessage ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin_conf, xmlgeneral.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
    end
  end

end
  
return plugin