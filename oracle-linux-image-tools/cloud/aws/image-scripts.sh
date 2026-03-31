#!/usr/bin/env bash
#
# Cleanup and package image for AWS
#
# Copyright (c) 2026 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at
# https://oss.oracle.com/licenses/upl
#
# Description: this module provides the following functions which are run on
# the host:
#   cloud::validate: called at the very beginning to validate project parameters
#     (optional)
#   cloud::customize_args: arguments to pass to virt-customize (optional)
#   cloud::sysprep_args: arguments to pass to virt-sysprep (optional)
#   cloud::image_package: Package the raw image for the target cloud.
#     This function must be defined either at cloud or cloud/distribution level
#
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
#

#######################################
# Parameter validation
# Globals:
#   BOOT_MODE
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::validate() {
  [[ "${BOOT_MODE,,}" !=  "bios" ]] && common::error "AWS images only supports bios BOOT_MODE"
  [[ ${DISTR_NAME} =~ aarch64$ ]] && common::error "AWS images builder do not support aarch64"
  [[ ${ORACLE_RELEASE} -lt 8 ]] && common::error "AWS images builder only supports OL8 and above"
  :
}

#######################################
# Image packaging - creates a VMDK image
# Globals:
#   VM_NAME, WORKSPACE
# Arguments:
#   None
# Returns:
#   None
#######################################
cloud::image_package() {
  # common::convert_to_raw "${WORKSPACE}/${VM_NAME}/${VM_NAME}.raw" --keep
  # common::convert_to_vhd "${WORKSPACE}/${VM_NAME}/${VM_NAME}.vhd" --keep
  common::convert_to_vmdk "${WORKSPACE}/${VM_NAME}/${VM_NAME}.vmdk"
}
