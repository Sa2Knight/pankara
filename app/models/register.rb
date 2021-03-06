#----------------------------------------------------------------------
# Register - 歌唱履歴を作成する
#----------------------------------------------------------------------
require_relative 'base'
require_relative 'util'
require_relative 'db'
require_relative 'validate'
class Register < Base

  attr_accessor :karaoke , :with_url

  # initialize - インスタンスを生成する
  #---------------------------------------------------------------------
  def initialize(user = nil)
    @user   = user
    @userid = user && user['id']
    @karaoke = nil
    @attendance = nil
    @score_type = nil
    @with_url = true
  end

  # create_karaoke - カラオケ記録を作成する
  #---------------------------------------------------------------------
  def create_karaoke(datetime , name , plan , store , product)

    # 入力値を検証/補正
    Validate.is_datetime?(datetime) or return false
    plan = plan.to_f #時間が0はありえないので0なら拒否
    plan < 0.5 and return Util.error('invalid plan')
    name.strip!

    # カラオケ名が空欄の場合、デフォルト名を付ける
    if name.nil? || name.strip == ''
      name = "#{datetime} のカラオケ"
    end

    # 店名、機種名からそれぞれのIDを取得
    store_id = self.create_store(store)
    product_id = self.get_product(product)

    # karaokeレコードを挿入し、そのIDを取得
    db = DB.new(
      :INSERT => ['karaoke' , ['datetime' , 'name' , 'plan' , 'store' , 'product' , 'created_by']] ,
      :SET => [datetime , name , plan , store_id , product_id , @userid]
    )
    @karaoke = db.execute_insert_id
    log = "【カラオケ登録】#{@karaoke_name}(#{@karaoke}) #{datetime} / #{store}(#{store_id}) / #{product}(#{product_id}) / plan"
    Util.write_log('event' , log)
    return @karaoke
  end

  # set_karaoke - カラオケIDを設定する
  #---------------------------------------------------------------------
  def set_karaoke(id)
    @karaoke = id
  end

  # attend_karaoke - カラオケに参加する 既に参加している場合IDを設定する
  #---------------------------------------------------------------------
  def attend_karaoke(price = nil , memo = nil)
    @karaoke or return
    price and price = price.to_i

    # 既に登録済みの場合、そのIDを戻す
    @attendance = DB.new(
      :SELECT => 'id' ,
      :FROM => 'attendance' ,
      :WHERE => ['user = ?' , 'karaoke = ?'] ,
      :SET => [@userid , @karaoke]
    ).execute_column

    # 未登録の場合はattendanceレコードを挿入し、そのIDを戻す
    if @attendance.nil?
      db = DB.new(
        :INSERT => ['attendance' , ['user' , 'karaoke' , 'price' , 'memo']] ,
        :SET => [@userid , @karaoke , price , memo]
      )
      @attendance = db.execute_insert_id
    end
  end

  # create_history - 歌唱履歴を作成する
  #---------------------------------------------------------------------
  def create_history(song , artist ,  key = 0 , satisfaction_level=nil, score_type=nil , score=nil)
    @attendance or return
    key = key.to_i
    score and score = score.to_f
    song.strip!
    artist.strip!

    # score_typeが定義されており、0以外の得点が設定されてる場合のみスコアを設定
    if score_type.nil? || score_type.to_s == "0" || score.nil? || score.to_i == 0
      score_type = nil
      score = nil
    end
    score or score_type = nil

    # 楽曲/アーティスト/採点モードを取得または作成
    artist_id = create_artist(artist)
    song_id = create_song(artist_id , artist , song)
    scoretype_id = get_scoretype(score_type)

    # 歌唱履歴を作成
    history_id = DB.new(
      :INSERT => ['history' , ['attendance' , 'song' , 'songkey' , 'satisfaction_level', 'score_type' , 'score']] ,
      :SET => [@attendance , song_id , key , satisfaction_level, scoretype_id , score] ,
    ).execute_insert_id

    # 歌唱回数と、何回(何日)ぶりの歌唱かを取得

    # log生成
    log = "【歌唱履歴登録】#{@attendance} / #{song}(#{song_id}) / #{artist}(#{artist_id}) / #{score_type}(#{scoretype_id}) / #{key} / #{score}"
    Util.write_log('event' , log)

    history = History.new(history_id)
    return {
      history_id: history_id,
      song:       song,
      artist:     artist,
      score_type: history['score_type_name'],
      score:      history['score'],
    }.merge(history.result)
  end

  # create_artist - 歌手を新規登録。既出の場合IDを戻す
  #---------------------------------------------------------------------
  def create_artist(name)
    artist_id = DB.new(
      :SELECT => 'id' , :FROM => 'artist' , :WHERE => 'name = ?' , :SET => name
    ).execute_column

    if artist_id
      artist_id
    else
      DB.new(
        :INSERT => ['artist' , ['name']] ,
        :SET => name
      ).execute_insert_id
    end
  end

  # create_song - 曲を新規登録。既出の場合IDを戻す
  #---------------------------------------------------------------------
  def create_song(artist_id , artist_name , song_name)
    song_id = DB.new(
      :SELECT => 'id' , :FROM => 'song' , :WHERE => ['artist = ?' , 'name = ?'] ,
      :SET => [artist_id , song_name]
    ).execute_column

    if song_id
      song_id
    else
      url = @with_url ? Util.search_tube(song_name , artist_name) : nil
      DB.new(
        :INSERT => ['song' , ['artist' , 'name' , 'url']] ,
        :SET => [artist_id , song_name , url] ,
      ).execute_insert_id
    end
  end

  # create_store - 店舗を新規登録。既出の場合IDを戻す
  #---------------------------------------------------------------------
  def create_store(store)

    # 名前の指定が無い場合'未登録'に差し替え
    store['name'].strip!
    store['branch'].strip!
    if store['name'] == ''
      store['name'] = '未登録'
      store['branch'] = ''
    end

    store_id = DB.new(
      :SELECT => 'id' , :FROM => 'store' , :WHERE => ['name = ?' , 'branch = ?'] ,
      :SET => [store['name'] , store['branch']]
    ).execute_column

    if store_id
      store_id
    else
      DB.new(
        :INSERT => ['store' , ['name' , 'branch']] ,
        :SET => [store['name'] , store['branch']] ,
      ).execute_insert_id
    end
  end

  # get_product - 機種名からIDを取得
  #---------------------------------------------------------------------
  def get_product(product)
    product['brand'].strip!
    product['product'].strip!
    product_id = DB.new(
      :SELECT => 'id' , :FROM => 'product' , :WHERE => ['brand = ?' , 'product = ?'] ,
      :SET => [product['brand'] , product['product']]
    ).execute_column
    return product_id ? product_id : false
  end

  # get_scoretype - 採点モードのIDを取得。固定データのため新規登録は無し
  #---------------------------------------------------------------------
  def get_scoretype(score_type)
    score_type or return
    brand = score_type['brand']
    name = score_type['name']
    db = DB.new(
      :SELECT => 'id' , :FROM => 'score_type' , :WHERE => ['brand = ?' , 'name = ?'] ,
      :SET => [brand , name]
    ).execute_column
  end

end
