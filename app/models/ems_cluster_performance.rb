class EmsClusterPerformance < MetricRollup
  default_scope { where("resource_type = 'EmsCluster' and resource_id IS NOT NULL") }

  belongs_to :ems_cluster, :foreign_key => :resource_id

  def self.display_name(number = 1)
    n_('Cluster Performance', 'Cluster Performances', number)
  end
end
