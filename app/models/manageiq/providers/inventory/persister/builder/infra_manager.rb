module ManageIQ::Providers
  class Inventory::Persister
    class Builder
      class InfraManager < ::ManageIQ::Providers::Inventory::Persister::Builder
        def networks
          add_properties(
            :manager_ref                  => %i(hardware ipaddress ipv6address),
            :parent_inventory_collections => %i(vms miq_templates),
          )
        end

        def host_networks
          add_properties(
            :model_class                  => ::Network,
            :manager_ref                  => %i(hardware ipaddress),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def guest_devices
          add_properties(
            :manager_ref                  => %i(hardware uid_ems),
            :parent_inventory_collections => %i(vms miq_templates),
          )
        end

        def host_guest_devices
          add_properties(
            :model_class                  => ::GuestDevice,
            :manager_ref                  => %i(hardware uid_ems),
            :parent_inventory_collections => %i(hosts),
          )
        end

        def host_hardwares
          add_properties(
            :model_class                  => ::Hardware,
            :manager_ref                  => %i(host),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def host_system_services
          add_properties(
            :model_class                  => ::SystemService,
            :manager_ref                  => %i(host name),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def snapshots
          add_properties(
            :manager_ref                  => %i(vm_or_template uid),
            :parent_inventory_collections => %i(vms miq_templates),
          )
        end

        def host_operating_systems
          add_properties(
            :model_class                  => ::OperatingSystem,
            :manager_ref                  => %i(host),
            :parent_inventory_collections => %i(hosts),
          )
        end

        def ems_custom_attributes
          add_properties(
            :model_class                  => ::CustomAttribute,
            :manager_ref                  => %i(name),
            :parent_inventory_collections => %i(vms miq_templates),
          )
        end

        def vm_and_template_ems_custom_fields
          skip_auto_inventory_attributes

          add_properties(
            :model_class                  => ::CustomAttribute,
            :manager_ref                  => %i(name),
            :parent_inventory_collections => %i(vms)
          )

          add_inventory_attributes(%i(section name value source resource))
        end

        def ems_folders
          add_properties(
            :manager_ref          => %i(uid_ems),
            :attributes_blacklist => %i(ems_children),
          )
          add_common_default_values
        end

        def datacenters
          add_common_default_values
        end

        def resource_pools
          add_properties(
            :manager_ref          => %i(uid_ems),
            :attributes_blacklist => %i(ems_children),
          )
          add_common_default_values
        end

        def ems_clusters
          add_properties(
            :attributes_blacklist => %i(ems_children datacenter_id),
          )

          add_inventory_attributes(%i(datacenter_id))
          add_common_default_values
        end

        def storages
          add_properties(
            :manager_ref => %i(location),
            :complete    => false,
            :arel        => Storage,
          )
        end

        def hosts
          add_common_default_values

          add_custom_reconnect_block(
            lambda do |inventory_collection, inventory_objects_index, attributes_index|
              relation = inventory_collection.model_class.where(:ems_id => nil)

              return if relation.count <= 0

              inventory_objects_index.each_slice(100) do |batch|
                relation.where(inventory_collection.manager_ref.first => batch.map(&:first)).each do |record|
                  index = inventory_collection.object_index_with_keys(inventory_collection.manager_ref_to_cols, record)

                  # We need to delete the record from the inventory_objects_index and attributes_index, otherwise it
                  # would be sent for create.
                  inventory_object = inventory_objects_index.delete(index)
                  hash             = attributes_index.delete(index)

                  record.assign_attributes(hash.except(:id, :type))
                  if !inventory_collection.check_changed? || record.changed?
                    record.save!
                    inventory_collection.store_updated_records(record)
                  end

                  inventory_object.id = record.id
                end
              end
            end
          )
        end

        def vms
          super

          custom_reconnect_block = lambda do |inventory_collection, inventory_objects_index, attributes_index|
            relation = inventory_collection.model_class.where(:ems_id => nil)

            return if relation.count <= 0

            inventory_objects_index.each_slice(100) do |batch|
              relation.where(inventory_collection.manager_ref.first => batch.map(&:first)).each do |record|
                index = inventory_collection.object_index_with_keys(inventory_collection.manager_ref_to_cols, record)

                # We need to delete the record from the inventory_objects_index and attributes_index, otherwise it
                # would be sent for create.
                inventory_object = inventory_objects_index.delete(index)
                hash = attributes_index.delete(index)

                record.assign_attributes(hash.except(:id, :type))
                if !inventory_collection.check_changed? || record.changed?
                  record.save!
                  inventory_collection.store_updated_records(record)
                end

                inventory_object.id = record.id
              end
            end
          end

          add_properties(
            :custom_reconnect_block => custom_reconnect_block
          )
        end

        def host_storages
          add_properties(
            :manager_ref                  => %i(host storage),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def host_switches
          add_properties(
            :manager_ref                  => %i(host switch),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def host_virtual_switches
          add_properties(
            :manager_ref                  => %i(host uid_ems),
            :model_class                  => Switch,
            :parent_inventory_collections => %i(hosts)
          )
        end

        def distributed_virtual_switches
          add_properties(
            :manager_ref => %i(uid_ems)
          )
          add_common_default_values
        end

        def lans
          add_properties(
            :manager_ref                  => %i(switch uid_ems),
            :parent_inventory_collections => %i(hosts),
          )
        end

        def subnets
          add_properties(
            :manager_ref                  => %i(lan ems_ref),
            :parent_inventory_collections => %i(hosts),
          )
        end

        def customization_specs
          add_properties(:manager_ref => %i(name))

          add_common_default_values
        end

        def miq_scsi_luns
          add_properties(
            :manager_ref                  => %i(miq_scsi_target uid_ems),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def miq_scsi_targets
          add_properties(
            :manager_ref                  => %i(guest_device uid_ems),
            :parent_inventory_collections => %i(hosts)
          )
        end

        def storage_profiles
          add_common_default_values
        end

        def root_folder_relationship
          skip_auto_inventory_attributes
          skip_model_class

          add_properties(
            :custom_save_block => root_folder_relationship_save_block
          )

          add_dependency_attributes(
            :ems_folders => ->(persister) { [persister.collections[:ems_folders]] },
          )
        end

        private

        def root_folder_relationship_save_block
          lambda do |ems, inventory_collection|
            folder_inv_collection = inventory_collection.dependency_attributes[:ems_folders]&.first
            return if folder_inv_collection.nil?

            # All folders must have a parent except for the root folder
            root_folder_obj = folder_inv_collection.data.detect { |obj| obj.data[:parent].nil? }
            return if root_folder_obj.nil?

            root_folder = folder_inv_collection.model_class.find(root_folder_obj.id)
            root_folder.with_relationship_type(:ems_metadata) { root_folder.parent = ems }
          end
        end

        def relationship_save_block(relationship_key, relationship_type, parent_type)
          lambda do |_ems, inventory_collection|
            children_by_parent = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }
            parent_by_child    = Hash.new { |h, k| h[k] = {} }

            inventory_collection.dependency_attributes.each_value do |dependency_collections|
              next if dependency_collections.blank?

              dependency_collections.each do |collection|
                next if collection.blank?

                collection.data.each do |obj|
                  parent = obj.data[relationship_key].try(&:load)
                  next if parent.nil?

                  parent_klass = parent.inventory_collection.model_class

                  children_by_parent[parent_klass][parent.id] << [collection.model_class, obj.id]
                  parent_by_child[collection.model_class][obj.id] = [parent_klass, parent.id]
                end
              end
            end

            ActiveRecord::Base.transaction do
              child_recs = parent_by_child.each_with_object({}) do |(model_class, child_ids), hash|
                hash[model_class] = model_class.find(child_ids.keys).index_by(&:id)
              end

              children_to_remove = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }
              children_to_add    = Hash.new { |h, k| h[k] = Hash.new { |hh, kk| hh[kk] = [] } }

              parent_recs_needed = Hash.new { |h, k| h[k] = [] }

              child_recs.each do |model_class, children_by_id|
                children_by_id.each_value do |child|
                  new_parent_klass, new_parent_id = parent_by_child[model_class][child.id]
                  prev_parent = child.with_relationship_type(relationship_type) { child.parents(:of_type => parent_type)&.first }

                  next if prev_parent && (prev_parent.class.base_class == new_parent_klass && prev_parent.id == new_parent_id)

                  children_to_remove[prev_parent.class.base_class][prev_parent.id] << child if prev_parent
                  children_to_add[new_parent_klass][new_parent_id] << child

                  parent_recs_needed[prev_parent.class.base_class] << prev_parent.id if prev_parent
                  parent_recs_needed[new_parent_klass] << new_parent_id
                end
              end

              parent_recs = parent_recs_needed.each_with_object({}) do |(model_class, parent_ids), hash|
                hash[model_class] = model_class.find(parent_ids.uniq)
              end

              parent_recs.each do |model_class, parents|
                parents.each do |parent|
                  old_children = children_to_remove[model_class][parent.id]
                  new_children = children_to_add[model_class][parent.id]

                  parent.remove_children(old_children) if old_children.present?
                  parent.add_children(new_children) if new_children.present?
                end
              end
            end
          end
        end
      end
    end
  end
end
