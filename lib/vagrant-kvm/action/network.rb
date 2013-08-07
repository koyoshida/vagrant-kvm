require "log4r"

module VagrantPlugins
  module ProviderKvm
    module Action
      # This middleware class configures networking
      class Network

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::kvm::network")
          @app    = app
        end

        def call(env)
          @env = env

          hostonly_network_options = Array.new
          private_network_options = Array.new
          public_network_options = Array.new

          env[:machine].config.vm.networks.each do |type, network_options|
            hostonly_network_options << network_options if type == :forwarded_port
            private_network_options << network_options if type == :private_network
            public_network_options << network_options if type == :public_network
          end

          # setup hostonly network and port_forwarding
          hostonly_network_options.each do |options|
            # XXX: TBD
            # Define virbr2 for hostonly network
            # hostonly.xml =>  192.168.123.0/24
          end

          # start private networks
          # it may be in another network subnet with virbr{0,1}
          private_network_options.each do |options|
            options = set_private_network_options(options)
            if check_private_network_segment(options)
              options[:hosts] = private_network_hosts(env,options)
              env[:ui].info I18n.t("vagrant.actions.vm.network.preparing")
              env[:machine].provider.driver.create_network(options)
              # add nic to vm
              addr = options[:ip].split(".")
              host = options[:hosts][0]
              nic = { :mac => host[:mac], :network => "vagrant-"+addr[2].to_s}
              env[:machine].provider.driver.add_nic(nic)
              env[:machine_ip] = options[:ip]
            else
              @logger.info ("Ignore invalid private network definition.")
            end
          end

          # start public networks
          public_network_options.each do |options|
            # XXX: TBD
            # bind interface to bridge virbr1 for public.
            # address may be 192.168.100.0/24
          end

          @app.call(env)
        end

        def private_network_hosts(env,options)
            hosts = []
            name = env[:machine].provider_config.name ?
                      env[:machine].provider_config.name : "default"
            hosts << {
              :mac => format_mac(env[:machine].config.vm.base_mac),
              :name => name,
              :ip => options[:ip]
            }
        end

        # check options[:ip] is not in segment of virbr{0|1}
        def check_private_network_segment(options)
          if options.has_key?(:ip)
            addr = options[:ip].split(".")
            return false if addr[2] == '122' || addr[2] == '100' #virbr{0|1}
          end
        true
        end

        def set_private_network_options(options)
          if options.has_key?(:ip)
            addr = options[:ip].split(".")
            addr[3] = "1"
            base_ip = addr.join(".")
            addr[3] = "100"
            start_ip = addr.join(".")
            addr[3] = "200"
            end_ip = addr.join(".")
            range = {
              :start => start_ip,
              :end   => end_ip }
            options = {
              :base_ip => base_ip,
              :netmask => "255.255.255.0",
              :range   => range,
              :name    => "vagrant-" + addr[2].to_s,
              :domain_name => "vagrant.local"
            }.merge(options)
          else
            options = {
              :name        => "vagrant-default",
              :domain_name => "vagrant.local"
            }.merge(options)
          end
          options
        end

        def format_mac(mac)
          if mac.length == 12
            mac = mac[0..1] + ":" + mac[2..3] + ":" +
              mac[4..5] + ":" + mac[6..7] + ":" +
              mac[8..9] + ":" + mac[10..11]
          end
          mac
        end

      end
    end
  end
end
