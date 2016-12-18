require 'sinatra'
require './plugins/UDV_Worksheet/master_udv'

get '/UDV_Worksheet/sheet' do
	redirect to("/") unless valid_session?

	if request.referrer =~ /admin/ or params[:admin_view] == "true"
		redirect to("/no_access") if not is_administrator?
		@admin = true
		@report_id = 0

		if params[:delete]
			# delete the id
			DataMapper.repository(:udv) {
				q = Questions.get(params[:delete])
				if q
					q.destroy
				end
				@questions = Questions.all(:report_id => 0)
			}
		end

		DataMapper.repository(:udv) {
			@questions = Questions.all(:report_id => 0)
		}
	else
		if request.referrer =~ /report_pl/
			# grab the questions for report id
			id = request.referrer.split("report_plugins").first.split("/")[-1]
		else
			id = params[:report_id]
		end

	    # Query for the first report matching the id
    	@report = get_report(id)

	    if @report == nil
	        return "No Such Report"
	    end
	    @report_id = id

		DataMapper.repository(:udv) {
			@questions = Questions.all(:report_id => id)
		}

		# if dne create a set for that report id
		if @questions.size == 0
			# replicate all master questions
			DataMapper.repository(:udv) {
				@questions = Questions.all(:report_id => 0)

				@questions.each do |master_q|
				    q = Questions.new
				    q.udv_name = master_q.udv_name
				    q.question = master_q.question
				    q.question_answer = master_q.question_answer
				    q.report_id = id
				    q.save()
				end

				@questions = Questions.all(:report_id => id)
			}
		end
	end

	haml :"../plugins/UDV_Worksheet/views/sheet", :encode_html => true
end

post '/UDV_Worksheet/sheet' do
	redirect to("/") unless valid_session?
    data = url_escape_hash(request.POST)

	if params["admin_view"] == "true"
		redirect to("/no_access") if not is_administrator?
		@report_id = 0

		# todo doesn't handle updates to other questions
	   	DataMapper.repository(:udv) {
		    q = Questions.new
		    q.udv_name = data["udv_name"]
		    q.question = data["question"]
		    q.question_answer = data["question_answer"]
		    q.report_id = 0
		    q.save()

		    @admin = true
			@questions = Questions.all(:report_id => 0)
		}
	else
		# grab the questions for report id
		id = data["report_id"]

	    # Query for the first report matching the id
    	@report = get_report(id)

	    if @report == nil
	        return "No Such Report"
	    end

	    data.each do |key,value|
	    	if key =~ /question_answer/
	    		q_id = key.split("_").last
	    	end
	    	if q_id
			   	DataMapper.repository(:udv){
				    q = Questions.first(:report_id => id, :id => q_id)
				    q.question_answer = value
				    q.save()
				}
			end
	    end

	    DataMapper.repository(:udv){
			@questions = Questions.all(:report_id => id)
		}

		# save to UDVs
	    if  @report.user_defined_variables
    	    @user_variables = JSON.parse(@report.user_defined_variables)
    	else
    		@user_variables = {}
    	end

    	@questions.each do |question|
	    	@user_variables[question.udv_name] = question.question_answer
	    end
		@report.user_defined_variables = @user_variables.to_json
		@report.save
	end

	# redirect back to sheet display
	haml :"../plugins/UDV_Worksheet/views/sheet", :encode_html => true
end
