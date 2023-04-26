
local typedefs = require "kong.db.schema.typedefs"
local xmlgeneral   = require("kong.plugins.lua-xml-handling-lib.xmlgeneral")

return {
  name = "xml-request-1-transform-xslt-before",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsltTransformBefore = { type = "string", required = true }, },
        },
    }, },
  },
}