require 'sinatra'
require 'sqlite3'
require 'json'
require 'pry'
require './lib/pic'
require './lib/post'
require './lib/oldpost'
require './lib/user'
require './lib/connection'
require 'active_record'
require 'bcrypt'
include FileUtils::Verbose
enable :sessions
set :public_folder, './public'
#landing page for user
get '/' do
	puts '/'
	send_file File.join(settings.public_folder, 'index.html')
end
get '/public/bundle.js' do
	puts 'public'
	send_file File.join(settings.public_folder, 'bundle.js')
end
#press page
get '/press.html'
	puts '/press.html'
	send_file File.join(settings.public_folder, 'press.html')
end
#respond to ajax for carousel
get '/pics' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'
	content_type :json
	pics = Pic.order(:carousel)
	pics.to_json
end

#news ajax
get '/news' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'
	content_type :json
	news = Post.where("section = ?", "news").reverse_order
	news.to_json
end

#shows ajax
get '/shows' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'	
	content_type :json
	shows = Post.where("section = ? AND eventdate > ?", "shows", Time.now).order(:eventdate)
	shows.to_json
end

#press ajax
get '/press' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'	
	content_type :json
	press = Post.where("section = ?", "press").reverse_order
	press.to_json
end

#video ajax
get '/videos' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'
	content_type :json
	video = Post.where("section = ?", "videos").reverse_order
	video.to_json
end

#contact ajax
get '/contact' do
	headers 'Access-Control-Allow-Origin' => '*'
	headers 'Access-Control-Allow-Methods' => 'GET'	
	content_type :json
	contact = Post.where("section = ?", "contact").reverse_order
	contact.to_json
end

# does what it says
def authenticated?
	session[:valid_user] == true
end

# log in
get '/admin/login' do
	erb :"admin/login"
end

#create a user
post '/admin/user' do
	if params[:password] != params[:pass_confirm]
		redirect '/admin/login'
	else
		pass = BCrypt::Password.create(params[:password])
		session[:valid_user] = true
		User.create(name: params[:name], password_digest: pass)
		redirect '/admin'
	end
end

#actually log in
post '/admin/session' do
	user = User.find_by(name: params[:name])
	if user
		if BCrypt::Password.new(user.password_digest) == params[:password]
			session[:valid_user] = true
			redirect '/admin'
		else
			redirect '/admin/login'
		end
	else
		redirect '/admin/login'
	end
end

# CRUD pics
get '/admin/pics' do
	puts session[:valid_user]
	if authenticated?
		puts "GET ADMIN/PICS"
		pics = Pic.order(:carousel)
		erb :"admin/pics", locals: {pics: pics}
	else
		redirect '/admin/login'
	end
end

# upload a pic, save the file in public, and add the url and carousel status to the pics table
post '/admin/pic' do
	if authenticated?
		puts "POST ADMIN/PIC"

		if params[:carousel_selection]
			car = params[:carousel_selection]
		else car = 0
		end
		tempfile = params[:file][:tempfile] 
		filename = params[:file][:filename].gsub(" ", "_")
		cp(tempfile.path, "./public/#{filename}")
		Pic.create(url: filename, carousel: car)
		redirect '/admin/pics'
	else
		redirect '/admin/login'
	end
end

# update carousel status of each pic
put '/admin/pics' do
	if authenticated?
		newpics = JSON.parse(params[:pics])

		
		newpics.each do |newpic|
			
			puts "XXXXX"
			puts newpic
			pic = Pic.find_by(id: newpic["id"])
			pic.update(carousel: newpic["carousel"])
			end
		
		redirect '/admin/pics'
	else
		redirect '/admin/login'
	end
end

put '/admin/pic/:id' do
	if authenticated?
		pic = Pic.find_by(id: params[:id].to_i)
		pic.update(carousel: params[:carousel])
		redirect '/admin/pics'
	else
		redirect '/admin/login'
	end
end
# show an individual pic
get '/admin/pic/:id' do
	if authenticated?
		pic = Pic.find_by(id: params[:id])
		erb :"admin/pic", locals: {pic: pic}
	else
		redirect '/admin/login'
	end
end

#DESTROY!
delete '/admin/pic/:id' do
	if authenticated?
		pic = Pic.find_by(id: params[:id])
		filename = pic.url
		pic.delete
		File.delete("./public/#{filename}")
		redirect '/admin/pics'
	else
		redirect '/admin/login'
	end
end

#CRUD posts
get '/admin/posts' do
	if authenticated?
		posts = Post.all()
		erb :"admin/posts", locals: {posts: posts}
	else
		redirect '/admin/login'
	end
end

#show individual post
get '/admin/post/:id' do
	if authenticated?
		post = Post.find_by(id: params[:id])
		pics = Pic.all()
		erb :"admin/post", locals: {post: post, pics: pics}
	else
		redirect '/admin/login'
	end
end

#update post
put '/admin/post' do
	if authenticated?
		puts params
		post = Post.find_by(id: params[:id].to_i)
		post.update(title: params[:title], story: params[:story], section: params[:section])
		redirect '/admin/posts'
	else
		redirect '/admin/login'
	end
end

#create post
post '/admin/post' do
	if authenticated?

		if params[:section] == "shows"
			expire = params[:date] + " 23:59:00"
			Post.create(title: params[:title], story: params[:story], section: params[:section], eventdate: expire)
					binding.pry
			redirect '/admin/posts'
		else params[:section]
			Post.create(title: params[:title], story: params[:story], section: params[:section])
			redirect '/admin/posts'
		end
	else
		redirect '/admin/login'
	end
end

#archive deleted post, delete post in regular post table
delete '/admin/post/:id' do
	if authenticated?
		post = Post.find_by(id: params[:id])
		Oldpost.create(title: post.title, story: post.story, section: post.section)
		post.delete
		redirect '/admin/posts'
	else
		redirect '/admin/login'
	end
end

delete '/admin/logout' do
	session[:valid_user] = false
	redirect '/'
end

#landing page for admin
get '/admin' do
	if authenticated?
		pics = Pic.all()
		erb :"admin/admin", locals: {pics: pics}
	else
		redirect '/admin/login'
	end
end

get '/pic_window' do
	if authenticated?
		pics = Pic.all()
		erb :"admin/pic_window", locals: {pics: pics}
	else
		redirect '/admin/login'
	end
end