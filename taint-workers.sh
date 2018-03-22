#! /usr/bin/env sh

# This shellscript taints all workers, since terraform can't use wildcard when
# tainting modules
# Ref: https://github.com/hashicorp/terraform/issues/16651

set -e

terraform taint -module=linux_workers "aws_instance.linux.0"
terraform taint -module=linux_workers "aws_instance.linux.1"
terraform taint -module=linux_workers "aws_instance.linux.2"
terraform taint -module=linux_workers "aws_instance.linux.3"
terraform taint -module=linux_workers "aws_instance.linux.4"
terraform taint -module=windows_workers "aws_instance.windows.0"
terraform taint -module=windows_workers "aws_instance.windows.1"
terraform taint -module=windows_workers "aws_instance.windows.2"
terraform taint -module=windows_workers "aws_instance.windows.3"
terraform taint -module=windows_workers "aws_instance.windows.4"
