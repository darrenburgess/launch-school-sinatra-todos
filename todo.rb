require "sinatra"
require "sinatra/reloader"
require "tilt/erubis"

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists
end

get "/lists/new" do
  erb :new_list, layout: :layout
end

post "/lists" do
  session[:lists] << {name: params[:list_name], todos: []}
  session.each {|name, value| puts "#{name}: #{value}"}
  redirect "/lists"
end
