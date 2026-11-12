export VAGRANT_DEFAULT_PROVIDER=vmware_desktop

.PHONY: up destroy status suspend resume halt ssh-config

up:
	vagrant up
	vagrant ssh-config > ssh_config

destroy:
	vagrant destroy -f
	rm -rf .disks

status:
	vagrant status

suspend:
	vagrant suspend

resume:
	vagrant resume

halt:
	vagrant halt