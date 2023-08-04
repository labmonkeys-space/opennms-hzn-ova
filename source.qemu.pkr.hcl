source "qemu" "base-ubuntu-cloud-amd64" {
  headless         = true
  memory           = 2048
  cpus             = 2
  boot_wait        = "5s"
  disk_compression = true
  disk_image       = true
  disk_size        = "30G"
  disk_interface   = "virtio-scsi"
  format           = "qcow2"
  qemuargs         = [["-smbios", "type=1,serial=ds=nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/"]]
  shutdown_command = "echo 'ubuntu' | sudo -S shutdown -P now"
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  skip_nat_mapping = true
  ssh_port         = 22
  ssh_wait_timeout = "50m"
}
