# Installs & configure the octavia service
#
# == Parameters
#
# [*enabled*]
#   (optional) Should the service be enabled.
#   Defaults to true
#
# [*manage_service*]
#   (optional) Whether the service should be managed by Puppet.
#   Defaults to true.
#
# [*host*]
#   (optional) The octavia api bind address.
#   Defaults to 0.0.0.0
#
# [*port*]
#   (optional) The octavia api port.
#   Defaults to 9876
#
# [*package_ensure*]
#   (optional) ensure state for package.
#   Defaults to 'present'
#
# [*auth_strategy*]
#   (optional) set authentication mechanism
#   Defaults to 'keystone'
#
# [*sync_db*]
#   (optional) Run octavia-db-manage upgrade head on api nodes after installing the package.
#   Defaults to false

class octavia::api (
  $manage_service        = true,
  $enabled               = true,
  $package_ensure        = 'present',
  $host                  = '0.0.0.0',
  $port                  = '9876',
  $auth_strategy         = 'keystone',
  $sync_db               = false,
) inherits octavia::params {

  include ::octavia::deps
  include ::octavia::policy
  include ::octavia::db

  if $auth_strategy == 'keystone' {
    include ::octavia::keystone::authtoken
  }

  package { 'octavia-api':
    ensure => $package_ensure,
    name   => $::octavia::params::api_package_name,
    tag    => ['openstack', 'octavia-package'],
  }

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  if $sync_db {
    include ::octavia::db::sync
  }

  service { 'octavia-api':
    ensure     => $service_ensure,
    name       => $::octavia::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    tag        => ['octavia-service', 'octavia-db-sync-service'],
  }

  octavia_config {
    'DEFAULT/host'                             : value => $host;
    'DEFAULT/port'                             : value => $port;
    'DEFAULT/auth_strategy'                    : value => $auth_strategy;
  }

}
