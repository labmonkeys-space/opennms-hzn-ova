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
	@cp template.ovf image/onms-hzn-core.ovf
	@cd image && shasum -a 256 --tag onms-hzn-core.ovf onms-hzn-core-1.vmdk > sha256.sum

manifest: checksum
	@echo "Create VMware compatible manifest with custom checksum file"
	@cd image && sed 's/SHA256 (/SHA256(/' sha256.sum | sed 's/) =/)=/' > onms-hzn-core.mf

ova: manifest
	@echo "Create OVA file"
	@cd image && \
	tar -cvf onms-hzn-core-vm.ova onms-hzn-core.ovf onms-hzn-core.mf onms-hzn-core-1.vmdk && \
	shasum -a 256 --tag -b onms-hzn-core-vm.ova > onms-hzn-core-vm.shasum

clean:
	@echo "Delete image build artifacts"
	@rm -rf image
