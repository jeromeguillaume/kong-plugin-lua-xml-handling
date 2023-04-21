# remove the previous container
docker rm -f kong-gateway-lua-xml-handling >/dev/null

#--platform linux/arm64 \
#-e "KONG_PLUGINS=bundled,xml-request-1-transform-xslt-before,xml-request-2-validate-xsd,xml-request-3-transform-xslt-after,xml-request-4-route-by-xpath,xml-response-1-transform-xslt-before" \



docker run -d --name kong-gateway-lua-xml-handling \
--network=kong-net \
--link kong-database-lua-xml-handling:kong-database-lua-xml-handling \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-request-1-transform-xslt-before,destination=/usr/local/share/lua/5.1/kong/plugins/xml-request-1-transform-xslt-before \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-request-2-validate-xsd,destination=/usr/local/share/lua/5.1/kong/plugins/xml-request-2-validate-xsd \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-request-3-transform-xslt-after,destination=/usr/local/share/lua/5.1/kong/plugins/xml-request-3-transform-xslt-after \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-request-4-route-by-xpath,destination=/usr/local/share/lua/5.1/kong/plugins/xml-request-4-route-by-xpath \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-response-1-transform-xslt-before,destination=/usr/local/share/lua/5.1/kong/plugins/xml-response-1-transform-xslt-before \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/xml-response-2-validate-xsd,destination=/usr/local/share/lua/5.1/kong/plugins/xml-response-2-validate-xsd \
--mount type=bind,source=/Users/jeromeg/Documents/Kong/Tips/kong-plugin-lua-xml-handling/kong/plugins/lua-xml-handling-lib,destination=/usr/local/share/lua/5.1/kong/plugins/lua-xml-handling-lib \
-e "KONG_DATABASE=postgres" \
-e "KONG_PG_HOST=kong-database-lua-xml-handling" \
-e "KONG_PG_USER=kong" \
-e "KONG_PG_PASSWORD=kongpass" \
-e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
-e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
-e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
-e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
-e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
-e "KONG_PLUGINS=bundled,xml-request-1-transform-xslt-before,xml-request-2-validate-xsd,xml-request-3-transform-xslt-after,xml-request-4-route-by-xpath,xml-response-1-transform-xslt-before,xml-response-2-validate-xsd" \
-e KONG_LICENSE_DATA \
-e "KONG_NGINX_WORKER_PROCESSES=1" \
-p 8000:8000 \
-p 8443:8443 \
-p 8001:8001 \
-p 8002:8002 \
-p 8444:8444 \
kong/kong-gateway:3.1.1.3-alpine
#kong/kong-gateway:2.8.4.0-alpine
#kong/kong-gateway:3.1.1.3-alpine

#kong/kong-gateway:3.2.2.1

echo 'docker logs kong-gateway-lua-xml-handling -f'