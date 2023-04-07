
local typedefs = require "kong.db.schema.typedefs"
local xmldef   = require("kong.plugins.lua-xml-handling.xmldef")

return {
  name = "lua-xml-handling",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsdSoapSchema = { type = "string", required = true, default = xmldef.jeg_XSD_SOAP }, },
          { xsdApiSchema = { type = "string", required = false }, },
        },
    }, },
  },
}