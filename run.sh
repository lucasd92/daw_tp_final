#!/bin/bash

PUERTO_PHP=8085
PUERTO_JS=8000
INSTALL=0
CONT=0
VERS=18
SABOR="bionic"

echo "Para ayuda, ejecuta ./run.sh -h"
echo "OPTIND inicia en $OPTIND"
while getopts ":ip:j:hv:c:" optname
  do
    case "$optname" in
      "h")
        echo "Script para instalar contenedores docker y corer aplicación WEB."
        echo "-i          : Instalar docker y sus dependencias."
        echo "-c          : Instalar contenedores necesarios."
        echo "-v  [opcion]: version de ubuntu (soportados 20, 19, 18,17,16 y 14). Por defecto 18."
        echo "-p  [opcion]: Puerto para el servidor PHPMyAdmin. Por defecto 8085."
        echo "-j  [opcion]: Puerto para el servidor NodeJS. Por defecto 8000."
        exit
        ;;
      "v")
        #echo "Se ha especificado la opción $optname"
        VERS=$OPTARG
        ;;    
      "i")
        #echo "Se ha especificado la opción $optname"
        INSTALL=1
        ;;
      "c")
        #echo "Se ha especificado la opción $optname"
        CONT=1
        ;;
      "p")
        #echo "Se ha especificado la opción $optname"
        PUERTO_PHP=$OPTARG
        ;;
      "j")
        #echo "La opción $optname tiene el valor $OPTARG"
        PUERTO_JS=$OPTARG
        ;;
      "?")
        echo "Opción desconocida $OPTARG"
        exit
        ;;
      ":")
        echo "Sin valor de argumentos para la opción -$OPTARG"
        exit
        ;;
      *)
      # Should not occur
        echo "Error desconocido mientras se procesaban las opciones"
        ;;
    esac
    echo "OPTIND ahora es $OPTIND"
  done


#Selecciono el nombre de la distribución segun la version
if [ $VERS = 20 ] 
then
 SABOR="focal"
fi
if [ $VERS = 19 ] 
then
 SABOR="eoan"
fi
if [ $VERS = 17 ] 
then
 SABOR="artful"
fi
if [ $VERS = 16 ] 
then
 SABOR="xenial"
fi
if [ $VERS = 14 ] 
then
 SABOR="trusty"
fi




if [ $INSTALL = 1 ] 
then
echo "Borrando versiones anteriores"
sudo apt-get remove docker docker-engine docker.io
echo "Actualizando repositorios"
sudo apt-get update
echo "Instalando dependencias"
sudo apt-get install apt-transport-https 
sudo apt-get install ca-certificates 
sudo apt-get install curl 
sudo apt-get install gnupg-agent 
sudo apt-get install software-properties-common
echo "Importando clave GPG"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
echo "Verificar fingerprint"
sudo apt-key fingerprint 0EBFCD88
echo "Agregando repositorio al sistema"
sudo echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $SABOR stable" >> /etc/apt/sources.list
echo "Actualizando repositorios"
sudo apt-get update
echo "Instalando docker"
sudo apt-get install docker-ce
echo "Agregando usuario al grupo docker"
sudo usermod -aG docker $USER
sudo gpasswd -a $USER docker
echo "Reiniciando docker"
sudo service docker restart
echo "Corriendo ejemplo \"Hello World\""
sudo docker run hello-world
echo "Se recomienda reiniciar con \"sudo reboot\""
echo "Vuelva a correr el script para iniciar el proyecto"
exit
fi

if [ $CONT = 1 ] 
then
echo "Instalando contenedores.."
echo "Instalando compilador Typescript"
docker pull harmish/typescript
echo "Instalando Servidor NodeJS"
docker pull abassi/nodejs-server:10.0-dev
echo "Instalando MySQL"
docker pull mysql:5.7
echo "Instalando PHPMyAdmin"
docker pull phpmyadmin/phpmyadmin
fi


echo "Cerrando posibles contenedores abiertos"
docker stop $(docker ps -a -q)
sleep 5
echo "Creando red"
docker network create --driver bridge mysql-net
sleep 5
echo "Inicializando compilador de Typescript"
./src/compile_ts.sh ./src ./js &
sleep 5
echo "Inicializando base de datos"
./start_mysql.sh mysql-net "$PWD"/db &
sleep 5
echo "Inicializando PHPMyAdmin"
./run_phpadmin.sh mysql-net mysql-server $PUERTO_PHP &
sleep 5
echo "Inicializando NodeJS"
./serve_node_app_net.sh "$PWD" ws/index.js $PUERTO_JS mysql-net &
sleep 5
xdg-open http://localhost:$PUERTO_JS &
