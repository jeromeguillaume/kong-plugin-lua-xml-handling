
local typedefs = require "kong.db.schema.typedefs"
local xmlgeneral   = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

return {
  name = "xml-request-2-validate-xsd",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsdSoapSchema = { type = "string", required = true, default = xmlgeneral.XSD_SOAP }, },
          { xsdApiSchema = { type = "string", required = false }, },
        },
    }, },
  },
}