module VagrantPlugins
  module ProviderKvm
    module Util
      class SnapshotDefinition

        include Errors

        # base_disk can be 'device' or 'file'
        def initialize(base_disk)
          @base_disk = base_disk
        end

        # as_libvirt(name, new_disk, desc)
        #
        # new_disk should be 'disk file'
        #
        # @return [String]
        def as_libvirt(name, new_disk, desc='Create Snapshot')
         xml = KvmTemplateRenderer.render("libvirt_snapshotdomain", {
            :name => name,
            :description => desc,
            :disks => [
                      {:old => @base_disk, :new => new_disk}
                     ]
          })
          xml
        end
      end
    end
  end
end
