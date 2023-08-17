.PHONY: deps image checksum manifest ova clean

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

checksum: image
	@echo "Create VMware file and checksum"
	@cp template.ovf image/onms-hzn.ovf
	@cd image && sha256sum --tag onms-hzn.ovf onms-hzn-1.vmdk > sha256.sum

manifest: checksum
	@echo "Create VMware compatible manifest with custom checksum file"
	@cd image && sed 's/SHA256 (/SHA256(/' sha256.sum | sed 's/) =/)=/' > onms-hzn.mf

ova: manifest
	@echo "Create OVA file"
	@cd image && \
	tar -cvf onms-hzn-vm.ova onms-hzn.ovf onms-hzn.mf onms-hzn-1.vmdk && \
	sha256sum --tag -b onms-hzn-vm.ova > onms-hzn-vm.shasum

clean:
	@echo "Delete image build artifacts"
	@rm -rf image
