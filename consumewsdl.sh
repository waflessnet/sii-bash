#!/bin/bash
# Autor : Francisco Céspedes
# correo : ncwapuntes@gmail.com / francisco@twpanel.com
# 
# Este script permite conectarse a los WSDL autenticacion del SII y obtener el token de acceso
# Modo de uso: 
# chmod +x consumewsdl.sh
# ./consumewsdl.sh </ruta/certificado.pfx> <clavedelcertificado>
#

SOAPFILE_SEED='rGetSeed.xml'
SOAPFILE_TOKEN='rGetToken.xml'
TEMPLATE='template.xml'
TIMEOUT=15
SOAPAction_SEMILLA='SOAPAction: "'$URL_SEMILLA'"'
SOAPAction_TOKEN='SOAPAction: "'$URL_TOKEN'"'

if [ -z $1 ]; then
  echo "ERROR :-1 Favor ingrese la ruta del certificado"
  exit;
  else
  RUTA_CERTIFICADO=$1
fi

if [ -z $2 ]; then
 echo "ERROR: -2 Debe ingresar la clave del certificado"
 exit;
 else
 CLAVECERTIFICADO=$2
fi

if [ -z $3 ]; then 
URL_SEMILLA='https://palena.sii.cl/DTEWS/CrSeed.jws'
URL_TOKEN='https://palena.sii.cl/DTEWS/GetTokenFromSeed.jws'
else
SERVER=$3
 if [ "$SERVER" == "maullin" ]; then
	URL_SEMILLA='https://maullin.sii.cl/DTEWS/CrSeed.jws'
	URL_TOKEN='https://maullin.sii.cl/DTEWS/GetTokenFromSeed.jws'
 else
	URL_SEMILLA='https://palena.sii.cl/DTEWS/CrSeed.jws'
	URL_TOKEN='https://palena.sii.cl/DTEWS/GetTokenFromSeed.jws'
 fi
fi

if [ ! -f "$RUTA_CERTIFICADO" ]; then
	echo "Error:1 No existe archivo"
	exit;
fi

# extraemos la clave privada 
PKEY=$(openssl pkcs12 -in "$RUTA_CERTIFICADO" -out tmp/claveprivada.pem -nocerts -nodes -password pass:"$CLAVECERTIFICADO" 2>&1)
if [ "$PKEY" != "MAC verified OK" ]; then
	echo "Error:2 clave incorrecta del certificado";
	exit;
fi
# extraemos el certificado
CERT=$(openssl pkcs12 -in "$RUTA_CERTIFICADO" -out tmp/certificado.pem -nokeys -clcerts -password pass:''$CLAVECERTIFICADO''  2>&1)
if [ "$CERT" != "MAC verified OK" ]; then
        echo "Error:3 clave incorrecta del certificado";
        exit;
fi

#llamadas al servicio de semilla
curl -s -X POST -H 'Content-Type: text/xml;charset=UTF-8' --data-binary @"${SOAPFILE_SEED}" -H "${SOAPAction_SEMILLA}"  ${URL_SEMILLA} | recode html..ascii > tmp/response-semilla.xml
SEMILLA=$(cat tmp/response-semilla.xml  | grep -Po '(?<=<SEMILLA>)([^</SEMILLA>]*)')
if [ "$SEMILLA" == "" ]; then
        echo "Error:4 No existe semilla,favor verifique su acceso al WSDL CrSeed.jws";
        exit;
fi
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

ESTADO=$(cat tmp/token-xml.xml | grep -oP '(?<=<ESTADO>).*?(?=</ESTADO>)')
if [ "$ESTADO" != "00" ]; then
	echo "Error:5 error al crear el token estado:"$ESTADO
	exit;
fi
#retornamos el token
cat tmp/token-xml.xml | grep -oP '(?<=<TOKEN>).*?(?=</TOKEN>)'
