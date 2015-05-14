#!/bin/b
# Autor : Francisco Céspedes
# corremo : ncwapuntes@gmail.com / francisco@twpanel.com
# 

URL_SEMILLA='https://palena.sii.cl/DTEWS/CrSeed.jws'
URL_TOKEN='https://palena.sii.cl/DTEWS/GetTokenFromSeed.jws'
SOAPFILE_SEED='rGetSeed.xml'
SOAPFILE_TOKEN='rGetToken.xml'
TEMPLATE='template.xml'
TIMEOUT=15
CLAVECERTIFICADO='xxxxxxxx'
SOAPAction_SEMILLA='SOAPAction: "'$URL_SEMILLA'"'
SOAPAction_TOKEN='SOAPAction: "'$URL_TOKEN'"'
# extraemos la clave privada 
openssl pkcs12 -in tmp/certificado.pfx -out tmp/claveprivada.pem -nocerts -nodes -password pass:''$CLAVECERTIFICADO'' > /dev/null 2>&1 
# extraemos el certificado
openssl pkcs12 -in tmp/certificado.pfx -out tmp/certificado.pem -nokeys -clcerts -password pass:''$CLAVECERTIFICADO'' > /dev/null 2>&1

#llamadas al servicio de semilla
curl -s -X POST -H 'Content-Type: text/xml;charset=UTF-8' --data-binary @"${SOAPFILE_SEED}" -H "${SOAPAction_SEMILLA}"  ${URL_SEMILLA} | recode html..ascii > tmp/response-semilla.xml
SEMILLA=$(cat tmp/response-semilla.xml  | grep -Po '(?<=<SEMILLA>)([^</SEMILLA>]*)')

#generamos el archivo XML en base al template
sed 's/<Semilla>.*<\/Semilla>/<Semilla>'$SEMILLA'<\/Semilla>/g' template.xml > tmp/semilla.xml
#Firmar un documento
xmlsec1 --sign --privkey-pem tmp/claveprivada.pem,tmp/certificado.pem --pwd ''$CLAVECERTIFICADO'' tmp/semilla.xml > tmp/semilla-firmada.xml
#agregamos tags de request
sed -i '1s|<\?|<pszXml xsi:type="xsd:string"><!\[CDATA\[<|' tmp/semilla-firmada.xml 
sed -i '79s|<\/getToken>|<\/getToken>\]\]><\/pszXml>|' tmp/semilla-firmada.xml
#entramos al request y ponemos el xml
 sed -n "1,4p" rGetToken.xml > tmp/request-token.xml
 cat tmp/semilla-firmada.xml >> tmp/request-token.xml
 sed -n "6,8p" rGetToken.xml >> tmp/request-token.xml
#llamamos el wsdl para obtener el token
curl -s -X POST -H 'Content-Type: text/xml;charset=UTF-8' --data-binary @tmp/request-token.xml  -H "${SOAPAction_TOKEN}"  ${URL_TOKEN} | recode html..ascii >  tmp/token-xml.xml
#retornamos el token
cat tmp/token-xml.xml | awk -F">" '/TOKEN/{printf $2 }'  | sed 's|</TOKEN||'
