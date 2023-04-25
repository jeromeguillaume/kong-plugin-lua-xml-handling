-- handler.lua
local plugin = {
    PRIORITY = 69,
    VERSION = "1.0.0",
  }

-----------------------------------------------------------------------------------------
-- XSLT TRANSFORMATION - AFTER XSD: Transform the XML response after (XSLT TRANSFORMATION)
-----------------------------------------------------------------------------------------
function plugin:responseXMLhandling(plugin_conf, soapEnvelope)
  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

  local soapEnvelope_transformed
  local soapFaultBody
  
  -- If there is 'XSLT Transformation Before' configuration
  if plugin_conf.xsltTransformAfter then
    -- Apply XSL Transformation (XSLT)
    local errMessage
    soapEnvelope_transformed, errMessage = xmlgeneral.XSLTransform(plugin_conf, soapEnvelope, plugin_conf.xsltTransformAfter)
    
    if errMessage ~= nil then
      -- Format a Fault code to Client
      soapFaultBody = xmlgeneral.formatSoapFault (xmlgeneral.ResponseTextError .. xmlgeneral.SepTextError .. xmlgeneral.XSLTError,
                                                  errMessage)
    end
  else
    soapEnvelope_transformed = soapEnvelope
  end

  return soapEnvelope_transformed, soapFaultBody

end

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:access(plugin_conf)
  
  -- Enables buffered proxying, which allows plugins to access Service body and response headers at the same time
  -- Mandatory calling 'kong.service.response.get_raw_body()' in 'header_filter' phase
  kong.service.request.enable_buffering()

end

-----------------------------------------------------------------------------------------
-- Executed when all response headers bytes have been received from the upstream service
-----------------------------------------------------------------------------------------
function plugin:header_filter(plugin_conf)
  local errMessage
  local soapEnvelope
  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

  -- In case of error set by previous plugin, we don't do anything to avoid an issue.
  -- If we call get_raw_body (), without calling request.enable_buffering(), it will raise an error and 
  -- it happens when a previous plugin called kong.response.exit(): in this case all 'header_filter' and 'body_filter'
  -- are called (and the 'access' is not called which enables the enable_buffering())
  if kong.ctx.shared.xmlSoapHandlingFault and 
     kong.ctx.shared.xmlSoapHandlingFault.error then
    kong.log.notice("A pending error has been set by previous plugin: we do nothing in this plugin")
    return
  end

  -- if kong.response.get_header("Content-Encoding") == "gzip" then
  --  kong.response.clear_header("Content-Encoding")
  -- end

  -- If a previous Response plugin modified the soapEnvelope we retrieve it with 'kong.ctx.shared'
  -- because we are unable to call 'kong.response.get_raw_body' (which is not available in 'header_filter')
  if  kong.ctx.shared.xmlSoapHandlingFault and
      kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope then
    soapEnvelope = kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope    
  -- There is no previous Response plugin
  else
    -- Get SOAP envelope from the Response backend API
    soapEnvelope = kong.service.response.get_raw_body ()
  end
  
  -- There is no SOAP envelope (or Body content) so we don't do anything
  if not soapEnvelope then
    kong.log.notice("The Body is 'nil'")
    return
  else
    -- Apply XSLT (XSL Transformation) After
    local soapEnvelope_transformed, soapFaultBody = plugin:responseXMLhandling (plugin_conf, soapEnvelope)
    
    -- If there is an error during XSLT we change the HTTP staus code and
    -- the Body content (with the detailed error message) will be changed by 'body_filter' phase
    if soapFaultBody ~= nil then
      -- Return a Fault code to Client
      kong.response.set_status(xmlgeneral.HTTPCodeSOAPFault)
      kong.response.set_header("Content-Length", #soapFaultBody)

      -- Set the Global Fault Code to Request and Response XLM/SOAP plugins 
      -- It prevents to apply XML/SOAP handling whereas there is already an error
      kong.ctx.shared.xmlSoapHandlingFault = {
        error = true,
        priority = plugin.PRIORITY,
        soapEnvelope = soapFaultBody
      }
    else
      -- We aren't able to call 'kong.response.set_raw_body()' at this stage to change the body content
      -- but it will be done by 'body_filter' phase
      kong.response.set_header("Content-Length", #soapEnvelope_transformed)

      -- We set the new SOAP Envelope for cascading Plugins because they are not able to retrieve it
      -- by calling 'kong.response.get_raw_body ()' in header_filter
      kong.ctx.shared.xmlSoapHandlingFault = {
        error = false,
        priority = plugin.PRIORITY,
        soapEnvelope = soapEnvelope_transformed
      }

    end
  end
end

------------------------------------------------------------------------------------------------------------------
-- Executed for each chunk of the response body received from the upstream service.
-- Since the response is streamed back to the client, it can exceed the buffer size and be streamed chunk by chunk.
-- This function can be called multiple times
------------------------------------------------------------------------------------------------------------------
function plugin:body_filter(plugin_conf)

  -- If there is a pending error we don't do anything except for the Plugin itself
  if  kong.ctx.shared.xmlSoapHandlingFault        and
      kong.ctx.shared.xmlSoapHandlingFault.error  and 
      kong.ctx.shared.xmlSoapHandlingFault.priority ~= plugin.PRIORITY then
    kong.log.notice("A pending error has been set by previous plugin: we do nothing in this plugin")
    return
  end

  local xmlgeneral = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

  -- Set the modified SOAP envelope
  if  kong.ctx.shared.xmlSoapHandlingFault  and
      kong.ctx.shared.xmlSoapHandlingFault.priority == plugin.PRIORITY then
    
    if kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope then
      kong.response.set_raw_body(kong.ctx.shared.xmlSoapHandlingFault.soapEnvelope)
    end
  end
end

return plugin