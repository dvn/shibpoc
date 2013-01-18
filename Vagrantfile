# http://vagrantup.com/v1/docs/vagrantfile.html
# # vi:ft=ruby:

Vagrant::Config.run do |config|
  config.vm.box = "centos"
  config.vm.box_url = "https://dl.dropbox.com/u/7225008/Vagrant/CentOS-6.3-x86_64-minimal.box"

  #config.vm.network :hostonly, "33.33.33.10"
  #config.vm.forward_port 80, 9999

  config.vm.customize ["modifyvm", :id, "--name", "shibpoc", "--memory", 1024]

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "manifests"
    puppet.module_path = "modules"
    puppet.manifest_file  = "init.pp"
  end
end
