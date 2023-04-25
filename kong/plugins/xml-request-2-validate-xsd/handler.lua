-- handler.lua
local plugin = {
    PRIORITY = 74,
    VERSION = "1.0.0",
  }

---------------------------------------------------------------------------------------------------
-- Executed for every request from a client and before it is being proxied to the upstream service
---------------------------------------------------------------------------------------------------
function plugin:access(plugin_conf)

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")
  
  -- Enables buffered proxying (due to 'xml-response-1-transform-xslt-before' plugin)
  -- kong.service.request.enable_buffering()
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()
  
  -- If the plugin is defined with XSD SOAP schema
  if plugin_conf.xsdSoapSchema then
    -- Validate the SOAP XML with its schema
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 0, soapEnvelope, plugin_conf.xsdSoapSchema)
    
    if errMessage ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin.PRIORITY,
                                        plugin_conf, 
                                        xmlgeneral.HTTPCodeSOAPFault, 
                                        xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError, 
                                        errMessage)
    end
  end
  
  -- If the plugin is defined with XSD API schema
  if plugin_conf.xsdApiSchema then
  
    -- Validate the API XML (included in the <soap:envelope>) with its schema
    local errMessage = xmlgeneral.XMLValidateWithXSD (plugin_conf, 2, soapEnvelope, plugin_conf.xsdApiSchema)
    
    if errMessage ~= nil then
      -- Return a Fault code to Client
      return xmlgeneral.returnSoapFault (plugin.PRIORITY,
                                        plugin_conf, 
                                        xmlgeneral.HTTPCodeSOAPFault, 
                                        xmlgeneral.RequestTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSDError, 
                                        errMessage)
    end
  end

end

return plugin