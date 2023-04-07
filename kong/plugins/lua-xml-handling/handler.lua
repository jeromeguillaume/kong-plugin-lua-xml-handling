-- handler.lua
local plugin = {
    PRIORITY = 1,
    VERSION = "0.1",
  }

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function returnSoapFault(plugin_conf, HTTPcode, ErrMsg, ErrEx)
  local soapErrMsg = "\
  <?xml version=\"1.0\" encoding=\"utf-8\"?> \
  <soap:Envelope xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"> \
  <soap:Body> \
    <soap:Fault>\
      <faultcode>soap:Client</faultcode>\
      <faultstring>" .. ErrMsg .. ": " .. ErrEx .. "</faultstring>\
      <detail/>\
    </soap:Fault>\
  </soap:Body>\
</soap:Envelope>\
"
  kong.log.err ("returnSoapFault, soapErrMsg:" .. soapErrMsg)
  return kong.response.exit(400, soapErrMsg, {["Content-Type"] = "text/xml; charset=utf-8"})
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema)
  local ffi         = require("ffi")
  local libxml2jeg  = require("kong.plugins.lua-xml-handling.libxml2ex")
  local libxml2     = require("xmlua.libxml2")
  
  -- Create Parser Context
  local xsd_context = libxml2jeg.xmlSchemaNewMemParserCtxt(XSDSchema)

  -- Create XSD schema
  local xsd_schema_doc = libxml2jeg.xmlSchemaParse(xsd_context)
  
  -- Create Validation context of XSD Schema
  local validation_context = libxml2jeg.xmlSchemaNewValidCtxt(xsd_schema_doc)
  
  -- Load the complete XML document (with <soap:Envelope>)
  local xml_doc = libxml2jeg.xmlReadMemory(XMLtoValidate, nil, nil, 1)
  kong.log.notice ("After xmlReadMemory")
  -- if we have to find the 1st Child of API
  if child ~=0 then
    -- Example:
    -- <soap:Envelope xmlns:xsi=....">
    --    <soap:Body>
    --      <Add xmlns="http://tempuri.org/">
    --        <a>5</a>
    --        <b>7</b>
    --      </Add>
    --    </soap:Body>
    --  </soap:Envelope>
    
    -- Get Root Element, which is <soap:Envelope>
    local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc);
    -- Get Child Element, which is <soap:Body>
    local xmlNodePtrChild  = libxml2.xmlFirstElementChild(xmlNodePtrRoot)
    -- Get WebService Child Element, which is, for instance, <Add xmlns="http://tempuri.org/">
    local xmlNodePtrChildWS = libxml2.xmlFirstElementChild(xmlNodePtrChild)

    -- Dump in a String the WebService part
    kong.log.notice ("XSD validation API part: " .. libxml2jeg.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))

    -- Check validity of One element with its XSD schema
    local is_valid = libxml2jeg.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS)
    
  else
    -- Get Root Element, which is <soap:Envelope>
    local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc);
    kong.log.notice ("XSD validation SOAP part: " .. libxml2jeg.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))

    kong.log.notice ("Before xmlSchemaValidateDoc")
    -- Check validity of XML with its XSD schema
    local is_valid = libxml2jeg.xmlSchemaValidateDoc (validation_context, xml_doc)
  end
  
  
  local errMessage, err = libxml2jeg.xmlGetLastError()
  if err == nil then
    kong.log.notice ("XSD validation of SOAP schema: Ok")
  else
    kong.log.err ("XSD validation of SOAP schema: Ko, " .. errMessage)
  end
  return errMessage, err
end

function plugin:access(plugin_conf)

  local xmldef = require("kong.plugins.lua-xml-handling.xmldef")
  
  -- Get SOAP envelope from the request
  local soapEnvelope = kong.request.get_raw_body()

  -- Validate the SOAP XML with its schema
  local errMessage, err = XMLValidateWithXSD (plugin_conf, 0, soapEnvelope, plugin_conf.xsdSoapSchema)
  if err ~= nil then
    -- Return a Fault code to Client
    return returnSoapFault (plugin_conf, xmldef.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
  end

  -- Validate the API XML (included in the <soap:envelope>) with its schema
  errMessage, err = XMLValidateWithXSD (plugin_conf, 2, soapEnvelope, plugin_conf.xsdApiSchema)
  if err ~= nil then
    -- Return a Fault code to Client
    return returnSoapFault (plugin_conf, xmldef.HTTPCodeSOAPFault, "XSD validation failed", errMessage)
  end

  -- Get <soap:Body> content from entire <soap:Envelope>
  -- 
  -- Example:
  -- <soap:Envelope xmlns:xsi=....">
  --    <soap:Body>
  --      <Add xmlns="http://tempuri.org/">
  --        <a>5</a>
  --        <b>7</b>
  --      </Add>
  --    </soap:Body>
  --  </soap:Envelope>
--[[  
  local xmlNodePtrRoot
  local xmlNodePtrChild
  local xmlNodePtrChildWS
  -- Get Root Element, which is <soap:Envelope>
  xmlNodePtrRoot = libxml2.xmlDocGetRootElement(xml_doc);
  if xmlNodePtrRoot == ffi.NULL then
    kong.log.err ("XSD validation of API schema: Unable to get <soap:Envelope> Root Element")
  else
    -- Get Child Element, which is <soap:Body>
    xmlNodePtrChild = libxml2.xmlFirstElementChild (xmlNodePtrRoot)
    if xmlNodePtrChild == ffi.NULL then
      kong.log.err ("XSD validation of API schema: Unable to get <soap:Body> Child Element")
    else
      xmlNodePtrChildWS = libxml2.xmlFirstElementChild (xmlNodePtrChild)
      -- Get WebService Child Element, which is <Add xmlns="http://tempuri.org/">
      if xmlNodePtrChildWS == ffi.NULL then
        kong.log.err ("XSD validation of API schema: Unable to get WebService Child Element of <soap:Body>")
      else
        kong.log.notice("Dump Root: " .. libxml2jeg.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))
      end
    end
  end
]]--
  -- free memory
  -- xmlSchemaFreeParserCtxt
  -- xmlSchemaFreeValidCtxt
end
  

return plugin