module VagrantPlugins
  module ProviderKvm
    module Action
      class SetNetworkName
        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::action::vm::setnetworkname")
          @app = app
        end

        def call(env)
          options = nil
          env[:machine].config.vm.networks.each do |type, network_options|
            options = network_options if type == :private_network
          end
          network_name=options[:network_name]
          if not network_name.nil?
            @logger.info("Setting the name of the Network: #{network_name}")
            env[:machine].provider.driver.set_network_name(network_name)
          end
          @app.call(env)
        end
      end
    end
  end
end

