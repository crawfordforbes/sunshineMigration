require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'json'
require 'pry'
require './lib/pic'
require './lib/post'
require './lib/user'
require './lib/connection'
require 'active_record'
include FileUtils::Verbose


get '/' do
	all_posts = Post.all()
	erb(:index, locals: {all_posts: all_posts})
end

get '/admin/pics' do
	puts "GET ADMIN/PICS"
	pics = Pic.all()
	erb :"pics/pics", locals: {pics: pics}
end

post '/admin/pic' do
	puts "POST ADMIN/PIC"

	if params[:carousel_selection]
		car = 1
	else car = 0
	end
	tempfile = params[:file][:tempfile] 
	filename = params[:file][:filename] 
	cp(tempfile.path, "./public/#{filename}")
	Pic.create(url: filename, carousel: car)
	redirect '/admin/pics'
end

put '/admin/pics' do
	puts "xxxxxxxxxxxxx"

	checked_string = params.keys[0].split(',')
	checked = []
	checked_string.each do |id| 
		checked<<id.to_i
	end
	puts checked
	pics = Pic.all()
	pics.each do |pic|
		x = 0
		while x < checked.length do
			if pic.id == checked[x]
				puts "in if: pic id = #{pic.id}, x = #{x}"
				pic.update(carousel: 1)
				x = checked.length
			else 
				puts "in else: pic id = #{pic.id}, x = #{x}"
				pic.update(carousel: 0)
				x += 1
			end
		end
	end
redirect '/admin/pics'
end


get '/admin/pic/:id' do
	pic = Pic.find_by(id: params[:id])
	erb :"pics/pic", locals: {pic: pic}
end

delete '/admin/pic/:id' do
	pic = Pic.find_by(id: params[:id])
	filename = pic.url
	pic.delete
	File.delete("./public/#{filename}")
	redirect '/admin/pics'
end

get '/admin' do
	erb :"admin/admin"
end