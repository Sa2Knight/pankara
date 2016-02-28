require_relative './march'

class LocalRoute < March

  # success - 正常を通知するJSONを戻す
  #--------------------------------------------------------------------
  def success
    return Util.to_json({:result => 'success'})
  end

  # error - 異常を通知するJSONを戻す
  #--------------------------------------------------------------------
  def error(info = '')
    return Util.to_json({:result => 'error' , :info => info})
  end

  # post '/local/rpc/songlist' - 楽曲一覧を戻す
  #---------------------------------------------------------------------
  get '/local/rpc/songlist/?' do
    hash = Hash.new
    Song.list.each do |s|
      hash[s['song_name']] = s['artist_name']
    end
    return Util.to_json(hash)
  end

  # post '/local/rpc/storelist' - 店と店舗のリストをJSONで戻す
  #---------------------------------------------------------------------
  post '/local/rpc/storelist/?' do
    Util.to_json(Store.list)
  end

  # post '/local/rpc/karaokelist/?' - カラオケの一覧もしくは指定したカラオケを戻す
  #---------------------------------------------------------------------
  post '/local/rpc/karaokelist/?' do
    params[:id].nil? ? Util.to_json(Karaoke.list_all) : Util.to_json(Karaoke.new(params[:id], true).params)
  end

  # post '/local/rpc/historylist/?' - 歌唱履歴の一覧もしくは指定した歌唱履歴を戻す
  #---------------------------------------------------------------------
  post '/local/rpc/historylist/?' do
    params[:id].nil? ? Util.to_json(History.recent_song) : Util.to_json(History.new(params[:id], true).params)
  end

  # post '/local/rpc/karaoke/delete/?' - カラオケを削除する
  #--------------------------------------------------------------------
  post '/local/rpc/karaoke/delete/?' do
    karaoke = Karaoke.new(params[:id])
    karaoke.params or return error('no record')
    karaoke.delete
    return success
  end

  # post '/local/rpc/karaoke/modify/?' - カラオケを編集する
  #--------------------------------------------------------------------
  post '/local/rpc/karaoke/modify/?' do
    karaoke = Karaoke.new(params[:id])
    karaoke.params or return error('no record')
    arg = Util.to_hash(params[:params])
    result = karaoke.modify(arg)
    return result ? success : error('modify failed')
  end

  # post '/local/rpc/history/delete/?' - 歌唱履歴を削除する
  #--------------------------------------------------------------------
  post '/local/rpc/history/delete/?' do
    history = History.new(params[:id])
    history.params or return error('no record')
    history.delete
    return success
  end

  # post '/local/rpc/history/modify/?' - 歌唱履歴を編集する
  #--------------------------------------------------------------------
  post '/local/rpc/history/modify/?' do
    history = History.new(params[:id])
    history.params or return error('no record')
    arg = Util.to_hash(params[:params])
    result = history.modify(arg)
    return result ? success : error('modify failed')
  end


end
