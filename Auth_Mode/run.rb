if File.file?("#{Dir.pwd()}/plugins/Auth_Mode/installed")
	class Server < Sinatra::Application
		def is_administrator?
			return true
		end

		def valid_session?
			return true
		end

		def is_plugin?
			return true
		end

	end
else
	puts "|!| Failed to load AuthMode, see the README for installation instructions."
end