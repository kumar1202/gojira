require 'spec_helper'
require 'gojira/cli'
require 'tmpdir'
require 'fileutils'

RSpec.describe 'Gojira Workflow Integration', type: :integration do
  let(:tmp_dir) { Dir.mktmpdir }
  let(:configs_dir) { File.join(tmp_dir, 'configs') }
  let(:clusters_file) { File.join(tmp_dir, 'clusters.yaml') }
  
  before do
    # Create test directory structure
    FileUtils.mkdir_p(File.join(configs_dir, 'dev', 'product1'))
    
    # Create test service files
    File.write(File.join(configs_dir, 'dev', 'product1', 'service1.yaml'), <<~YAML)
      services:
        - name: test-service
          host: test.upstream
          port: 443
          protocol: https
          connect_timeout: 60000
          tags:
            - pci
          routes:
            - name: test-route
              hosts:
                - test.example.com
              paths:
                - /api
              methods:
                - GET
                - POST
    YAML
    
    # Create upstreams file
    File.write(File.join(configs_dir, 'dev', 'product1', 'upstreams.yaml'), <<~YAML)
      test.upstream:
        - delhi:
            - host: backend1.delhi.example.com
              weight: 50
            - host: backend2.delhi.example.com
              weight: 50
        - mumbai:
            - host: backend.mumbai.example.com
              weight: 100
    YAML
    
    # Create clusters file
    File.write(clusters_file, <<~YAML)
      dev:
        dc:
          - delhi
          - mumbai
        control_plane:
          - compliance_type: pci
            dc: delhi
            address: http://localhost:8001
          - compliance_type: non-pci
            dc: delhi
            address: http://localhost:8011
          - compliance_type: pci
            dc: mumbai
            address: http://localhost:8021
          - compliance_type: non-pci
            dc: mumbai
            address: http://localhost:8031
    YAML
  end
  
  after do
    FileUtils.rm_rf(tmp_dir)
  end
  
  describe 'env lint' do
    it 'validates a correct environment configuration' do
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:lint], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file
        })
      }.to output(/Env successfully validated/).to_stdout
    end
    
    it 'fails validation for missing upstreams file' do
      FileUtils.rm(File.join(configs_dir, 'dev', 'product1', 'upstreams.yaml'))
      
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:lint], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file
        })
      }.to raise_error(Thor::Error, /Missing upstreams.yaml/)
    end
    
    it 'fails validation for service without any tags' do
      File.write(File.join(configs_dir, 'dev', 'product1', 'service2.yaml'), <<~YAML)
        services:
          - name: bad-service
            host: bad.upstream
            port: 443
            protocol: https
            tags: []
      YAML
      
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:lint], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file
        })
      }.to raise_error(Thor::Error, /must have at least one tag/)
    end
    
    it 'accepts custom compliance tags' do
      File.write(File.join(configs_dir, 'dev', 'product1', 'service3.yaml'), <<~YAML)
        services:
          - name: internal-service
            host: internal.upstream
            port: 443
            protocol: https
            tags:
              - internal
              - monitoring
      YAML
      
      # Add upstream for the new service
      File.write(File.join(configs_dir, 'dev', 'product1', 'upstreams.yaml'), <<~YAML)
        test.upstream:
          - delhi:
              - host: backend1.delhi.example.com
                weight: 100
        internal.upstream:
          - delhi:
              - host: internal.delhi.example.com
                weight: 100
      YAML
      
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:lint], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file
        })
      }.to output(/Env successfully validated/).to_stdout
    end
  end
  
  describe 'env generate' do
    it 'generates Kong configuration for PCI Delhi' do
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:generate], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file,
          compliance_type: 'pci',
          dc_name: 'delhi'
        })
      }.to output(/Kong configuration generated at:/).to_stdout
      
      generated_file = File.join(configs_dir, 'generated', 'kong-dev-pci-delhi.yaml')
      expect(File.exist?(generated_file)).to be true
      
      config = YAML.load_file(generated_file)
      expect(config['_format_version']).to eq('3.0')
      expect(config['services'].length).to eq(1)
      expect(config['services'][0]['name']).to eq('test-service')
      expect(config['upstreams'].length).to eq(1)
      expect(config['upstreams'][0]['targets'].length).to eq(2)
      expect(config['routes'].length).to eq(1)
    end
    
    it 'filters services by compliance type' do
      # Add a non-pci service
      File.write(File.join(configs_dir, 'dev', 'product1', 'service2.yaml'), <<~YAML)
        services:
          - name: non-pci-service
            host: test.upstream
            port: 443
            protocol: https
            tags:
              - non-pci
      YAML
      
      cli = Gojira::CLI.new
      
      cli.invoke(:env, [:generate], {
        gateway_folder: configs_dir,
        env_name: 'dev',
        cluster_file: clusters_file,
        compliance_type: 'pci',
        dc_name: 'delhi'
      })
      
      generated_file = File.join(configs_dir, 'generated', 'kong-dev-pci-delhi.yaml')
      config = YAML.load_file(generated_file)
      
      # Should only include PCI service
      expect(config['services'].length).to eq(1)
      expect(config['services'][0]['name']).to eq('test-service')
    end
    
    it 'generates correct upstream targets for specific DC' do
      cli = Gojira::CLI.new
      
      # Generate for Mumbai
      cli.invoke(:env, [:generate], {
        gateway_folder: configs_dir,
        env_name: 'dev',
        cluster_file: clusters_file,
        compliance_type: 'pci',
        dc_name: 'mumbai'
      })
      
      generated_file = File.join(configs_dir, 'generated', 'kong-dev-pci-mumbai.yaml')
      config = YAML.load_file(generated_file)
      
      # Should only include Mumbai targets
      expect(config['upstreams'][0]['targets'].length).to eq(1)
      expect(config['upstreams'][0]['targets'][0]['target']).to include('mumbai')
    end
    
    it 'generates configuration for custom compliance types' do
      # Add custom tagged service
      File.write(File.join(configs_dir, 'dev', 'product1', 'internal-service.yaml'), <<~YAML)
        services:
          - name: internal-api
            host: internal.upstream
            port: 443
            protocol: https
            tags:
              - internal
      YAML
      
      # Add upstream for internal service
      File.write(File.join(configs_dir, 'dev', 'product1', 'upstreams.yaml'), <<~YAML)
        test.upstream:
          - delhi:
              - host: backend1.delhi.example.com
                weight: 100
        internal.upstream:
          - delhi:
              - host: internal.delhi.example.com
                weight: 100
      YAML
      
      # Update clusters file to include internal compliance type
      File.write(clusters_file, <<~YAML)
        dev:
          dc:
            - delhi
          control_plane:
            - compliance_type: pci
              dc: delhi
              address: http://localhost:8001
            - compliance_type: internal
              dc: delhi
              address: http://localhost:8011
      YAML
      
      cli = Gojira::CLI.new
      
      expect {
        cli.invoke(:env, [:generate], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file,
          compliance_type: 'internal',
          dc_name: 'delhi'
        })
      }.to output(/Kong configuration generated at:/).to_stdout
      
      generated_file = File.join(configs_dir, 'generated', 'kong-dev-internal-delhi.yaml')
      expect(File.exist?(generated_file)).to be true
      
      config = YAML.load_file(generated_file)
      expect(config['services'].length).to eq(1)
      expect(config['services'][0]['name']).to eq('internal-api')
    end
  end
  
  describe 'full workflow' do
    it 'completes lint and generate for all combinations' do
      cli = Gojira::CLI.new
      
      # First lint
      expect {
        cli.invoke(:env, [:lint], {
          gateway_folder: configs_dir,
          env_name: 'dev',
          cluster_file: clusters_file
        })
      }.to output(/Env successfully validated/).to_stdout
      
      # Then generate for all combinations
      combinations = [
        { compliance_type: 'pci', dc_name: 'delhi' },
        { compliance_type: 'non-pci', dc_name: 'delhi' },
        { compliance_type: 'pci', dc_name: 'mumbai' },
        { compliance_type: 'non-pci', dc_name: 'mumbai' }
      ]
      
      combinations.each do |combo|
        expect {
          cli.invoke(:env, [:generate], {
            gateway_folder: configs_dir,
            env_name: 'dev',
            cluster_file: clusters_file,
            **combo
          })
        }.to output(/Kong configuration generated at:/).to_stdout
        
        generated_file = File.join(configs_dir, 'generated', "kong-dev-#{combo[:compliance_type]}-#{combo[:dc_name]}.yaml")
        expect(File.exist?(generated_file)).to be true
      end
    end
  end
end