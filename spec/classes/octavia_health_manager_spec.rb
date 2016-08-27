require 'spec_helper'

describe 'octavia::health_manager' do

  let :params do
    { :enabled        => true,
      :manage_service => true,
      :package_ensure => 'latest',
      :heartbeat_key  => 'default_key'
    }
  end

  shared_examples_for 'octavia-health-manager' do

    context 'without a heartbeat key' do
      before { params.delete(:heartbeat_key) }
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'with an invalid value for heartbeat key' do
      before do
        params.merge!({
          :heartbeat_key => 0,
        })
      end
      it { expect { is_expected.to raise_error(Puppet::Error) } }
    end

    context 'with minimal parameters' do
      before do
        params.merge!({
          :heartbeat_key => 'abcdefghi',
        })
      end
      it { is_expected.to contain_octavia_config('health_manager/heartbeat_key').with_value('abcdefghi') }
    end

    it 'installs octavia-health-manager package' do
      is_expected.to contain_package('octavia-health-manager').with(
        :ensure => 'latest',
        :name   => platform_params[:health_manager_package_name],
        :tag    => ['openstack', 'octavia-package'],
      )
    end

    [{:enabled => true}, {:enabled => false}].each do |param_hash|
      context "when service should be #{param_hash[:enabled] ? 'enabled' : 'disabled'}" do
        before do
          params.merge!(param_hash)
        end

        it 'configures octavia-health-manager service' do
          is_expected.to contain_service('octavia-health-manager').with(
            :ensure     => (params[:manage_service] && params[:enabled]) ? 'running' : 'stopped',
            :name       => platform_params[:health_manager_service_name],
            :enable     => params[:enabled],
            :hasstatus  => true,
            :hasrestart => true,
            :tag        => ['octavia-service'],
          )
        end
      end
    end

    context 'with disabled service managing' do
      before do
        params.merge!({
          :manage_service => false,
          :enabled        => false })
      end

      it 'configures octavia-health-manager service' do
        is_expected.to contain_service('octavia-health-manager').with(
          :ensure     => nil,
          :name       => platform_params[:health_manager_service_name],
          :enable     => false,
          :hasstatus  => true,
          :hasrestart => true,
          :tag        => ['octavia-service'],
        )
      end
    end

  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts())
      end
      let(:platform_params) do
        case facts[:osfamily]
        when 'Debian'
          { :health_manager_package_name => 'octavia-health-manager',
            :health_manager_service_name => 'octavia-health-manager' }
        when 'RedHat'
          { :health_manager_package_name => 'openstack-octavia-health-manager',
            :health_manager_service_name => 'octavia-health-manager' }
        end
      end
      it_behaves_like 'octavia-health-manager'
    end
  end

end