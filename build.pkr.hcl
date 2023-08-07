packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
  }
}

build {
  source "source.qemu.base-ubuntu-cloud-amd64" {
    name                    = "onms-hzn"
    iso_url                 = local.iso_url_ubuntu_cloud_2204
    iso_checksum            = "file:${local.iso_checksum_url_ubuntu_cloud_2204}"
    output_directory        = "image"
    accelerator             = "none"
    http_directory          = local.http_directory
  }

  provisioner "shell" {
    environment_vars  = [
      "DEBIAN_FRONTEND=noninteractive",
      "HOME_DIR=/home/ubuntu",
      "POSTGRESQL_VERSION=14*",
      "OPENJDK_VERSION=17",
      "ONMS_HZN_VERSION=32.0.1*",
      "ONMS_MIRROR=debian.opennms.org",
      "ONMS_RELEASE=stable",
      "ONMS_JRRD2_VERSION=2.*"
    ]
    execute_command   = "echo 'ubuntu' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    expect_disconnect = true
    // fileset will list files in etc/scripts sorted in an alphanumerical way.
    scripts           = fileset(".", "scripts/*.sh")
  }
}
