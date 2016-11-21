require './model/master'
require './helpers/helper'
require './helpers/vuln_importer'
require './helpers/xslt_generation'
require 'nokogiri'
require 'zip'

# todo usage

def convert_docx_xslt(docx)
	# read the docx in
	error = nil
    begin
	    xslt = generate_xslt(docx)
    rescue => e
    	puts e
    	error = e
    end


    if error
        puts "|!| The report template you uploaded threw an error when parsing:#{error}"
        exit
    else
    	return xslt
    end
end


def run(bxml, xsltin)
	# parse burp xml
	findings = parse_burp_xml(File.read("#{bxml}"))["findings"]

	# set the findings to xml
	findings_xml = "<findings_list>"
	findings.each do |finding|
		findings_xml << finding.to_xml
	end
	findings_xml << "</findings_list>"

	# Replace the stub elements with real XML elements; add your Company Name
	findings_xml = meta_markup_unencode(findings_xml, "Company Name")

	# make a report XML
	report_xml = "<report>#{findings_xml}</report>"

	# convert the docx to xslt
	xslt_in = convert_docx_xslt(xsltin)

	# Push the finding from XML to XSLT
	xslt = Nokogiri::XSLT(xslt_in)
	docx_xml = xslt.transform(Nokogiri::XML(report_xml))

	# We use a temporary file with a random name
	rand_file = "./tmp/#{rand(36**12).to_s(36)}.docx"
	FileUtils::copy_file(xsltin,rand_file)

	# build the word document using the results
	docx_modify(rand_file, docx_xml,'word/document.xml')

	puts "|+| Report generated: #{rand_file}"
end

if ARGV.size < 2
	puts "usage:\n\t\truby ba_cli.rb BURP_XML TEMPLATE"
else
	run(ARGV[0],ARGV[1])
end