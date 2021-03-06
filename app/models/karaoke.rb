#----------------------------------------------------------------------
# Karaoke - カラオケ記録に関する情報を操作
#----------------------------------------------------------------------
require_relative 'base'
require_relative 'util'
require_relative 'db'
require_relative 'store'
require_relative 'product'
require_relative 'register'
require_relative 'song'
require_relative 'attendance'
class Karaoke < Base

  attr_reader :histories

  # initialize - インスタンスを生成し、機種名、店舗名を取得する
  #---------------------------------------------------------------------
  def initialize(id , opt = {})
    # レコードを取得せずにインスタンスを生成
    if opt[:id_only]
      @params = {'id' => id}
      return
    end
    @params = DB.new.get('karaoke' , id)
    @params or return nil

    product = Product.new(@params['product'])
    @params['product_brand'] = product.params['brand']
    @params['product_name'] = product.params['product']
    @params['product_full_name'] = "#{product.params['brand']}(#{product.params['product']})"

    store = Store.new(@params['store'])
    @params['store_name'] = store.params['name']
    @params['branch_name'] = store.params['branch']
    @params['store_full_name'] = "#{store.params['name']} #{store.params['branch']}"
  end

  # modify - カラオケレコードを修正する
  #---------------------------------------------------------------------
  def modify(arg)

    # 店名と店舗名の指定がある場合、storeに置き換える
    if  arg['store_name'] && arg['store_branch']
      r = Register.new
      arg['store'] = r.create_store({'name' => arg['store_name'] ,'branch' => arg['store_branch']})
    end

    arg.select! do |k , v| 
      ['name' , 'datetime' , 'plan' , 'store' , 'product'].include?(k) && v.to_s != ""
    end
    DB.new(
      :UPDATE => ['karaoke' , arg.keys] , 
      :WHERE => 'id = ?' ,
      :SET => arg.values.push(@params['id'])
    ).execute or return false
    old_params = @params
    @params = DB.new.get('karaoke' , old_params['id'])
    Util.write_log('event' , "【カラオケ修正】#{old_params} → #{@params}")
    return true
  end

  # delete - カラオケレコードを削除する
  #--------------------------------------------------------------------
  def delete

    # 参照されているattendanceレコードを削除する
    attendances = DB.new(
      :SELECT => {'attendance.id' => 'id'} ,
      :FROM => 'attendance' ,
      :JOIN => ['attendance' , 'karaoke'] ,
      :WHERE => 'karaoke.id = ?' ,
      :SET => @params['id']
    ).execute_columns or return false
    attendances.each do |id|
      attendance = Attendance.new(id)
      attendance.delete or return false
    end

    # karaokeレコードを削除する
    DB.new(:DELETE => 1 , :FROM => 'karaoke' , :WHERE => 'id = ?' , :SET => @params['id']).execute
    Util.write_log('event' , "【カラオケ削除】#{@params}")
    @params = nil
    return true
  end

  # url - カラオケ詳細画面のURLを取得
  #--------------------------------------------------------------------
  def url
    Util.url('karaoke' , 'detail' , @params['id'])
  end

  # get_members - カラオケに参加しているユーザ一覧を取得する
  #--------------------------------------------------------------------
  def get_members
    DB.new(
      :SELECT => {
        'attendance.id' => 'attendance',
        'attendance.price' => 'price',
        'attendance.memo' => 'memo',
        'user.id' => 'userid',
        'user.username' => 'username',
        'user.screenname' => 'screenname',
      },
      :FROM => 'attendance',
      :JOIN => ['attendance' , 'user'],
      :WHERE => 'attendance.karaoke = ?',
      :SET => @params['id'],
    ).execute_all
  end

  # get_history - カラオケ記録に対応した歌唱履歴を取得する
  #---------------------------------------------------------------------
  def get_history
    # karaokeに参加しているユーザ一覧を取得
    @params['members'] = []
    users_info = Util.array_to_hash(self.get_members , 'attendance')
    @histories = DB.new(
      :SELECT => {
        'history.id' => 'history_id' ,
        'history.created_at' => 'history_datetime' ,
        'history.attendance' => 'history_attendance' ,
        'history.song' => 'song' ,
        'history.satisfaction_level' => 'satisfaction_level',
        'history.songkey' => 'songkey' ,
        'history.score_type' => 'score_type' ,
        'history.score' => 'score',
      } ,
      :FROM => 'history' ,
      :WHERE_IN => ['history.attendance' , users_info.length] ,
      :SET => users_info.keys ,
      :OPTION => 'ORDER BY history.created_at'
    ).execute_all
    @histories.empty? and return []

    # historiesに含まれる楽曲情報を取得
    song_id_list = @histories.map {|h| h['song']}
    songs_info = Song.list({:songs => song_id_list, :artist_info => true , :want_hash => true})
    @histories.each do | history |
      history.merge! songs_info[history['song']] || {}
      # Todo ほとんど同じユーザなのにhistoryごとにuserinfoが入るのは無駄だな
      history['userinfo'] = users_info[history['history_attendance']]
      history['scoretype_name'] = ScoreType.id_to_name(history['score_type'])
    end

    # Todo リストを渡して集計するメソッドを作ったら良さそう

    # 全体の集計
    scores = @histories.select {|h| h['score']}.map {|h| h['score']}
    if scores.size > 0
      @params['max_score'] = scores.max
      @params['avg_score'] = scores.inject(0.0) {|r,h| r += h} / scores.size
    end
    @params['sang_count'] = @histories.count
    artists = @histories.map {|h| h['artist_id']}
    @params['artist_count'] = artists.uniq.count

    # ユーザーごとの集計
    users_info.values.each do |member|
      membersHistory = @histories.select {|h| h['history_attendance'] == member['attendance']}
      if membersHistory.size > 0
        # 歌唱回数
        member['sang_count'] = membersHistory.count
        scores = membersHistory.select {|h| h['score']}.map {|h| h['score']}
        # 最も歌われた歌手
        artists = membersHistory.map {|h| h['artist_id']}
        member['artist_count'] = artists.uniq.count
        # 最高点と平均点
        if scores.size > 0
          member['max_score'] = scores.max
          member['avg_score'] = scores.inject(0.0) {|r,h| r += h} / scores.size
        end
        # 平均満足度
        satisfaction_total = membersHistory.inject(0.0) do |r,h|
          if h['satisfaction_level']
            r += h['satisfaction_level']
          else
            r += 0
          end
        end
        member['satisfaction_level'] = satisfaction_total / membersHistory.size
      end
    end
    @params['members'] = users_info.values
  end

  # result - カラオケ登録に関する各種集計情報を取得
  # 計算コストが高いメソッドなので同時多数では呼ばないように
  #---------------------------------------------------------------------
  def result(opt = {})
    return {
      id:       @params['id'],
      name:     @params['name'],
      datetime: @params['datetime'],
      plan:     @params['plan'],
      product:  @params['product_full_name'],
      store:    @params['store_full_name'],
      url:      self.url,
    }
  end

  # list_all - カラオケ記録の一覧を全て取得し、店舗名まで取得する
  #---------------------------------------------------------------------
  def self.list_all(opt = {})
    list = DB.new(
      :SELECT =>  {
        'karaoke.id' => 'id' ,
        'karaoke.name' => 'name' ,
        'karaoke.datetime' => 'datetime' ,
        'karaoke.plan' => 'plan' ,
        'karaoke.store' => 'store' ,
        'karaoke.product' => 'product_id' ,
        'store.name' => 'store_name' ,
        'store.branch' => 'branch_name' ,
        'product.brand' => 'brand_name' ,
        'product.product' => 'product_name'
      } ,
      :FROM => 'karaoke' ,
      :JOIN => [
        ['karaoke' , 'store'] ,
        ['karaoke' , 'product'] ,
      ] ,
      :OPTION => 'ORDER BY datetime DESC'
    ).execute_all

    # 参加者情報を取得
    if opt[:with_attendance]
      list.each do |karaoke|
        k = Karaoke.new(karaoke['id'] , {:id_only => true})
        karaoke['members'] = k.get_members
      end
    end

    # 楽曲登録数を取得
    if opt[:with_sang_count]
      counts_array = DB.new(
        :SELECT => {
          'attendance.karaoke' => 'karaoke_id',
          'count(history.id)' => 'sang_count',
        },
        :FROM => 'history' ,
        :JOIN => ['history' , 'attendance'] ,
        :OPTION => 'GROUP BY attendance.karaoke'
      ).execute_all
      counts_hash = Util.array_to_hash(counts_array , 'karaoke_id' , true)
      list.each do |karaoke|
        karaoke['sang_count'] = counts_hash[karaoke['id']] ? counts_hash[karaoke['id']]['sang_count'] : 0
      end
    end
    return list
  end

  # list - カラオケレコードの一覧を取得(list_allの簡易版)
  #--------------------------------------------------------------------
  def self.list(opt = {})
    db = DB.new(
      :SELECT => {
        'id' => 'karaoke_id',
        'name' => 'karaoke_name',
        'datetime' => 'karaoke_datetime',
        'plan' => 'karaoke_plan',
        'store' => 'karaoke_store',
        'product' => 'karaoke_product',
      },
      :FROM => 'karaoke',
    )

    # 対象のkaraokeを指定
    if ids = opt[:ids]
      db.where_in(['id' , ids.length])
      db.set(ids)
    end

    # 特定の月を対象にする
    if opt[:year] && opt[:month]
      month = sprintf('%d-%02d' , opt[:year].to_i , opt[:month].to_i)
      db.where('datetime like ?')
      db.set("#{month}%")
    end

    list = db.execute_all

    # 参加者情報を取得する
    if opt[:with_attendance]
      list.each do |karaoke|
        k = Karaoke.new(karaoke['karaoke_id'] , {:id_only => true})
        karaoke['members'] = k.get_members
      end
    end

    return list
  end
end
