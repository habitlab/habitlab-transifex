require 'spec_helper'

require 'json'
require 'pathname'
require 'rack/test'

include Txgh

describe 'integration tests', integration: true do
  include Rack::Test::Methods

  def app
    @app ||= Txgh::Hooks.new
  end

  around(:each) do |example|
    Dir.chdir('./spec/integration') do
      example.run
    end
  end

  let(:payload_path) do
    Pathname(File.dirname(__FILE__)).join('payloads')
  end

  let(:github_postbody) do
    File.read(payload_path.join('github_postbody.json'))
  end

  let(:github_postbody_release) do
    File.read(payload_path.join('github_postbody_release.json'))
  end

  let(:github_postbody_l10n) do
    File.read(payload_path.join('github_postbody_l10n.json'))
  end

  let(:project_name) { 'test-project-88' }
  let(:repo_name) { 'txgh-bot/txgh-test-resources' }

  let(:config) do
    Txgh::KeyManager.config_from(project_name, repo_name)
  end

  def sign_with(body)
    header(
      GithubRequestAuth::GITHUB_HEADER,
      GithubRequestAuth.header(body, config.github_repo.webhook_secret)
    )
  end

  it 'loads correct project config' do
    expect(config.project_config).to_not be_nil
  end

  it 'verifies the transifex hook endpoint works' do
    VCR.use_cassette('transifex_hook_endpoint') do
      data = '{"project": "test-project-88","resource": "samplepo","language": "el_GR","translated": 100}'
      post '/transifex', JSON.parse(data)
      expect(last_response).to be_ok
    end
  end

  it 'verifies the github hook endpoint works' do
    VCR.use_cassette('github_hook_endpoint') do
      sign_with(github_postbody)
      header 'content-type', 'application/x-www-form-urlencoded'
      post '/github', github_postbody
      expect(last_response).to be_ok
    end
  end

  it 'verifies the github release hook endpoint works' do
    VCR.use_cassette('github_release_hook_endpoint') do
      sign_with(github_postbody_release)
      header 'content-type', 'application/x-www-form-urlencoded'
      post '/github', github_postbody_release
      expect(last_response).to be_ok
    end
  end

  it 'verifies the github l10n hook endpoint works' do
    VCR.use_cassette('github_l10n_hook_endpoint') do
      sign_with(github_postbody_l10n)
      header 'content-type', 'application/x-www-form-urlencoded'
      post '/github', github_postbody_l10n
      expect(last_response).to be_ok
    end
  end
end