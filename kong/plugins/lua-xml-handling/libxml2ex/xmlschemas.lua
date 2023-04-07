local ffi = require("ffi")

ffi.cdef[[
    typedef struct _xmlSchema xmlSchema;
    typedef xmlSchema * xmlSchemaPtr;
    typedef struct _xmlSchemaParserCtxt {} xmlSchemaParserCtxt;
    typedef xmlSchemaParserCtxt * xmlSchemaParserCtxtPtr;

    typedef xmlDoc * xmlDocPtr;
    
    xmlSchemaParserCtxtPtr	xmlSchemaNewMemParserCtxt   (const char * buffer, int size);
    xmlSchemaPtr	        xmlSchemaParse		        (void * ctxt);
    xmlSchemaValidCtxtPtr	xmlSchemaNewValidCtxt	    (xmlSchemaPtr schema);
    xmlDocPtr	            xmlReadMemory               (const char * buffer, 
                                                        int size, 
                                                        const char * URL, 
                                                        const char * encoding, 
                                                        int options);
    int	                    xmlSchemaValidateDoc		(xmlSchemaValidCtxtPtr ctxt, xmlDocPtr doc);
    typedef void            xmlSchemaValidityErrorFunc	(void * ctx, const char * msg, ...);
    typedef void            xmlSchemaValidityWarningFunc(void * ctx, const char * msg, ...);
    int                     xmlSchemaValidateOneElement	(xmlSchemaValidCtxtPtr ctxt, 
					                                    xmlNodePtr elem);
    int	                    xmlSchemaGetValidErrors		(xmlSchemaValidCtxtPtr ctxt, 
                                                        xmlSchemaValidityErrorFunc * err, 
                                                        xmlSchemaValidityWarningFunc * warn, 
                                                        void ** ctx);
    xmlErrorPtr             xmlGetLastError		        (void);
    void	                xmlResetLastError		    (void);
]]