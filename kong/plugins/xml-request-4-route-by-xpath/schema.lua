
local typedefs = require "kong.db.schema.typedefs"

return {
  name = "xml-request-4-route-by-xpath",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { RouteToPath = { type = "string", required = true }, },
          { RouteToUpstream = { type = "string", required = true }, },
          { XPath = { type = "string", required = true }, },
          { XPathCondition = { type = "string", required = true }, },
          { XPathRegisterNs = { type = "array",  required = true, elements = {type = "string", required = true}, default = {"soap,http://schemas.xmlsoap.org/soap/envelope/"}},},
        },
    }, },
  },
}