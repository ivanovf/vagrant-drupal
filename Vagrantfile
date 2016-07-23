dir = File.dirname(File.expand_path(__FILE__))

require 'yaml'
require "#{dir}/ruby/deep_merge.rb"

configValues = YAML.load_file("#{dir}/config.yaml")

custom = configValues

Dir.glob("#{dir}/sities/*.yaml").each do |file|
	sities = YAML.load_file(file)
	custom.deep_merge!(sities)
end

File.open("#{dir}/config-custom.yaml", 'w') {|f| f.write custom.to_yaml } #Store

if File.file?("#{dir}/config-custom.yaml")
  custom = YAML.load_file("#{dir}/config-custom.yaml")
  configValues.deep_merge!(custom)
end

if File.file?("#{dir}/config-custom.yaml")
  custom = YAML.load_file("#{dir}/config-custom.yaml")
  configValues.deep_merge!(custom)
end

data = configValues['vagrantfile']

Vagrant.require_version '>= 1.6.0'

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-6.8"

  config.ssh.forward_agent = true
  config.ssh.insert_key = false
  
  ENV['VAGRANT_DEFAULT_PROVIDER'] = 'virtualbox'

  config.vm.provider :virtualbox do |virtualbox|
    virtualbox.cpus = 2
    virtualbox.gui = true

    virtualbox.customize ["modifyvm", :id, "--memory", "2048"]
    virtualbox.customize ['modifyvm', :id, '--name', config.vm.hostname]

    data['vm']['synced_folder'].each do |i, folder|
      virtualbox.customize ['setextradata', :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate//#{i}", '1']
    end
  end

  if data['vm']['network']['private_network'].to_s != ''
    config.vm.network 'private_network', ip: "#{data['vm']['network']['private_network']}"
  end

  if data['vm']['network']['public_network'].to_s != ''
    config.vm.network 'public_network'
    if data['vm']['network']['public_network'].to_s != '1'
      config.vm.network 'public_network', ip: "#{data['vm']['network']['public_network']}"
    end
  end

  data['vm']['network']['forwarded_port'].each do |i, port|
    if port['guest'] != '' && port['host'] != ''
      config.vm.network :forwarded_port, guest: port['guest'].to_i, host: port['host'].to_i
    end
  end

  data['vm']['synced_folder'].each do |i, folder|
    if folder['source'] != '' && folder['target'] != ''
      sync_owner = !folder['owner'].nil? ? folder['owner'] : 'vagrant'
      sync_group = !folder['group'].nil? ? folder['group'] : 'vagrant'

      if folder['sync_type'] == 'nfs'
        if Vagrant.has_plugin?('vagrant-bindfs')
          config.vm.synced_folder "#{folder['source']}", "/mnt/vagrant-#{i}", id: "#{i}", type: 'nfs'
          config.bindfs.bind_folder "/mnt/vagrant-#{i}", "#{folder['target']}", owner: sync_owner, group: sync_group, perms: "u=rwX:g=rwX:o=rwX"
        else
          config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}", type: 'nfs'
        end
      else
        config.vm.synced_folder "#{folder['source']}", "#{folder['target']}", id: "#{i}",
          group: sync_group, owner: sync_owner, mount_options: ['dmode=777', 'fmode=777']
      end
    end
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "#{dir}/ansible/playbook.yml"
  end
  
end
