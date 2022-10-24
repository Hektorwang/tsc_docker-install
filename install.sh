#!/bin/bash

# shellcheck disable=SC1091
WORK_DIR=$(cd "$(dirname "$0")"/ && pwd) && cd "$WORK_DIR"/ || exit 99
source "${WORK_DIR}"/func

MODULE_HOME="/home/tsc/docker"

#参数个数
PARAM_COUNT=$#

#安装类型及目录
INSTALL_TYPE=$1
INSTALL_PATH=$2

usage() {
  #如果传递进来的参数个数不等于2，则记录错误并退出
  LOGINFO "---------------------------Usage---------------------------------------"
  LOGINFO " Input error ! You must input two params !"
  LOGINFO " sh install.sh <INSTALL_TYPE> <INSTALL_PATH>"
  LOGINFO " Example:"
  LOGINFO " sh install.sh install    ${MODULE_HOME}    Install the application."
  LOGINFO " sh install.sh uninstall  ${MODULE_HOME}    Uninstall the application."
  LOGINFO " sh install.sh reinstall  ${MODULE_HOME}    Reinstall the application."
}

#判断参数个数
if [ ${PARAM_COUNT} -ne 2 ]; then
  usage
  exit 1
fi

modify_profile() {
  ProfilePath="${INSTALL_PATH}/etc/daemon.json"
  StoragePath="${INSTALL_PATH}/var/lib/docker"
  RunPath="${INSTALL_PATH}/var/run/docker"
  if [[ ! -e ${StoragePath} ]]; then
    mkdir -p "${StoragePath}"
  fi
  if [[ ! -e ${RunPath} ]]; then
    mkdir -p "${RunPath}"
  fi
  sed -i "s#ProfilePath#${ProfilePath}#g" /etc/systemd/system/docker.service
  sed -i "s#StoragePath#${StoragePath}#g" "${INSTALL_PATH}"/etc/daemon.json
  sed -i "s#RunPath#${RunPath}#g" "${INSTALL_PATH}"/etc/daemon.json
}

install() {
  if [[ ! -d ${INSTALL_PATH}/bin ]]; then
    mkdir -p "${INSTALL_PATH}"/bin
  fi
  if [[ ! -e ${DOCKER_FILE} ]]; then
    LOGERROR "docker文件不存在, 请将安装包移动到${DOCKER_FILE}"
    exit 2
  fi
  
  LOGINFO "extracting installation package..."
  tar xzvf "${DOCKER_FILE}" -C /tmp &>/dev/null
  \cp /tmp/docker/* "${INSTALL_PATH}"/bin &>/dev/null
  \cp "${DOCKER_COMPOSE_FILE}" "${INSTALL_PATH}"/bin/docker-compose
  chmod u+x "${INSTALL_PATH}"/bin/*
  set -e
  LOGINFO "creating symbolic connection to /usr/bin"
  ln -s "${INSTALL_PATH}"/bin/* /usr/bin
  set +e

  LOGINFO "register docker service..."
  \cp "${WORK_DIR}"/src/docker.service /etc/systemd/system/
  # chmod a+x /etc/systemd/system/docker.service
  
  LOGINFO "creating docker config..."
  mkdir -p "${INSTALL_PATH}"/etc  
  \cp "${WORK_DIR}"/src/daemon.json "${INSTALL_PATH}"/etc
  modify_profile
  
  LOGINFO "creating docker group..."
  groupadd docker
  
  LOGINFO "starting docker service..."
  systemctl daemon-reload
  systemctl start docker
  
  LOGINFO "checking docker service..."
  if systemctl status docker &>/dev/null; then
    LOGSUCCESS "installation successed"
  fi
}

uninstall() {
  LOGINFO "stopping docker service..."
  systemctl stop docker
  
  LOGINFO "deleting docker service file..."
  rm -rf /etc/systemd/system/docker.service
  rm -rf /etc/docker
  
  LOGINFO "deleting docker directory..."
  # rm -rf "${INSTALL_PATH}"
  mv -vf "${INSTALL_PATH}" "${INSTALL_PATH}"."$(date +%Y%m%d%H%M%S)"
  
  LOGINFO "deleting docker binary file..."
  cd /usr/bin
  rm -rf containerd containerd-shim containerd-shim-runc-v2 ctr docker-compose
  rm -rf docker dockerd docker-init docker-proxy runc docker-compose
  
  LOGINFO "deleting docker network interface card..."
  ifconfig docker0 down
  brctl delbr docker0 &>/dev/null

  LOGINFO "deleting other docker files..."
  rm -rf /var/run/docker
  
  LOGINFO "deleting group docker..."
  if groupdel docker; then
    LOGSUCCESS "uninstall successed"
  fi
}



##操作类型
case "$INSTALL_TYPE" in
install)
  source "${WORK_DIR}"/checkenv.sh
  LOGINFO "开始安装 docker"
  install
  ;;
uninstall)
  LOGINFO "卸载 docker"
  uninstall
  ;;
reinstall)
  LOGINFO "开始重新安装 docker"
  uninstall
  install
  LOGSUCCESS "重新安装 SUCCESS"
  ;;
*)
  usage
  exit 10
  ;;
esac

