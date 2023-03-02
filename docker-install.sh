#!/bin/bash
source /media/setup/FILES/SIS/installer/variablen

f_add_group_docker() {
echo -e $LGREEN"Docker"$RALL
sleep 1
addgroup docker
echo ""
}

f_uninst_old_v() {
#Uninstall old versions
echo -e $LGREEN"Docker - Uninstall old versions"$RALL
sleep 1
sudo apt-get remove docker docker-engine docker.io containerd runc -y
echo ""
}

f_setup_repo() {
#Setup Repo
echo -e $LGREEN"Docker - Setup Repo"$RALL
sleep 1
sudo apt-get update -y
sudo apt-get install \
    net-tools \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common -y
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
echo ""
}

f_inst_docker_engine() {
#Install Docker Engine
echo -e $LGREEN"Docker Engine"$RALL
sleep 1
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
sudo usermod -aG docker $USER
sudo docker run --rm hello-world
echo -e "\e[92m$(docker -v)\e[39m"
echo ""
}

f_setup_data-root() {
#Docker Engine Data-root
echo -e $LGREEN"Docker Engine - Data-Root"$RALL
sleep 1
echo ""
read -r "Enter Docker Data Root Path" drpath
sudo systemctl stop docker.service
sudo systemctl stop docker.socket
echo '{
    "graph": "$drpath",
    "storage-driver": "overlay"
}' > /etc/docker/daemon.json
mv /var/lib/docker/* /media/raid1/Docker/
sudo systemctl daemon-reload
sudo systemctl start docker
docker info | grep "Root Dir"
#read -p "Weiter mit Enter..."
echo ""
}

f_inst_docker-compose() {
#Install Docker Compose
echo -e $LGREEN"Docker Compose"$RALL
sleep 1
wget "https://github.com`curl https://github.com/docker/compose/releases/ | grep "x86_64" | grep -iv -e "sha256" | grep -o '<a .*href=.*>' | sed -e 's/<a /\n<a /g' | sed -e 's/<a .*href=['"'"'"]//' | grep "/v*.**.*/" | sed -e 's/docker-compose-.*//'`docker-compose-linux-x86_64" -P /usr/local/bin/
mv /usr/local/bin/docker-compose-linux-x86_64 /usr/local/bin/docker-compose
#sudo curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo -e "\e[92m$(sudo docker-compose --version)\e[39m"
echo ""
}

f_inst_portainer() {
#Install Portainer.io
echo -e $LGREEN"Docker - Portainer.io"$RALL
sleep 1
docker run -d -p 8000:8000 -p 9000:9000 --name portainer --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock -v /opt/portainer:/data portainer/portainer-ce:latest
echo ""
}


f_show_usage() {
printf "******************\n"
printf "* Docker - Setup *\n"
printf "******************\n"
printf "\n"
printf "Normal Setup started automatically!! \n"
printf "\n"
printf " -d | change Data-Root\n"
printf "\n"
printf " -h | Print this helpscreen\n"
printf "\n"
}

f_banner_post() {
clear
echo ""
echo -e "\e[92m******************\e[39m"
echo -e "\e[92m*  Setup Docker  *\e[39m"
echo -e "\e[92m******************\e[39m"
echo ""
}

f_banner_fin() {
ip=$(ip -o -4 addr show scope global | grep eth0 | tr -s ' ' | tr '/' ' ' | cut -f 4 -d ' ')
echo ""
echo -e "\e[92m******************\e[39m"
echo -e "\e[92m* Setup Finished *\e[39m"
echo -e "\e[92m* Portainer IP: http://$ip:8000 *\e[39m"
echo -e "\e[92m******************\e[39m"
echo ""
}

f_banner_aborted() {
echo ""
echo -e "\e[31m******************\e[39m"
echo -e "\e[31m* Setup Aborted! *\e[39m"
echo -e "\e[31m******************\e[39m"
echo ""
}

install() {
f_banner_post
f_add_group_docker
f_uninst_old_v
f_setup_repo
f_inst_docker_engine
f_inst_docker-compose
f_inst_portainer
f_banner_fin
}



if [[ $# -eq 0 ]]; then
f_show_usage
while true
do
echo ""
read -r -n 1 -p "Proceed with Installation... (Y|n)? " cvcc && printf "\n"
case "$cvcc" in
    y|Y|"")
    install
    break
    ;;
    n|N)
    f_banner_aborted
    break
    ;;
esac
done
fi

while [ ! -z "$1" ];do
    case "$1" in
    -h|help)
    f_show_usage
    ;;
    -d)
    f_setup_data-root
    ;;
    *)
    f_show_usage
esac
shift
done
