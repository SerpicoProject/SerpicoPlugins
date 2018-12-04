require './helpers/plugin_listener'

class TestPluginListener < PluginListener
  def notify_report_generated(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

    plugin_xml = "<testplugin>"
    # Generate some extra XML to be added in the report if necessary
    # if not, you can safely delete this method
    plugin_xml << "</testplugin>"
    return plugin_xml
  end

  def notify_report_deleted(report_object)
    # This should never happend since the notify method is called from safe locations, but we never know
    if !report_object
      return
    end

    # Cleanup the local database if necessary
    # if not, you can safely delete this method
    return
  end
end
