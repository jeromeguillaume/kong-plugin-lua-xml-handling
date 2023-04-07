# Kong plugins: XML Handling
It's a set of Kong plugins which are developed in Lua and uses the GNOME C libraries [libxml2](https://gitlab.gnome.org/GNOME/libxml2#libxml2) and [libxslt](https://gitlab.gnome.org/GNOME/libxslt#libxslt).

The plugins handle the XML **Request** and the XML **Response** in this order:

**Request**:

1) ```XSLT TRANSFORMATION - BEFORE XSD```: Transform the XML request with XSLT (XSLTransformation) before XSD Validation (step #2)
2) ```XSD VALIDATION```: Validate XML request against its XSD schema
3) ```XSLT TRANSFORMATION - AFTER XSD```: Transform the XML request with XSLT (XSLTransformation) after XSD Validation (step #2)
4) ```ROUTING BY XPATH```: change the Route of the request to a different hostname and path depending of XPath condition

**Response**:

5) ```XSLT TRANSFORMATION - BEFORE XSD```: Transform the XML response before step #6
6) ```XSD VALIDATION```: Validate the XML response against its XSD schema
7) ```XSLT TRANSFORMATION - AFTER XSD```:  Transform the XML response after step #6

Each handling is optional, except the ```XSLT TRANSFORMATION - AFTER XSD``` of the Response.
In case of misconfiguration the Plugin sends to the consumer an HTTP 500 Internal Server Error ```<soap:Fault>``` (with the error detailed message)

![Alt text](/images/Pipeline-Kong-xml-handling.png?raw=true "Kong - XML execution pipeline")

![Alt text](/images/Kong-Manager.png?raw=true "Kong - Manager")


## How deploy XML Handling plugin
1) Create and prepare a PostgreDB called ```kong-database-lua-xml-handling```.
[See documentation](https://docs.konghq.com/gateway/latest/install/docker/#prepare-the-database).

2) Provion a license of Kong Enterprise Edition and put the content in ```KONG_LICENSE_DATA``` environment variable. The following license is only an example. You must use the following format, but provide your own content.
```
 export KONG_LICENSE_DATA='{"license":{"payload":{"admin_seats":"1","customer":"Example Company, Inc","dataplanes":"1","license_creation_date":"2023-04-07","license_expiration_date":"2023-04-07","license_key":"00141000017ODj3AAG_a1V41000004wT0OEAU","product_subscription":"Konnect Enterprise","support_plan":"None"},"signature":"6985968131533a967fcc721244a979948b1066967f1e9cd65dbd8eeabe060fc32d894a2945f5e4a03c1cd2198c74e058ac63d28b045c2f1fcec95877bd790e1b","version":"1"}}'
```

3) Start the Kong Gateway
```
./start-kong.sh
```

## How configure and test ```calcWebService/Calc.asmx``` Service in Kong
1) Create a Kong Service named ```calcWebService``` with this URL: https://ecs.syr.edu/faculty/fawcett/Handouts/cse775/code/calcWebService/Calc.asmx.
This simple backend Web Service adds 2 numbers.

2) Create a Route on the Service ```calcWebService``` with the ```path``` value ```/calcWebService```

3) Call the ```calcWebService``` through the Kong Gateway Route by using [httpie](https://httpie.io/) tool
```
http POST http://localhost:8000/calcWebService \
Content-Type:"text/xml; charset=utf-8" \
--raw "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<soap:Envelope xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:soap=\"http://schemas.xmlsoap.org/soap/envelope/\">
  <soap:Body>
    <Add xmlns=\"http://tempuri.org/\">
      <a>5</a>
      <b>7</b>
    </Add>
  </soap:Body>
</soap:Envelope>"
```

The expected result is ```12```:
```xml
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" ...>
  <soap:Body>
    <AddResponse xmlns="http://tempuri.org/">
      <AddResult>12</AddResult>
    </AddResponse>
  </soap:Body>
</soap:Envelope>
```

## How test XML Handling plugins with ```calcWebService/Calc.asmx```

### Example #2: Request | ```XSD VALIDATION```: calling incorrectly ```calcWebService``` and detecting issue in the Request with XSD schema
Calling incorrectly ```calcWebService``` and detecting issue in the Request with XSD schema. 
We call incorrectly the Service by injecting a SOAP error; the plugin detects it, sends an error message to the Consumer and Kong doesn't call the SOAP backend API.

Add ```xml-request-2-validate-xsd``` plugin and configure the plugin with:
- ```XsdApiSchema``` property with this value:
```xml
<xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" targetNamespace="http://tempuri.org/" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  <xs:element name="Add" type="tem:AddType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="AddType">
    <xs:sequence>
      <xs:element type="xs:integer" name="a" minOccurs="1"/>
      <xs:element type="xs:integer" name="b" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
  <xs:element name="Subtract" type="tem:SubtractType" xmlns:tem="http://tempuri.org/"/>
  <xs:complexType name="SubtractType">
    <xs:sequence>
      <xs:element type="xs:integer" name="a" minOccurs="1"/>
      <xs:element type="xs:integer" name="b" minOccurs="1"/>
    </xs:sequence>
  </xs:complexType>
</xs:schema>
```

Use request defined at step #3, **change** ```<soap:Envelope>``` by **```<soap:EnvelopeKong>```** and ```</soap:Envelope>``` by **```</soap:EnvelopeKong>```** => Kong says: 
```xml
<faultstring>
XSD validation failed: Error code: 1845, Line: 2, Message: Element '{http://schemas.xmlsoap.org/soap/envelopeKong/}Envelope': No matching global declaration available for the validation root.
</faultstring>
```
Use request defined at step #3, **remove ```<a>5</a>```** => there is an error because the ```<a>``` tag has the ```minOccurs="1"``` XSD property and Kong says: 
```xml
<faultstring>
XSD validation failed: Error code: 1871, Line: 5, Message: Element '{http://tempuri.org/}b': This element is not expected. Expected is ( {http://tempuri.org/}a ).
</faultstring>
```
