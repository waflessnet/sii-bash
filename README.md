# sii-bash
### Autenticacion con SII
Este script bash permite autenticarse frente a los WDSL con el SII de chile mediante el mecanismo de obtencion de semilla, certificacion de esta y obtencion del token.
#### Requisitos:
 - Debes poseer un certificado de digital, por lo menos simple, emitido por una entidad certificadora.
 - Linux
#### Dependencias
Para poder utilizar el script es necesario contar con los siguientes paquetes
 - curl 
 - recode
 - xmlsec1 
 - openssl 
 #### Instalacion de dependencias en DEBIAN/UBUNTU 
 apt install curl recode xmlsec1 openssl 
 
 #### Instalacion de dependencias en GENTOO 
 emerge -av curl recode xmlsec1 openssl
 
 #### Instalación de dependencias en CentOS 
 yum install xmlsec1 xmlsec1-openssl recode curl openssl-libs

#### Modo de uso
   
```sh
$ git clone https://github.com/waflessnet/sii-bash.git 
$ cd  sii-bash/
$ chmod +x consumewsdl.sh
$ ./consumewsdl.sh </ruta/certificado.pfx> <claveCertificado> <servidor>
```
Con esto obtenemos el token de autenticacion del servicio.
Esta definido por default  produccion: palena.sii.cl, es decir si se omite <servidor>  consume en palena.sii.cl si se agrega maullin consume en maullin.sii.cl.
Consumo en palena.sii.cl:
```sh
$  ./consumewsdl.sh /tmp/certificado.pfx 123456 
```
Consumo en maullin.sii.cl:
```sh
$  ./consumewsdl.sh /tmp/certificado.pfx 123456  maullin
```
Si la clave del certificado utliza caracteres especiales agregamos comillas simples a esta :
```sh
$  ./consumewsdl.sh /tmp/certificado.pfx 'wqe@qkj$sdf09' maullin
```
