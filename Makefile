.PHONY: deps image vmdk clean

.DEFAULT_GOAL := vmdk

deps:
	@command -v packer
	@command -v qemu-system-x86_64
	@command -v qemu-img
	@command -v ovftool

image: deps
	@echo "Build QEMU x86_64 image"
	@packer build .

vmdk: image
	@echo "Convert to VMware disk image"
	@qemu-img convert image/packer-base-ubuntu-cloud-amd64 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 image/onms-hzn-disk01.vmdk

ova: vmdk
	@echo "Create OVA file"
	@cp template.ovf image/onms-hzn.ovf && cd image
	@ovftool onms-hzn.ovf onms-hzn-vm.ova

clean:
	@echo "Delete image build artifacts"
	@rm -rf image
