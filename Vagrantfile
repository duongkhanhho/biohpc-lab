require "fileutils"

VDISK    = "/Applications/VMware Fusion.app/Contents/Library/vmware-vdiskmanager"
DISK_DIR = File.join(__dir__, ".disks")
CTRL     = "sata0" 

def ensure_disk(path, size)
  return if File.exist?(path)
  FileUtils.mkdir_p(DISK_DIR)
  system(VDISK, "-c", "-s", size, "-a", "lsilogic", "-t", "0", path) ||
    abort("Cannot create disk #{path}")
end

NODES = {
  "login01" => { id: 0, mgmt: "10.10.0.10", storage: "10.20.0.10", mem: 2048, disks: 0 },
  "node01"  => { id: 1, mgmt: "10.10.0.11", storage: "10.20.0.11", mem: 2048, disks: 2 },
  "node02"  => { id: 2, mgmt: "10.10.0.12", storage: "10.20.0.12", mem: 2048, disks: 2 },
  "node03"  => { id: 3, mgmt: "10.10.0.13", storage: "10.20.0.13", mem: 2048, disks: 2 },
}

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"
  config.vm.synced_folder ".", "/vagrant", disabled: true

  NODES.each do |name, spec|
    mac_mgmt    = "00:50:56:10:00:1#{spec[:id]}"
    mac_storage = "00:50:56:20:00:1#{spec[:id]}"

    config.vm.define name do |node|
      node.vm.hostname = name

      node.vm.provider "vmware_desktop" do |v|
        v.gui = false
        v.memory = spec[:mem]
        v.cpus = 2
        # Card 2: mạng quản trị (vmnet2)
        v.vmx["ethernet1.present"]        = "TRUE"
        v.vmx["ethernet1.connectionType"] = "custom"
        v.vmx["ethernet1.vnet"]           = "vmnet2"
        v.vmx["ethernet1.virtualDev"]     = "e1000e"
        v.vmx["ethernet1.addressType"]    = "static"
        v.vmx["ethernet1.address"]        = mac_mgmt
        # Card 3: mạng storage (vmnet3)
        v.vmx["ethernet2.present"]        = "TRUE"
        v.vmx["ethernet2.connectionType"] = "custom"
        v.vmx["ethernet2.vnet"]           = "vmnet3"
        v.vmx["ethernet2.virtualDev"]     = "e1000e"
        v.vmx["ethernet2.addressType"]    = "static"
        v.vmx["ethernet2.address"]        = mac_storage

  
                # Đĩa OSD cho Ceph: bắt đầu từ slot 2 vì sata0:1 là CD-ROM của box
        spec[:disks].times do |i|
          disk = File.join(DISK_DIR, "#{name}-osd#{i}.vmdk")
          ensure_disk(disk, "25GB")
          slot = "#{CTRL}:#{i + 2}"
          v.vmx["#{slot}.present"]    = "TRUE"
          v.vmx["#{slot}.deviceType"] = "disk"
          v.vmx["#{slot}.fileName"]   = disk
        end
      end

      node.vm.provision "shell", inline: <<~SHELL
        cat > /etc/netplan/60-cluster.yaml <<EOF
        network:
          version: 2
          ethernets:
            mgmt0:
              match: { macaddress: "#{mac_mgmt}" }
              set-name: mgmt0
              addresses: [#{spec[:mgmt]}/24]
            stor0:
              match: { macaddress: "#{mac_storage}" }
              set-name: stor0
              addresses: [#{spec[:storage]}/24]
        EOF
          chmod 600 /etc/netplan/*.yaml
        netplan apply
      SHELL
    end
  end
end