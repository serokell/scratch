frst:

BASE_POOL_NAME=default

mk-data-dir:
	mkdir -p ./data

ssh-key: mk-data-dir
	rm -f ./data/id_rsa ./data/id_rsa.pub
	ssh-keygen -t rsa -f ./data/id_rsa -N ""
	chmod go= ./data/id_rsa

image: mk-data-dir
	nix-build -A bare-disk-image -o ./data/nixos-base-image

base-nixos: image
	virsh vol-delete --pool ${BASE_POOL_NAME} base-nixos || true
	virsh vol-create-as ${BASE_POOL_NAME} base-nixos 0 --format qcow2
	virsh vol-upload --pool ${BASE_POOL_NAME} base-nixos ./data/nixos-base-image/nixos.qcow2

fetch-ubuntu-focal:
	mkdir -p ./data/ubuntu
	curl --output-dir ./data/ubuntu --remote-name https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

base-ubuntu: mk-data-dir
	virsh vol-delete --pool ${BASE_POOL_NAME} base-ubuntu || true
	virsh vol-create-as ${BASE_POOL_NAME} base-ubuntu 0 --format qcow2
	virsh vol-upload --pool ${BASE_POOL_NAME} base-ubuntu ./data/ubuntu/focal-server-cloudimg-amd64.img

cloud-init-ubuntu: mk-data-dir
	nix-build -A ubuntu-cloud-init -o ./data/cloud-init-ubuntu.cfg

apply:
	terraform apply -auto-approve

destroy:
	terraform destroy -auto-approve

re: destroy apply

build: mk-data-dir
	nix-build -A deployment -o ./data/deployment.json

deploy: mk-data-dir
	nix-build -A deployment -o ./data/deployment.json
	./scripts/deploy-all.py ./data/deployment.json switch

deploy-reboot: mk-data-dir
	nix-build -A deployment -o ./data/deployment.json
	./scripts/deploy-all.py ./data/deployment.json reboot
