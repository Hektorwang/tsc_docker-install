#!/bin/bash

# shellcheck disable=SC1091
WORK_DIR=$(cd "$(dirname "$0")"/ && pwd) && cd "$WORK_DIR"/ || exit 99 

source "${WORK_DIR}"/func

#检查CPU架构
check_cpuarch() {
  CpuArch="$(arch)"
  LOGINFO "Check the system CPU architecture......"
  if [[ ${CpuArch} =~ x86.* ]]; then
    export DOCKER_FILE="${WORK_DIR}/src/docker-20.10.18-x86.tgz"
    export DOCKER_COMPOSE_FILE="${WORK_DIR}/src/docker-compose-linux-x86_64"
    LOGINFO "the system CPU architecture is ${CpuArch},use ${DOCKER_FILE} ${DOCKER_COMPOSE_FILE}"
  elif [[ ${CpuArch} =~ aarch.* || ${CpuArch} =~ altarch.* ]]; then
    export DOCKER_FILE="${WORK_DIR}/src/docker-20.10.18-aarch64.tgz"
    export DOCKER_COMPOSE_FILE="${WORK_DIR}/src/docker-compose-linux-aarch64"
    LOGINFO "the system CPU architecture is ${CpuArch},use ${DOCKER_FILE} ${DOCKER_COMPOSE_FILE}"
  else
    LOGERROR "only x86_64 and aarch64 are supported!"
    exit 10
  fi
}

check_longbit() {
  LongBit=$(getconf LONG_BIT)
  local Required=64
  LOGINFO "Check the system longbit......"
  if [[ ${LongBit} -eq ${Required} ]]; then
    LOGSUCCESS "the system longbit  meets the conditions,success!"
  else
    LOGERROR "must be ${Required} bit"
    exit 1
  fi
}

check_selinux() {
  LOGINFO "Check selinux......"
  if [[ $(getenforce) == "Disabled" ]]; then
    LOGSUCCESS "SELINUX disabled!"
  else
    LOGERROR "SELINUX must be disabled!"
    exit 1
  fi
}

check_kernel() {
  LOGINFO "Check the system kernel version......"
  local CurrentVer RequiredVer
  CurrentVer=$(uname -r | awk -F '-' '{print $1}' |awk -F'.' '{print $1*1000000+$2*1000+$3}')
  RequiredVer=$(echo 3.10 | awk -F'.' '{print $1*1000000+$2*1000+$3}')
  if [[ "${CurrentVer}" -ge ${RequiredVer} ]]; then
    LOGSUCCESS "the system kernel version  meets the conditions,success!"
  else
    LOGERROR "the kernel version must be ${RequiredVer} or higher!"
    exit 2
  fi
}

check_iptables() {
  LOGINFO "Check the system iptables version......"
  local CurrentVer RequiredVer
  CurrentVer=$(iptables -V | awk -F 'v' '{print $2}'|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  RequiredVer=$(echo 1.4|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  if [[ "${CurrentVer}" -ge ${RequiredVer} ]]; then
    LOGSUCCESS "the system iptables version  meets the conditions,success!"
  else
    LOGERROR "the iptables version must be ${RequiredVer} or higher!"
    exit 3
  fi
}

check_gitversion() {
  LOGINFO "Check the system git version......"
  local CurrentVer RequiredVer
  CurrentVer=$(git --version | awk '{print $3}'|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  RequiredVer=$(echo 1.7|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  if [[ "${CurrentVer}" -ge ${RequiredVer} ]]; then
    LOGSUCCESS "the system git version  meets the conditions,success!"
  else
    LOGERROR "the git version must be ${RequiredVer} or higher!"
    exit 4
  fi
}

check_ps() {
  LOGINFO "Check whether the ps is installed in the system......"
  if [[ $(ps) ]]; then
    LOGSUCCESS "the ps han been installed on the system,success!"
  else
    LOGERROR "the ps is not installed"
    exit 5
  fi
}

check_xzver() {
  LOGINFO "Check the system XZ utils version......"
  local CurrentVer RequiredVer
  CurrentVer=$(xz --version | awk '{print $4}' | head -n 1|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  RequiredVer=$(echo 4.9|awk -F'.' '{print $1*1000000+$2*1000+$3}')
  if [[ "${CurrentVer}" -ge ${RequiredVer} ]]; then
    LOGSUCCESS "the system iptables version  meets the conditions,success!"
  else
    LOGERROR "the XZ utils version must be ${RequiredVer} or higher!"
    exit 6
  fi
}

#检查系统是否满足安装条件
check_env() {
  check_longbit 
  check_kernel
  check_iptables
  check_selinux
  # check_gitversion
  check_ps
  check_xzver
}

check_cpuarch
check_env
