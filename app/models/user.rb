#----------------------------------------------------------------------
# User - 個々のユーザアカウントに関する情報を操作
#----------------------------------------------------------------------
require_relative 'util'
class User < Base

	# initialize(username:) - usernameを指定してインスタンスを生成
	#---------------------------------------------------------------------
	def initialize(username)
		db = DB.new
		db.from('user')
		db.where('username = ?')
		db.set(username)
		@params = db.execute_row
	end

	# histories - 歌唱履歴を取得、limitを指定するとその行数だけ取得
	#---------------------------------------------------------------------
	def histories(limit = 0)
		db = DB.new
		db.select({
			'karaoke.name' => 'karaoke_name' ,
			'karaoke.datetime' => 'datetime' ,
			'history.song' => 'song' ,
			'history.songkey' => 'songkey'
		})
		db.from('history')
		db.join(
			['history' , 'attendance'] ,
			['attendance' , 'karaoke']
		)
		db.where('attendance.user = ?')
		option = ['ORDER BY datetime DESC']
		# Sa2Knight: 引数が負数の場合にバグる可能性があるからlimit > 0が無難
		option.push("LIMIT #{limit}") if limit.nonzero?
		db.option(option)
		db.set(@params['id'])
		histories = db.execute_all
		histories.each do | history |
			song = Song.new(history['song'])
			history['song_name'] = song.params['name']
			history['artist'] = song.params['artist']
			history['artist_name'] = song.params['artist_name']
		end
		return histories
	end

	# get_karaoke - limitを指定するとその行数だけ取得
	#---------------------------------------------------------------------
	def get_karaoke(limit = 0)
		# 対象ユーザが参加したkaraokeのID一覧を取得
		db = DB.new
		db.select('karaoke')
		db.from('attendance')
		db.where('user = ?')
		db.set(@params['id'])
		attended_id_list = db.execute_all.collect {|info| info['karaoke']}

		# 全karaokeの情報から、ユーザが参加したカラオケについてのみ抽出
		all_karaoke_info = Karaoke.list_all
		attended_karaoke_info = all_karaoke_info.select do |karaoke|
			attended_id_list.include?(karaoke['id'])
		end
		# Sa2Knight: 同様にlimit > 0
		return limit.nonzero? ? attended_karaoke_info[0...limit] : attended_karaoke_info
	end

	# create_karaoke_log - karaokeレコードを挿入し、attendanceレコードを紐付ける
	#---------------------------------------------------------------------
	def create_karaoke_log(params)
		datetime = params[:datetime]
		plan = params[:plan].to_f
		store = params[:store].to_i
		product = params[:product].to_i
		price = params[:price].to_i
		memo = params[:memo]

		db = DB.new
		db.insert('karaoke' , ['datetime' , 'plan' , 'store' , 'product' , 'price' , 'memo'])
		db.set(datetime , plan , store , product , price , memo)
		karaoke_id = db.execute_insert_id

		db = DB.new
		db.insert('attendance' , ['user' , 'karaoke'])
		db.set(@params['id'] , karaoke_id)
		db.execute_insert_id
	end

	# authenticate - クラスメソッド ユーザのIDとパスワードを検証する
	#---------------------------------------------------------------------
	def self.authenticate(name , pw)
		db = DB.new
		db.from('user')
		db.where('username = ?' , 'password = ?')
		db.set(name , pw)
		db.execute_row
	end

	# Sa2Knight - ヘッダーコメントつけて
	def get_most_sang
		most_sang = {}
		# Sa2Knight - ここSQL記述してるけどhistoriesメソッド呼ぶだけじゃダメ？
		db = DB.new
		db.select({'history.song' => 'song'})
		db.from('history')
		db.join(['history', 'attendance'])
		db.where('attendance.user = ?')
		db.set(@params['id'])
		histories = db.execute_all
		# Sa2Knight - 「最も歌った曲」はユーザ自信の情報なわけだから、インスタンスの変数にするべき
		most_sang['song'] = get_most_sang_song histories
		most_sang['artist'] = get_most_sang_artist histories
		most_sang
	end

	# Sa2Knight - ヘッダーコメントつけて
	# Sa2Knight - 外から使われないメソッドはprivateに
	def get_most_sang_song(histories)
		# Sa2Knight - 表の集計ぐらいSQLにやらせよう。
		# COUNT(*) や GROUP BYを使ってSQLだけで一番歌われた曲は取れる
		hash = {}
		histories.each do |history|
			unless hash.has_key? history['song'] then
				hash[history['song']] = 1
			else
				hash[history['song']] += 1
			end
		end
		max = hash.max { |ary1, ary2| ary1[1] <=> ary2[1] }
		most_sang_song_id = hash.key max[1]
		db= DB.new
		db.select('name')
		db.from('song')
		db.where('id = ?')
		db.set(most_sang_song_id)
		most_sang_song_name = db.execute_column
		{'id' => most_sang_song_id, 'name' => most_sang_song_name}
	end

	# Sa2Knight - ヘッダーコメントつけて
	# Sa2Knight - 外から使われないメソッドはprivateに
	def get_most_sang_artist(histories)
		# Sa2Knight - SQLにやらせよう
		artists = []
		db = DB.new
		db.select({'song.artist' => 'artist'})
		db.from('history')
		db.join(['history', 'song'])
		db.where('song.id = ?')
		histories.each do |histroy|
			db.set(histroy['song'])
			artists.push db.execute_column
		end
		hash = {}
		artists.each do |artist|
			unless hash.has_key? artist then
				hash[artist] = 1
			else
				hash[artist] += 1
			end
		end
		max = hash.max { |ary1, ary2| ary1[1] <=> ary2[1] }
		most_sang_artist_id = hash.key max[1]
		db = DB.new
		db.select('name')
		db.from('artist')
		db.where('id = ?')
		db.set(most_sang_artist_id)
		most_sang_artist_name = db.execute_column
		{'id' => most_sang_artist_id, 'name' => most_sang_artist_name}
	end

	# Sa2Knight - ヘッダーコメントつけて
	# Sa2Knight - 基本的には外から呼ばれるメソッドを上に、プライベートなメソッドを下に宣言する。
	#逆でもいいけどどちらかに統一する
	def get_max_score
		# Sa2Knight - これはリクエストだけど、何の曲だったのか、どの採点モードだったのかはわかるべき
		db = DB.new
		db.select({'MAX(history.score)' => 'max_score'})
		db.from('history')
		db.join(['history', 'attendance'])
		db.where('attendance.user = ?')
		db.set(@params['id'])
		db.execute_column
	end

end
