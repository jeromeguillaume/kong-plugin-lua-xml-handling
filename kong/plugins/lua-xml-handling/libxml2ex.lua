local libxml2ex = {}

require("kong.plugins.lua-xml-handling.libxml2ex.xmlschemas")
require("kong.plugins.lua-xml-handling.libxml2ex.tree")
require("xmlua.libxml2.xmlerror")

local ffi = require("ffi")
local loaded, xml2 = pcall(ffi.load, "xml2")
if not loaded then
  if _G.jit.os == "Windows" then
    xml2 = ffi.load("libxml2-2.dll")
  else
    xml2 = ffi.load("libxml2.so.2")
  end
end

local function __xmlParserVersionIsAvailable()
    local success, err = pcall(function()
        local func = xml2.__xmlParserVersion
    end)
    return success
  end
  

local xmlParserVersion
if __xmlParserVersionIsAvailable() then
  xmlParserVersion = xml2.__xmlParserVersion()[0]
else
  xmlParserVersion = xml2.xmlParserVersion
end

libxml2ex.VERSION = ffi.string(xmlParserVersion)
libxml2ex.XML_SAX2_MAGIC = 0xDEEDBEAF

local function __xmlParserVersionIsAvailable()
  local success, err = pcall(function()
      local func = xml2.__xmlParserVersion
  end)
  return success
end

function libxml2ex.libxml2Version()
    ngx.log(ngx.NOTICE, "*** Begin ***")
    ngx.log(ngx.NOTICE, "xmlParserVersion: " .. ffi.string(xmlParserVersion))
    -- local root
    -- if root == ffi.NULL then
    --    return nil
    -- end
end

function libxml2ex.xmlSchemaNewMemParserCtxt (xsd_schema)
    ngx.log(ngx.NOTICE, "*** Begin ***")
    local xsd_context = xml2.xmlSchemaNewMemParserCtxt(xsd_schema, #xsd_schema)
    
    if xsd_context == ffi.NULL then
        ngx.log(ngx.ERR, "xsd_context is null")
    end

    return xsd_context
end

function libxml2ex.xmlSchemaParse (xsd_context)
    ngx.log(ngx.NOTICE, "*** Begin ***")
    local xsd_schema_doc = xml2.xmlSchemaParse(xsd_context)
    
    if xsd_schema_doc == ffi.NULL then
        ngx.log(ngx.ERR, "xsd_schema_doc is null")
    end

    return xsd_schema_doc
end

function libxml2ex.xmlSchemaNewValidCtxt (xsd_schema_doc)
    ngx.log(ngx.NOTICE, "*** Begin ***")
    local validation_context = xml2.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    if validation_context == ffi.NULL then
        ngx.log(ngx.ERR, "validation_context is null")
    end

    return validation_context
end

function libxml2ex.xmlReadMemory (xml_document, base_url_document, document_encoding, options)
    ngx.log(ngx.NOTICE, "*** Begin ***")
    local xml_doc = xml2.xmlReadMemory (xml_document, #xml_document, base_url_document, document_encoding, options)
    
    if xml_doc == ffi.NULL then
        ngx.log(ngx.ERR, "xml_doc is null")
    end

    return xml_doc
end

-- Validate a document tree in memory.
-- ctxt:	a schema validation context
-- doc:	a parsed document tree
-- Returns:	0 if the document is schemas valid, a positive error code number otherwise and -1 in case of internal or API error.
function libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
  ngx.log(ngx.NOTICE, "*** Begin ***")
  -- xmlSchemaSetValidErrors(valid_ctxt_ptr, (xmlSchemaValidityErrorFunc) err, (xmlSchemaValidityWarningFunc) warn, ctx);
  local is_valid = xml2.xmlSchemaValidateDoc (validation_context, xml_doc)
  return tonumber(is_valid)
end

function libxml2ex.xmlSchemaValidateOneElement	(validation_context, xmlNodePtr)
  ngx.log(ngx.NOTICE, "*** Begin ***")
  local is_valid = xml2.xmlSchemaValidateOneElement (validation_context, xmlNodePtr)
  return tonumber(is_valid)
end

-- Get the last parsing error registered
-- ctx:	an XML parser context
-- Returns:	NULL if no error occurred or a pointer to the error
function libxml2ex.xmlGetLastError ()
  local errMessage = ""
  local xmlError = xml2.xmlGetLastError()
  if xmlError ~= ffi.NULL then
    errMessage =  "Error code: "  .. tonumber(xmlError.code) ..
                  ", Line: "      .. tonumber(xmlError.line) ..
                  ", Message: "   .. ffi.string(xmlError.message)
    -- Reset Error avoiding recovering former errors
    xml2.xmlResetLastError()
  else
    xmlError = nil
  end
  return errMessage, xmlError
end

-- Dump an XML node, recursive behaviour,children are printed too. 
-- Note that @format = 1 provide node indenting only if xmlIndentTreeOutput = 1 or xmlKeepBlanksDefault(0) was called.
-- Since this is using xmlBuffer structures it is limited to 2GB and somehow deprecated, use xmlNodeDumpOutput() instead.
-- buf:	the XML buffer output
-- doc:	the document
-- cur:	the current node
-- level:	the imbrication level for indenting
-- format:	is formatting allowed
-- Returns:	the number of bytes written to the buffer or -1 in case of error

function libxml2ex.xmlNodeDump	(xmlDocPtr, xmlNodePtr, level, format)
  local xmlBuffer = xml2.xmlBufferCreate();
  local errDump = -1
  local xmlDump = ""

  if xmlBuffer ~= ffi.NULL then
    local rc = xml2.xmlNodeDump(xmlBuffer, xmlDocPtr, xmlNodePtr, level, format)
    -- if we succeeded dumping XML
    if tonumber(rc) ~= -1 then
      xmlDump = ffi.string(xmlBuffer.content)
      -- No error
      errDump = 0
    else
      ngx.log(ngx.ERR, "Failed to call 'xmlNodeDump'")
    end
    -- free Buffer
    xml2.xmlBufferFree(xmlBuffer)
    -- ?????
    -- ffi.gc(xml2.xmlBufferCreate(), xml2.xmlBufferFree)
  else
    ngx.log(ngx.ERR, "Failed to call 'xmlBufferCreate'")
  end
  return xmlDump, errDump
end

return libxml2ex