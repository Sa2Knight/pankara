require_relative './march'

class LocalRoute < March

  # post '/local/rpc/songlist' - 楽曲一覧を戻す
  #---------------------------------------------------------------------
  post '/local/rpc/songlist/?' do
    Util.to_json(Song.list.collect { |song| song['name'] }.sort)
  end

  # post '/local/rpc/artistlist' - 歌手一覧を戻す
  #---------------------------------------------------------------------
  post '/local/rpc/artistlist/?' do
    Util.to_json(Artist.list.collect { |artist| artist['name'] }.sort)
  end

  # post '/local/rpc/storelist' - 店と店舗のリストをJSONで戻す
  #---------------------------------------------------------------------
  post '/local/rpc/storelist/?' do
    Util.to_json(Store.list)
  end

end
