local ffi = require("ffi")

ffi.cdef[[
    typedef struct _xmlSchema xmlSchema;
    typedef xmlSchema * xmlSchemaPtr;
    typedef void (*xmlSchemaValidityErrorFunc)	(void * ctx, const char * msg);
    typedef void (*xmlSchemaValidityWarningFunc) (void * ctx, const char * msg);
    //typedef void xmlSchemaValidityErrorFunc	(void * ctx, const char * msg, ...);
    //typedef void xmlSchemaValidityWarningFunc (void * ctx, const char * msg, ...);
    
    typedef struct _xmlSchemaParserCtxt {
        int type;
        void *errCtxt;             /* user specific error context */
        xmlSchemaValidityErrorFunc error;   /* the callback in case of errors */
        xmlSchemaValidityWarningFunc warning;       /* the callback in case of warning */
        int err;
        int nberrors;
        xmlStructuredErrorFunc serror;
    
        //JEG xmlSchemaConstructionCtxtPtr constructor;
        void * constructor;
        int ownsConstructor; /* TODO: Move this to parser *flags*. */
    
        /* xmlSchemaPtr topschema;	*/
        /* xmlHashTablePtr namespaces;  */
    
        // JEG xmlSchemaPtr schema;        /* The main schema in use */
        void * schema;        /* The main schema in use */
        int counter;
    
        const xmlChar *URL;
        xmlDocPtr doc;
        int preserve;		/* Whether the doc should be freed  */
    
        const char *buffer;
        int size;
    
        /*
         * Used to build complex element content models
         */
        
        // JEG xmlAutomataPtr am;
        // JEG xmlAutomataStatePtr start;
        // JEG xmlAutomataStatePtr end;
        // JEG xmlAutomataStatePtr state;
        void * am;
        void * start;
        void * end;
        void * state;

        // JEG xmlDictPtr dict;		/* dictionary for interned string names */
        void * dict;		/* dictionary for interned string names */
        // JEG xmlSchemaTypePtr ctxtType; /* The current context simple/complex type */
        void * ctxtType; /* The current context simple/complex type */
        int options;
        xmlSchemaValidCtxtPtr vctxt;
        int isS4S;
        int isRedefine;
        int xsiAssemble;
        int stop; /* If the parser should stop; i.e. a critical error. */
        const xmlChar *targetNamespace;
        // JEG xmlSchemaBucketPtr redefined; /* The schema to be redefined. */
        void * redefined; /* The schema to be redefined. */
    
        // JEG xmlSchemaRedefPtr redef; /* Used for redefinitions. */
        void * redef; /* Used for redefinitions. */
        int redefCounter; /* Used for redefinitions. */
        //JEG xmlSchemaItemListPtr attrProhibs;
        void * attrProhibs;
    } _xmlSchemaParserCtxt;
    typedef _xmlSchemaParserCtxt xmlSchemaParserCtxt;
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
    int                     xmlSchemaValidateOneElement	(xmlSchemaValidCtxtPtr ctxt, 
					                                    xmlNodePtr elem);
    int	                    xmlSchemaGetValidErrors		(xmlSchemaValidCtxtPtr ctxt, 
                                                        xmlSchemaValidityErrorFunc * err, 
                                                        xmlSchemaValidityWarningFunc * warn, 
                                                        void ** ctx);
    void	                xmlSchemaSetParserErrors	(xmlSchemaParserCtxtPtr ctxt, 
                                                        xmlSchemaValidityErrorFunc err, 
                                                        xmlSchemaValidityWarningFunc warn, 
                                                        void * ctx);
    typedef struct xmlParserCtxt {} * xmlParserCtxtPtr;
    xmlParserCtxtPtr	xmlSchemaValidCtxtGetParserCtxt	    (xmlSchemaValidCtxtPtr ctxt);
    void	            xmlSchemaSetParserStructuredErrors	(xmlSchemaParserCtxtPtr ctxt, 
						 xmlStructuredErrorFunc serror, 
						 void * ctx);
]]