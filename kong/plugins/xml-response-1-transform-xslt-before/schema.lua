
local typedefs = require "kong.db.schema.typedefs"
local xmlgeneral   = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

return {
  name = "xml-response-1-transform-xslt-before",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsdApiSchema = { type = "string", required = false }, },
          { xsdSoapSchema = { type = "string", required = false, default = xmlgeneral.XSD_SOAP }, },
          { xsltTransform = { type = "string", required = false }, },
        },
    }, },
  },
}