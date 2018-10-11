require 'sinatra'
require './plugins/TestPlugin/helpers/testplugin_listener'

PluginNotifier.instance.attach_plugin(TestPluginListener.new)

# List current reports
get '/TestPlugin/hello' do
	haml :'../plugins/TestPlugin/views/test_plugin', :encode_html => true
end
