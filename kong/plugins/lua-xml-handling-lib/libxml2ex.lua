local libxml2ex = {}

require("kong.plugins.lua-xml-handling-lib.libxml2ex.xmlschemas")
require("kong.plugins.lua-xml-handling-lib.libxml2ex.tree")
require("kong.plugins.lua-xml-handling-lib.libxml2ex.xmlerror")
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
    return ffi.string(xmlParserVersion)
end

function libxml2ex.xmlSchemaNewMemParserCtxt (xsd_schema)
    local xsd_context = xml2.xmlSchemaNewMemParserCtxt(xsd_schema, #xsd_schema)
    
    if xsd_context == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaNewMemParserCtxt returns null")
    end
    
    return xsd_context
end

function libxml2ex.xmlSchemaParse (xsd_context)
    local validation_error = ""
    local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, error)
      ngx.log(ngx.ERR, "JEG xmlSchemaParse")
      validation_error = ffi.string(error['message'])
    end)
    -- xml2.xmlSetStructuredErrorFunc(xsd_context, error_handler)
    
    local xsd_schema_doc = xml2.xmlSchemaParse(xsd_context)

    if xsd_schema_doc == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaParse returns null")
    end
    
    error_handler:free()

    return xsd_schema_doc, validation_error
end

function libxml2ex.xmlSchemaNewValidCtxt (xsd_schema_doc)
    local validation_context = xml2.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    if validation_context == ffi.NULL then
        ngx.log(ngx.ERR, "xmlSchemaNewValidCtxt returns null")
    end

    return validation_context
end

-- Parse an XML in-memory document and build a tree.
-- buffer:	a pointer to a char array
-- size:	the size of the array
-- URL:	the base URL to use for the document
-- encoding:	the document encoding, or NULL
-- options:	a combination of xmlParserOption
-- Returns:	the resulting document tree
function libxml2ex.xmlReadMemory (xml_document, base_url_document, document_encoding, options)
  local libxml2 = require("xmlua.libxml2")  
  local xml_doc = xml2.xmlReadMemory (xml_document, #xml_document, base_url_document, document_encoding, options)
    
    if xml_doc == ffi.NULL then
        ngx.log(ngx.ERR, "xmlReadMemory returns null")
    end

    return ffi.gc(xml_doc, libxml2.xmlFreeDoc)
end

-- Validate a document tree in memory.
-- ctxt:	a schema validation context
-- doc:	a parsed document tree
-- Returns:	0 if the document is schemas valid, a positive error code number otherwise and -1 in case of internal or API error.
function libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
  local validation_error = ""
  local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, error)
    validation_error = ffi.string(error['message'])
  end)
  -- xml2.xmlSetStructuredErrorFunc(validation_context, error_handler)
  local is_valid = xml2.xmlSchemaValidateDoc (validation_context, xml_doc)
  
  error_handler:free()

  return tonumber(is_valid), validation_error
end

function libxml2ex.xmlSchemaValidateOneElement	(validation_context, xmlNodePtr)
  local is_valid = xml2.xmlSchemaValidateOneElement (validation_context, xmlNodePtr)
  return tonumber(is_valid)
end

-- Set the callback functions used to handle errors for a validation context
-- ctxt:	a schema validation context
-- err:	the error callback
-- warn:	the warning callback
-- ctx:	contextual data for the callbacks
function libxml2ex.xmlSchemaSetParserErrors (schema_ctxt)
  ngx.log(ngx.NOTICE, "Begin xmlSchemaSetParserErrors")

  -- ngx.log(ngx.NOTICE, "Begin cb*")
  -- ffi.cdef ([[
  --   typedef void (*cb)(void * ctx, const char * msg);  
  -- ]])
  --local pp = ffi.cast("cb", function(ctx, msg) end)
  
  local error_callback = function(ctx, msg, ...)
    ngx.log(ngx.ERR, "/*/*/*/ Begin error_callback")
  end
  local warning_callback = function(ctx, msg, ...)
    ngx.log(ngx.ERR, "/*/*/*/ Begin warning_callback")
  end
  local c_error_callback = ffi.cast("xmlSchemaValidityErrorFunc", error_callback)
  local c_warning_callback = ffi.cast("xmlSchemaValidityWarningFunc", warning_callback)
  
  xml2.xmlSchemaSetParserErrors (schema_ctxt, c_error_callback, c_warning_callback, nil)

  c_error_callback:free()
  c_warning_callback:free()
end

-- Get the last parsing error registered.
-- ctx:	an XML parser context
-- Returns:	NULL if no error occurred or a pointer to the error
function libxml2ex.xmlCtxtGetLastError (ctx)
  local errMessage = ""
  local xmlError = xml2.xmlCtxtGetLastError(ctx)
  if xmlError ~= ffi.NULL then

    local xmlErrorMsg = ffi.string(xmlError.message)
    -- If the last character is Return Line
    if xmlErrorMsg:sub(-1) == '\n' then
      -- Remove the Return Line
      xmlErrorMsg = xmlErrorMsg:sub(1, -2)
    end
    if xmlError.ctxt ~= ffi.NULL then
      ngx.log(ngx.NOTICE, "xmlError.ctxt is not null")
    end
    
    errMessage =  "Error code: "  .. tonumber(xmlError.code) ..
                  ", Line: "      .. tonumber(xmlError.line) ..
                  ", Message: "   .. xmlErrorMsg
    
  else
    ngx.log(ngx.NOTICE, "No error message, xmlCtxtGetLastError is null")
    xmlError = nil
  end
  return errMessage, xmlError
end

-- Format the Error Message
function libxml2ex.formatErrMsg(xmlError)

  local xmlErrorMsg = ffi.string(xmlError.message)
  -- If the last character is Return Line
  if xmlErrorMsg:sub(-1) == '\n' then
    -- Remove the Return Line
    xmlErrorMsg = xmlErrorMsg:sub(1, -2)
  end
  
  local errMessage =  "Error code: "  .. tonumber(xmlError.code) ..
                      ", Line: "      .. tonumber(xmlError.line) ..
                      ", Message: "   .. xmlErrorMsg
  return errMessage
end
-- Get the last parsing error registered
-- ctx:	an XML parser context
-- Returns:	NULL if no error occurred or a pointer to the error
function libxml2ex.xmlGetLastError ()
  local errMessage = ""
  local xmlError = xml2.xmlGetLastError()
  if xmlError ~= ffi.NULL then
    errMessage = libxml2ex.formatErrMsg(xmlError)
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
  else
    ngx.log(ngx.ERR, "Failed to call 'xmlBufferCreate'")
  end
  return xmlDump, errDump
end

function libxml2ex.xmlSchemaValidCtxtGetParserCtxt (xmlSchemaValidCtxtPtr)
  return xml2.xmlSchemaValidCtxtGetParserCtxt(xmlSchemaValidCtxtPtr)
end

-- Set the structured error callback
-- ctxt:	a schema parser context
-- serror:	the structured error function
-- ctx:	the functions context
function libxml2ex.xmlSchemaSetParserStructuredErrors (schema_context)
  local validation_error = ""
  local error_handler = ffi.cast("xmlStructuredErrorFunc", function(userdata, error)
    ngx.log(ngx.ERR, "/*/*/*/ xmlSchemaSetParserStructuredErrors")
    validation_error = ffi.string(error['message'])
  end)
  xml2.xmlSetStructuredErrorFunc(schema_context, error_handler)
  
  error_handler:free()

  return validation_error
end

-- Search and get the value of an attribute associated to a node This does the entity substitution. This function looks in DTD attribute declaration for #FIXED or default declaration values unless DTD use has been turned off. This function is similar to xmlGetProp except it will accept only an attribute in no namespace.
-- node:	the node
-- name:	the attribute name
-- Returns:	the attribute value or NULL if not found. It's up to the caller to free the memory with xmlFree().
function libxml2ex.xmlGetNoNsProp	(node, name)
  local attribute = xml2.xmlGetNoNsProp (node, name)

  return attribute
end

return libxml2ex