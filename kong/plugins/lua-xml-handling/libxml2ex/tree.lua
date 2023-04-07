local ffi = require("ffi")

ffi.cdef[[
    int     xmlNodeDump			(xmlBufferPtr buf, 
                                xmlDocPtr doc, 
                                xmlNodePtr cur, 
                                int level, 
                                int format);
]]