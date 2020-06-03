NAME=test
IMAGE_NAME=$(NAME)
VM_NAME=$(NAME)
POOL_NAME=default
NETWORK_NAME=default
MEMORY_SIZE_M=512
CORES_NUM=2

DEPLOY_TARGET=test.vm

# do nothing when no target for make
frst:

# generate ssh key
ssh-key:
	mkdir -p ./out
	rm -f ./out/id_rsa ./out/id_rsa.pub
	ssh-keygen -t rsa -f ./out/id_rsa -N ""
	chmod go= ./out/id_rsa

# build bare disk image
image:
	mkdir -p ./out
	nix-build -A bare-disk-image -o ./out/disk-image

# create vm from the disk image
vm-create:
	virsh vol-create-as default $(IMAGE_NAME) 0 --format qcow2
	virsh vol-upload --pool $(POOL_NAME) $(IMAGE_NAME) ./out/disk-image/nixos.qcow2
	virt-install \
	  --name $(VM_NAME) \
	  --memory $(MEMORY_SIZE_M) \
	  --vcpus cores=$(CORES_NUM) \
	  --disk vol=$(POOL_NAME)/$(IMAGE_NAME),bus=virtio \
	  --network network=$(NETWORK_NAME),model=virtio \
	  --os-variant none \
	  --install no_install=yes \
	  --noautoconsole

# delete vm
vm-delete:
	virsh destroy $(VM_NAME) || true
	virsh undefine $(VM_NAME) || true
	virsh vol-delete --pool $(POOL_NAME) $(IMAGE_NAME) || true

# monitor dhcp leases
ip:
	while true; do virsh domifaddr $(VM_NAME); sleep 1; done

# deploy to the vm without rebooting
deploy-switch:
	nix-build -A machine.system
	SSHOPTS="-F ./sshconfig" ../deploy.sh ./result $(DEPLOY_TARGET) switch

# deploy to the vm with rebooting
deploy-reboot:
	nix-build -A machine.system
	SSHOPTS="-F ./sshconfig" ../deploy.sh ./result $(DEPLOY_TARGET) reboot