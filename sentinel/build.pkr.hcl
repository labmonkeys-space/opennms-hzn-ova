packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
  }
}

build {
  source "source.qemu.opennms-horizon-sentinel-amd64" {
    name             = "onms-hzn-sentinel"
    iso_url          = local.iso_url_ubuntu_base_2204
    iso_checksum     = "file:${local.iso_checksum_url_ubuntu_base_2204}"
    output_directory = "image"
    accelerator      = "none"
    http_directory   = local.http_directory
  }

  provisioner "ansible-local" {
    playbook_file = "../ansible/hzn-sentinel-deployment.yml"
    extra_arguments = ["-e", "skip_startup=true" ]
    role_paths = [
      "../ansible/roles/opennms_common",
      "../ansible/roles/opennms_sentinel"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "HOME_DIR=/home/ubuntu"
    ]
    execute_command   = "echo 'ubuntu' | {{.Vars}} sudo -S -E sh -eux '{{.Path}}'"
    expect_disconnect = true
    // fileset will list files in etc/scripts sorted in an alphanumerical way.
    scripts = fileset(".", "../scripts/*.sh")
  }

  post-processors {
    post-processor "checksum" {
      checksum_types = ["sha256"]
      output = "image/packer-{{.BuildName}}-{{.ChecksumType}}.sum"
    }

    post-processor "shell-local" {
      inline = ["qemu-img convert image/packer-opennms-horizon-sentinel-amd64 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 image/onms-hzn-sentinel-1.vmdk"]
    }
  }
}
