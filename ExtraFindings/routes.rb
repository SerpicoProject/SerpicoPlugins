require 'sinatra'
require 'json'
require './model/master'

# TODO we should have a way to force setup to occur

get '/ExtraFindings/import' do
	# for now hand write the findings to import
	@sets = []

	# VulnDB: https://github.com/vulndb/data
	a = {}
	a["name"] = "VulnDB"
	a["link"] = "https://github.com/vulndb/data"
	a["license"] = "BSD 3-Clause"
	a["license_link"] = "https://github.com/vulndb/data/blob/master/LICENSE.md"
	@sets.push(a)

	haml :"../plugins/SerpicoPlugins/views/import", :encode_html => true
end

post '/ExtraFindings/import' do
	if params["VulnDB"]
		import_vulndb
		options.finding_types.push("VulnDB")
	end
	@success = "Imported findings"
	haml :"../plugins/SerpicoPlugins/views/import", :encode_html => true
end

# Simple helper method rather than hand cleaning every string
def c(value)
	c_value = value.gsub("\n\n","<paragraph></paragraph>")
	c_value = c_value.gsub("`","'")
	return c_value
end


def import_vulndb()
	# Iterate the VulnDB database
	vulndb_dir = "../plugins/SerpicoPlugins/data/VulnDB/db/"
	Dir.entries(vulndb_dir).each do |json_file|
		next if json_file == "." or json_file == ".."

		# Read in the JSON file and store as json obj
		file = File.read(vulndb_dir+json_file)
		json_data = JSON.parse(file)

		#### Change this portion if the VulnDB Schema changes
		finding = {}
		puts "|+| Importing #{json_data["title"]}"
		finding["title"] = c(json_data["title"])

		finding["overview"] = "<paragraph>"
		finding["overview"] += c(json_data["description"].join(" "))
		finding["overview"] += "</paragraph>"

		if json_data["fix"]["guidance"].kind_of?(Array)
			finding["remediation"] = "<paragraph>"
			finding["remediation"] += c(json_data["fix"]["guidance"].join(" "))
			finding["remediation"] += "</paragraph>"
		else
			finding["remediation"] = c(json_data["fix"]["guidance"])
		end

		finding["references"] = "<paragraph>VulnDB: https://github.com/vulndb/data</paragraph>"
		if json_data["references"] != nil
			json_data["references"].each do |ref|
				finding["references"] += "<paragraph>"+c(ref["url"])+"</paragraph>"
			end
		end

		finding["type"] = "VulnDB"
		finding["approved"] = true

		finding["risk"] = 1 if json_data["severity"] == "informational"
		finding["risk"] = 2 if json_data["severity"] == "low"
		finding["risk"] = 3 if json_data["severity"] == "medium"
		finding["risk"] = 4 if json_data["severity"] == "high"

		# TODO: add a true DREAD score calculator
		finding["damage"] = 1
		finding["reproducability"] = 1
		finding["exploitability"] = 1
		finding["affected_users"] = 1
		finding["discoverability"] = 1
		finding["dread_total"] = 5
		####

		# write the database
	    finding_db = TemplateFindings.create(finding)
	    finding_db.save
	end
end
