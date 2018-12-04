require 'sinatra'

# upload Excel file to be transformed in udvs and udos
get '/excel_to_variables' do
  report_id = params[:report_id]
  # Query for the first report matching the id
  @report = get_report(report_id)
  return 'No Such Report' if @report.nil?

  haml :'../plugins/ExcelToVariables/views/excel_to_variables'
end

# upload Excel file to be transformed in udvs and udos
post '/excel_to_variables' do
  report_id = params[:report_id]
  # Query for the first report matching the id
  @report = get_report(report_id)
  return 'No Such Report' if @report.nil?
  sent_file_data = params[:file][:tempfile].read
  shared_strings_noko = Nokogiri::XML(read_rels(params[:file][:tempfile], 'xl/sharedStrings.xml'))
  excel_worksheets = find_excel_worksheets(params[:file][:tempfile])
  excel_worksheets.each do |worksheet_path_in_zip|
    worksheet_xml = read_rels(params[:file][:tempfile], worksheet_path_in_zip)
    sheet_noko = Nokogiri::XML(worksheet_xml)
    # for every cell that has a shared string... (<v> contains the id of the shared string in excel)
    debug = []
    sheet_noko.xpath('//xmlns:worksheet/xmlns:sheetData/xmlns:row/xmlns:c[xmlns:v]').each do |c|
      #if it's a shared string cell
      if c['t'] == 's'
        # We get the shared string value of the current
        cell_value = get_shared_string_value(c, shared_strings_noko)
      #if it's not a ss cell
      else
        cell_value = c.at_xpath('./xmlns:v').content
      end
      # code part for udos. udos are between æ
      if cell_value.include?('æ'.force_encoding('ASCII-8BIT'))
        #we look into the next row for the udo values
        udo_type = cell_value.tr('æ'.force_encoding('ASCII-8BIT'),'')
        next_row = c.at_xpath('./following::xmlns:row')
        udo_properties = {}
        next unless next_row
        next_row.xpath('./xmlns:c[xmlns:v]').each do |c_from_next_row|
          cell_value_from_next_row = get_shared_string_value(c_from_next_row, shared_strings_noko)
          #strign between π is the property name. Value in the cell to the right is the property value
          if cell_value_from_next_row.include?('π'.force_encoding('ASCII-8BIT'))
            udo_property_name = cell_value_from_next_row.tr('π'.force_encoding('ASCII-8BIT'),'')
            c_from_next_row_index = c_from_next_row['r']
            letter_part = c_from_next_row_index.tr('0-9', '')
            number_part = c_from_next_row_index.tr('A-Z', '')
            c_containing_property_value = sheet_noko.at_xpath("//xmlns:worksheet/xmlns:sheetData/xmlns:row/xmlns:c[@r=\"#{letter_part.next!}#{number_part}\"]")
            if c_containing_property_value && c_containing_property_value.at_xpath('./xmlns:v')
              #if it's not a shared string
              if c_containing_property_value['t'] == 's'
                next_cell_shared_string_value = get_shared_string_value(c_containing_property_value, shared_strings_noko)
              #if it's a shared string cell
              else
                next_cell_shared_string_value = c_containing_property_value.at_xpath('./xmlns:v').content
              end
              udo_property_value = next_cell_shared_string_value
            else
              udo_property_value = ''
            end
            if udo_property_value =~ /\r\n/
              paragraphed_udo_property_value = ''
              brs = udo_property_value.split("\r\n")
              brs.each do |br|
                paragraphed_udo_property_value << '<paragraph>'
                paragraphed_udo_property_value << CGI.escapeHTML(br)
                paragraphed_udo_property_value << '</paragraph>'
              end
              udo_property_value = paragraphed_udo_property_value
            elsif udo_property_value != ''
              udo_property_value = "<paragraph>#{CGI.escapeHTML(udo_property_value.force_encoding('UTF-8'))}</paragraph>"
            end
            #what an encoding mess
            udo_properties[udo_property_name] = "#{udo_property_value.force_encoding('UTF-8')}"
          end
        end
        debug << udo_properties
        udo_template_id = false
        UserDefinedObjectTemplates.all().each do |udo_template|
          #we get the properties of the template. If they match with the udo we'ry trying to build, the template already exists
          if udo_type == udo_template.type
            if JSON.parse(udo_template.udo_properties).keys.sort == udo_properties.keys.sort
              udo_template_id = udo_template.id
            end
          end
        end
        #if we didn't find any matching udo template, we create a new one
        #return udo_properties.inspect
        if not udo_template_id
          new_udo_template = UserDefinedObjectTemplates.new
          new_udo_template.type = udo_type
          #creating the template with properties from excel emptied
          new_udo_template.udo_properties = udo_properties.map { |k, str| [k, ""] }.to_h.to_json
          if new_udo_template.save
            #save successfull
            udo_template_id = new_udo_template.id
          else
            return "<p>The following error(s) were found while trying to create udo template : </p>#{new_udo_template.errors.full_messages.flatten.join(', ')}<p>"
          end
        end
        #now, if udo doesn't exist yet, we create the udo and link it to the created/found udo template
        udo_already_exist = false
        UserDefinedObjects.all(type: udo_type, report_id: @report.id).each do |already_existing_udo|
          if JSON.parse(already_existing_udo.udo_properties) == udo_properties
            udo_already_exist = true
            next
          end
        end
        if not udo_already_exist
          new_udo = UserDefinedObjects.new
          new_udo.type = udo_type
          new_udo.udo_properties = udo_properties.to_json
          new_udo.template_id = udo_template_id
          new_udo.report_id = @report.id
          if new_udo.save
            #save successfull
          else
            return "<p>The following error(s) were found while trying to create udo template : </p>#{new_udo.errors.full_messages.flatten.join(', ')}<p>"
          end
        end
      #### UDV PART
      elsif cell_value.include?('§'.force_encoding('ASCII-8BIT'))
        udv_name = cell_value.tr('§'.force_encoding('ASCII-8BIT'),'')
        c_index = c['r']
        letter_part = c_index.tr('0-9', '')
        number_part = c_index.tr('A-Z', '')
        c_containing_udv_value = sheet_noko.at_xpath("//xmlns:worksheet/xmlns:sheetData/xmlns:row/xmlns:c[@r=\"#{letter_part.next!}#{number_part}\"]")
        if c_containing_udv_value && c_containing_udv_value.at_xpath('./xmlns:v')
          #if it's a shared string
          if c_containing_udv_value['t'] == 's'
            next_cell_shared_string_value = get_shared_string_value(c_containing_udv_value, shared_strings_noko)
          #if it's not a shared string cell
          else
            next_cell_shared_string_value = c_containing_udv_value.at_xpath('./xmlns:v').content
          end
          udv_value = next_cell_shared_string_value
        else
          udv_value = ''
        end
        if not @report.user_defined_variables.nil?
          udvs_from_report = JSON.parse(@report.user_defined_variables)
        else
          udvs_from_report = {}
        end
        udvs_from_report[udv_name] = udv_value
        if @report.update(user_defined_variables: udvs_from_report.to_json)
          #save successfull
        else
          return "<p>The following error(s) were found while trying to update report : </p>#{@report.errors.full_messages.flatten.join(', ')}<p>"
        end
      end
    end
  end
  haml :'../plugins/ExcelToVariables/views/excel_to_variables'
end

# returns the shared string value of a sheet cell
def get_shared_string_value(sheet_cell, shared_strings_noko)
  # ...We take the id of the shared string contained by the cell
  shared_string_id = sheet_cell.at_xpath('xmlns:v').content
  # ...we look in the shared strings file the corresponding value
  shared_string_value = shared_strings_noko.at_xpath("/xmlns:sst/xmlns:si[#{shared_string_id.to_i + 1}]/xmlns:t").content.to_s.force_encoding('ASCII-8BIT')
end

def find_excel_worksheets(excel)
  worksheets = []
  Zip::File.open(excel) do |zip|
    i = 1
    until zip.find_entry("xl/worksheets/sheet#{i}.xml").nil?
      worksheets.push("xl/worksheets/sheet#{i}.xml")
      i += 1
    end
  end
  worksheets
end
