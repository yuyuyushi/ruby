require 'sinatra'
require 'dm-core'
require 'dm-migrations'
require './student'
require './comment'

configure do
  enable :sessions
  set :username, "admin" 
  set :password, "admin"
end

configure :development do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/development.db")
    DataMapper.auto_upgrade!
end

configure :production do
    DataMapper.setup(:default, ENV['DATABASE_URL'])
    DataMapper.auto_upgrade!
end

get '/' do
  @comments = Comment.all
  erb :home
end

get '/about' do
  @title = "All About This Website"
  erb :about
end

get '/contact' do
  @title = "Contact"
  erb :contact
end

get '/students' do
  if session[:admin]
    @students = Student.all
    @title = "Students"
    erb :students
  else
    session[:from_comments] = false
    session[:from_students] = true
    redirect to ('/login')
  end
end

get '/students/add' do
  @title = "Add Student"
  halt(401, 'Please login first') unless session[:admin]
  erb :add_student
end

post '/students/add' do
  student = Student.create(params[:student])
    redirect to("/students/#{student.stdid}")
end

get '/students/:stdid' do
  halt(401, 'Please login first') unless session[:admin]
  @student = Student.get(params[:stdid])
  @title = "#{@student.firstname} #{@student.lastname}"
  erb :showstudent
end

get '/students/:stdid/edit' do
  halt(401, 'Please login first') unless session[:admin]
  @student = Student.get(params[:stdid])
  @title = "Edit Student"
  erb :editstudent
end

post '/students/:stdid/edit' do
  student = Student.get(params[:stdid])
  student.update(params[:student])
  redirect to("/students/#{student.stdid}")
end

get '/students/:stdid/delete' do
  halt(401, 'Please login first') unless session[:admin]
  Student.get(params[:stdid]).destroy
  redirect to("/students")
end

get '/comments' do
  @comments = Comment.all
  @title = "Comments"
  erb :comments
end

get '/comments/new' do
  @title = "New Comment"
  erb :newcomment
end

post '/comments/new' do
  comment = Comment.create(params[:comment])
  redirect to("/comments/#{comment.id}")
end

get '/comments/:id' do
  @comment = Comment.get(params[:id])
  @title = "Comment"
  erb :showcomment
end

get '/comments/:id/edit' do
  if session[:admin]
    @comment = Comment.get(params[:id])
    @title = "#{@comment.comment_body}"
    erb :editcomment
  else
    session[:from_comments] = true
    session[:from_students] = false
    redirect to ('/login')
  end
end

post '/comments/:id/edit' do
  comment = Comment.get(params[:id])
  comment.update(params[:comment])
  redirect to("/comments/#{comment.id}")
end

get '/comments/:id/delete' do
  halt(401, 'Please login first') unless session[:admin]
  Comment.get(params[:id]).destroy
  redirect to("/comments")
end

get '/video' do
  @title = "Video"
	erb :video
end

get '/login' do
  @title = "Login"
	erb :login
end

post '/login' do
  if params[:username] == settings.username && params[:password] == settings.password
    session[:admin] = true
    if session[:from_students]
      redirect to("/students")
    elsif session[:from_comments]
      redirect to("/comments")
    else
      redirect to("/")
    end
  else
    @title = "Login"
    erb :login
  end
end

get '/logout' do
  session.clear
  redirect to ("/")
end