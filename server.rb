require "sinatra"
require "pg"
require "pry"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do
  db_connection do |conn|
    @actors_list = conn.exec("SELECT * FROM actors ORDER BY name;").to_a
  end

  erb :index
end

get '/actors/:id' do
  @actor_id = params["id"]
  db_connection do |conn|
    @actor_name = conn.exec("SELECT actors.name FROM actors WHERE '#{@actor_id}' = actors.id;").to_a[0]["name"]
    @actor_info = conn.exec("SELECT movies.title, cast_members.character, movies.id
    FROM actors
    JOIN cast_members ON actors.id = cast_members.actor_id
    JOIN movies ON movies.id = cast_members.movie_id
    WHERE actors.id = '#{@actor_id}';").to_a
  end

  erb :actor
end

get '/movies' do
  db_connection do |conn|
    @movie_list = conn.exec("SELECT movies.title, movies.year, movies.rating, genres.name AS genre, studios.name, movies.id
    FROM movies
    LEFT JOIN genres ON genres.id = movies.genre_id
    LEFT JOIN studios ON studios.id = movies.studio_id
    ORDER BY movies.title;").to_a
  end


  erb :movies
end

get '/movies/:id' do
  @movie_id = params["id"]
  db_connection do |conn|
    @movie_info = conn.exec("SELECT movies.title, cast_members.character, studios.name AS studio, genres.name AS genre, actors.name, actors.id AS actor_id, movies.rating, movies.year
    FROM movies
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON actors.id = cast_members.actor_id
    JOIN studios ON movies.studio_id = studios.id
    JOIN genres ON movies.genre_id = genres.id
    WHERE movies.id = '#{@movie_id}';").to_a
  end

  erb :each_movie
end
