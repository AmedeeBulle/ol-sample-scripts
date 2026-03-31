#!/usr/bin/env bash
#
# Provisioning script for AWS
#
# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#
# Description: AWS specific provisioning. This module provides 2 functions,
# both are optional.
#   cloud::provision: provision the instance
#   cloud::cleanup: instance cleanup before shutdown
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

#######################################
# Configure AWS instance
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::config()
{
  common::echo_message "Setup network"
  # simple eth0 configuration
  if [[ -d /etc/sysconfig/network-scripts ]]; then
    cat > /etc/sysconfig/network-scripts/ifcfg-eth0 <<-EOF
		DEVICE="eth0"
		BOOTPROTO="dhcp"
		ONBOOT="yes"
		TYPE="Ethernet"
		USERCTL="yes"
		PEERDNS="yes"
		IPV6INIT="no"
		PERSISTENT_DHCLIENT="1"
		EOF
  fi
}

#######################################
# Install required packages for AWS
# Globals:
#   DRACUT_CMD, KERNEL, YUM_VERBOSE
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::install_aws_packages()
{
  # amazon/ena is in the modules packages
  common::echo_message "Install amazon/ena module"
  if [[ "${KERNEL,,}" = "uek" ]]; then
    yum install -y "${YUM_VERBOSE}" kernel-uek-modules
  else
    yum install -y "${YUM_VERBOSE}" kernel-modules
  fi
  local default_kernel
  default_kernel=$(common::default_kernel)
  ${DRACUT_CMD} -f "/boot/initramfs-${default_kernel}.img" "${default_kernel}"
}


#######################################
# Install cloud-init, use CLOUD_USER if specified
# Globals:
#   CLOUD_INIT, CLOUD_USER, YUM_VERBOSE
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::cloud_init()
{
  common::echo_message "Install cloud-init: ${CLOUD_INIT^^}"
  if [[ "${CLOUD_INIT,,}" = "yes" ]]; then
    # Disable cloud-init during installation
    #   cloud-init-generator is run at install time and generates systemd
    #   timeouts while scanning for data-sources as we have the distribution
    #   image mounted!
    mkdir /etc/cloud
    touch /etc/cloud/cloud-init.disabled
    yum install -y "${YUM_VERBOSE}" cloud-init tar cloud-utils-growpart
    rm /etc/cloud/cloud-init.disabled
    cat > /etc/cloud/cloud.cfg.d/90_ol.cfg <<-EOF
	# Provide sensible defaults for OL - see Orabug 34821447
	system_info:
	  default_user:
	    name: cloud-user
	    lock_passwd: true
	    gecos: Cloud User
	    groups: [adm, systemd-journal]
	    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
	    shell: /bin/bash
	  distro: rhel
	  paths:
	    cloud_dir: /var/lib/cloud
	    templates_dir: /etc/cloud/templates
	  ssh_svcname: sshd
	EOF
    if [[ -n "${CLOUD_USER}" ]]; then
      sed -i -e "s/\(^\s\+name:\).*/\1 ${CLOUD_USER}/" /etc/cloud/cloud.cfg.d/90_ol.cfg
    fi
  fi
}

#######################################
# Provisioning module
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::provision()
{
  cloud::install_aws_packages
  cloud::cloud_init
  cloud::config
}

#######################################
# Cleanup module
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::cleanup()
{
  :
}
