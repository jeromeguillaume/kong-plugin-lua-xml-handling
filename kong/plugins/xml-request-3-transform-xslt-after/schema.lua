
local typedefs = require "kong.db.schema.typedefs"

return {
  name = "xml-request-3-transform-xslt-after",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { xsltTransformAfter = { type = "string", required = true }, },
        },
    }, },
  },
}