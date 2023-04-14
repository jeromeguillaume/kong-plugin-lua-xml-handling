local xmlgeneral = {}

xmlgeneral.HTTPCodeSOAPFault = 500

xmlgeneral.jeg_XSD_SOAP = [[
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
            xmlns:tns="http://schemas.xmlsoap.org/soap/envelope/"
            targetNamespace="http://schemas.xmlsoap.org/soap/envelope/" >
  <!-- Envelope, header and body -->
  <xs:element name="Envelope" type="tns:Envelope" />
  <xs:complexType name="Envelope" >
    <xs:sequence>
      <xs:element ref="tns:Header" minOccurs="0" />
      <xs:element ref="tns:Body" minOccurs="1" />
      <xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>
  <xs:element name="Header" type="tns:Header" />
  <xs:complexType name="Header" >
    <xs:sequence>
      <xs:any namespace="##other" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##other" processContents="lax" />
  </xs:complexType>

  <xs:element name="Body" type="tns:Body" />
  <xs:complexType name="Body" >
    <xs:sequence>
      <xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##any" processContents="lax" >
    <xs:annotation>
      <xs:documentation>
      Prose in the spec does not specify that attributes are allowed on the Body element
    </xs:documentation>
    </xs:annotation>
  </xs:anyAttribute>
  </xs:complexType>
        
  <!-- Global Attributes.  The following attributes are intended to be usable via qualified attribute names on any complex type referencing them.  -->
  <xs:attribute name="mustUnderstand" >	
      <xs:simpleType>
      <xs:restriction base='xs:boolean'>
      <xs:pattern value='0|1' />
    </xs:restriction>
    </xs:simpleType>
  </xs:attribute>
  <xs:attribute name="actor" type="xs:anyURI" />
  <xs:simpleType name="encodingStyle" >
    <xs:annotation>
    <xs:documentation>
      'encodingStyle' indicates any canonicalization conventions followed in the contents of the containing element.  For example, the value 'http://schemas.xmlsoap.org/soap/encoding/' indicates the pattern described in SOAP specification
    </xs:documentation>
  </xs:annotation>
    <xs:list itemType="xs:anyURI" />
  </xs:simpleType>
  <xs:attribute name="encodingStyle" type="tns:encodingStyle" />
  <xs:attributeGroup name="encodingStyle" >
    <xs:attribute ref="tns:encodingStyle" />
  </xs:attributeGroup>
  <xs:element name="Fault" type="tns:Fault" />
  <xs:complexType name="Fault" final="extension" >
    <xs:annotation>
    <xs:documentation>
      Fault reporting structure
    </xs:documentation>
  </xs:annotation>
    <xs:sequence>
      <xs:element name="faultcode" type="xs:QName" />
      <xs:element name="faultstring" type="xs:string" />
      <xs:element name="faultactor" type="xs:anyURI" minOccurs="0" />
      <xs:element name="detail" type="tns:detail" minOccurs="0" />      
    </xs:sequence>
  </xs:complexType>
  <xs:complexType name="detail">
    <xs:sequence>
      <xs:any namespace="##any" minOccurs="0" maxOccurs="unbounded" processContents="lax" />
    </xs:sequence>
    <xs:anyAttribute namespace="##any" processContents="lax" /> 
  </xs:complexType>
</xs:schema>
]]

xmlgeneral.jeg_XSD_tempuri= [[
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="a" minOccurs="1"/>
      <xs:element type="xs:integer" name="b" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="a" minOccurs="1"/>
      <xs:element type="xs:integer" name="b" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
]]

xmlgeneral.jeg_XML= [[
<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope2 xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
  <soap:Body>
    <Add xmlns="http://tempuri.org/">
      <a>5</a>
      <b>7</b>
    </Add>
  </soap:Body>
</soap:Envelope2>
]]

---------------------------------------
-- Return a SOAP Fault to the Consumer
---------------------------------------
function xmlgeneral.returnSoapFault(plugin_conf, HTTPcode, ErrMsg, ErrEx)
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
  return kong.response.exit(HTTPcode, soapErrMsg, {["Content-Type"] = "text/xml; charset=utf-8"})
end

------------------------------------------
-- Transform XML with XSLT Transformation
------------------------------------------
function xmlgeneral.XSLTransform(plugin_conf, XMLtoTransform, XSLT)
  local libxml2ex   = require("kong.plugins.lua-xml-handling-lib.libxml2ex")
  local libxslt     = require("kong.plugins.lua-xml-handling-lib.libxslt")
  local libxml2     = require("xmlua.libxml2")
  local ffi         = require("ffi")
  local errMessage  = ""
  local err         = nil
  local style       = nil
  local xml_doc     = nil
  local xml_transformed_dump = ""
  
  kong.log.notice("XSLT transformation, BEGIN: " .. XMLtoTransform)

  local default_parse_options = bit.bor(ffi.C.XML_PARSE_RECOVER,
                                        ffi.C.XML_PARSE_NOERROR,
                                        ffi.C.XML_PARSE_NOWARNING,
                                        ffi.C.XML_PARSE_NONET)
                                        
  -- Load the XSLT document
  local xslt_doc = libxml2ex.xmlReadMemory(XSLT, nil, nil, default_parse_options)
  errMessage, err = libxml2ex.xmlGetLastError()

  if err == nil then
    -- Parse XSLT document
    style = libxslt.xsltParseStylesheetDoc (xslt_doc)
    
    -- Load the complete XML document (with <soap:Envelope>)
    xml_doc = libxml2ex.xmlReadMemory(XMLtoTransform, nil, nil, default_parse_options)
    
    errMessage, err = libxml2ex.xmlGetLastError()
  end

  if err == nil then
    -- Transform the XML doc with XSLT transformation
    local xml_transformed = libxslt.xsltApplyStylesheet (style, xml_doc)

    -- Get Root Element, which is <soap:Envelope>
    local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_transformed);
    
    -- Dump into a String the XML transformed by XSLT
    xml_transformed_dump = libxml2ex.xmlNodeDump	(xml_transformed, xmlNodePtrRoot, 1, 1)

    -- Remove empty Namespace (example: xmlns="") added by XSLT library or transformation 
    xml_transformed_dump = xml_transformed_dump:gsub(' xmlns=""', '')

    errMessage, err = libxml2ex.xmlGetLastError()
    
    -- Dump into a String the XML transformed
    kong.log.notice ("XSLT transformation, END: " .. xml_transformed_dump)
  end
  
  if err ~= nil then
    kong.log.err ("XSLT transformation, errMessage: " .. errMessage)
  end

  -- xmlCleanupParser()
  -- xmlMemoryDump()
  
  return xml_transformed_dump, errMessage, err
  
end

--------------------------------------
-- Validate a XML with its XSD schema
--------------------------------------
function xmlgeneral.XMLValidateWithXSD (plugin_conf, child, XMLtoValidate, XSDSchema)
  local ffi         = require("ffi")
  local libxml2ex   = require("kong.plugins.lua-xml-handling-lib.libxml2ex")
  local libxml2     = require("xmlua.libxml2")
  local errMessage  = ""
  local err         = nil
  
  -- Create Parser Context
  local xsd_context = libxml2ex.xmlSchemaNewMemParserCtxt(XSDSchema)
  -- context.lastError.message
  
  -- Create XSD schema
  local xsd_schema_doc, errMessage = libxml2ex.xmlSchemaParse(xsd_context)
  errMessage, err = libxml2ex.xmlGetLastError()

  if err == nil then
    
    -- Create Validation context of XSD Schema
    local validation_context = libxml2ex.xmlSchemaNewValidCtxt(xsd_schema_doc)
    
    -- Load the complete XML document (with <soap:Envelope>)
    local xml_doc = libxml2ex.xmlReadMemory(XMLtoValidate, nil, nil, 1)

    -- if we have to find the 1st Child of API (and not the <soap> root)
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
      kong.log.notice ("XSD validation API part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrChildWS, 1, 1))

      -- Check validity of One element with its XSD schema
      local is_valid = libxml2ex.xmlSchemaValidateOneElement (validation_context, xmlNodePtrChildWS)
      errMessage, err = libxml2ex.xmlGetLastError()
    else
      -- Get Root Element, which is <soap:Envelope>
      local xmlNodePtrRoot   = libxml2.xmlDocGetRootElement(xml_doc);
      kong.log.notice ("XSD validation SOAP part: " .. libxml2ex.xmlNodeDump	(xml_doc, xmlNodePtrRoot, 1, 1))

      -- Check validity of XML with its XSD schema
      local is_valid, errMessage = libxml2ex.xmlSchemaValidateDoc (validation_context, xml_doc)
      errMessage, err = libxml2ex.xmlGetLastError()
    end
  end
  
  if err == nil then
    kong.log.notice ("XSD validation of SOAP schema: Ok")
  else
    kong.log.err ("XSD validation of SOAP schema: Ko, " .. errMessage)
  end
  return errMessage, err
end

---------------------------------------------
-- Search a XPath and Compares it to a value
---------------------------------------------
function xmlgeneral.RouteByXPath (kong, XMLtoSearch, XPath, XPathCondition)
  local ffi         = require("ffi")
  local libxml2ex   = require("kong.plugins.lua-xml-handling-lib.libxml2ex")
  local libxml2     = require("xmlua.libxml2")
  
  kong.log.notice("XMLtoSearch: " .. XMLtoSearch)
  kong.log.notice("xmlNewParserCtxt")
  local context = libxml2.xmlNewParserCtxt()
  kong.log.notice("xmlCtxtReadMemory")
  local document = libxml2.xmlCtxtReadMemory(context, XMLtoSearch)
  if not document then
    error({message = ffi.string(context.lastError.message)})
  end
  kong.log.notice("xmlXPathNewContext")
  local context = libxml2.xmlXPathNewContext(document)
  kong.log.notice("xmlXPathRegisterNs")
  local rc = libxml2.xmlXPathRegisterNs(context, "soap", "http://schemas.xmlsoap.org/soap/envelope/")
  if rc == false then
    kong.log.err ("RouteByXPath, Unable to register the Path, rc: " .. tostring(rc))
  end
  kong.log.notice("xmlXPathRegisterNs")
  rc = libxml2.xmlXPathRegisterNs(context, "tempui", "http://tempuri.org/")
  if rc == false then
    kong.log.err ("RouteByXPath, Unable to register the Path, rc: " .. tostring(rc))
  end
  
  kong.log.notice("xmlXPathEvalExpression")
  -- XPath = "/root/sub"
  XPath =  "/soap:Envelope/soap:Body/Add"
  local object = libxml2.xmlXPathEvalExpression(XPath, context)
  if object ~= ffi.NULL then
    kong.log.notice("object.type: " .. tonumber(object.type))
    --kong.log.notice("lastError.code: " .. context.lastError.code)
    if object.nodesetval.nodeNr ~= 0 then
      if object.nodesetval.nodeTab[0] ~= ffi.NULL then
        kong.log.notice("libxml2.xmlNodeGetContent: " .. libxml2.xmlNodeGetContent(object.nodesetval.nodeTab[0]))
      else
        kong.log.err ("RouteByXPath, xmlNodeGetContent is null")  
      end
    else
      kong.log.err ("RouteByXPath, object.nodesetval.nodeNr is null")  
    end
  else
    kong.log.err ("RouteByXPath, object is null")
  end
end

return xmlgeneral