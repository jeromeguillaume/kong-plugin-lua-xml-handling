local ffi = require("ffi")

ffi.cdef[[
xmlErrorPtr	            xmlCtxtGetLastError	        (void * ctx);
xmlErrorPtr             xmlGetLastError		        (void);
void	                xmlResetLastError		    (void);
typedef void            xmlStructuredErrorFunc (void* userData, xmlErrorPtr error);
void	                xmlSetStructuredErrorFunc(void* ctx, xmlStructuredErrorFunc handler);
]]