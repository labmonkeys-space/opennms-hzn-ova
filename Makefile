.PHONY: deps image vmdk ova clean

.DEFAULT_GOAL := ova

deps:
	@command -v packer
	@command -v qemu-system-x86_64
	@command -v qemu-img

image: deps
	@echo "Build QEMU x86_64 image"
	@packer init .
	@packer validate .
	@packer build .

vmdk: image
	@echo "Convert to VMware disk image"
	@qemu-img convert image/packer-base-ubuntu-cloud-amd64 -O vmdk -o adapter_type=lsilogic,subformat=streamOptimized,compat6 image/onms-hzn-0.vmdk

manifest: vmdk
	@echo "Create VMware file and manifest"
	@cp template.ovf image/onms-hzn.ovf
	@cd image && sha256sum --tag onms-hzn.ovf onms-hzn-0.vmdk > onms-hzn.mf

ova: manifest
	@echo "Create OVA file"
	@cd image && \
	tar -cvf onms-hzn-vm.ova onms-hzn.ovf onms-hzn.mf onms-hzn-0.vmdk && \
	sha256sum --tag -b onms-hzn-vm.ova > onms-hzn-vm.shasum

clean:
	@echo "Delete image build artifacts"
	@rm -rf image
