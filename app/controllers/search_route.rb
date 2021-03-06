require_relative './march'
require_relative '../models/song'
require_relative '../models/tag'
require_relative '../models/user'

class SearchRoute < March

  # get '/search/keyword/:search_word' - 楽曲/歌手/タグ/ユーザを検索する
  #--------------------------------------------------------------------
  get '/keyword/?' do
    @search_word = params[:search_word] || ""
    @song_list = []
    @artist_list = []
    @tag_list = []
    @users = []

    if @search_word.size > 0
      # 該当する楽曲、歌手、タグの一覧を取得
      @song_list.concat(Song.list({:name_like => @search_word , :artist_info => true}))
      @artist_list.concat(Artist.list({:name_like => @search_word}))
      @tag_list.concat(Tag.tags(:like => @search_word , :class => 's'))
      @users = User.search(@search_word)

      # 全体で１件しかヒットしなかった場合、そのページにリダイレクト
      if @song_list.size + @artist_list.size + @tag_list.size + @users.size == 1
        if @song_list.size == 1
          redirect "/song/#{@song_list[0]['song_id']}"
        elsif @artist_list.size == 1
          redirect "/artist/#{@artist_list[0]['id']}"
        elsif @tag_list.size == 1
          redirect "/search/tag/?tag=#{@tag_list[0]}"
        else
          redirect "/user/userpage/#{@users[0]['username']}"
        end
      end
    end

    erb :search
  end

  # get '/search/tag/' - タグ検索
  # 現在は楽曲のみにタグが振られていることを想定
  #--------------------------------------------------------------------
  get '/tag/?' do
    @tag = params[:tag] || ""
    @song_list = []
    @columns = Util.is_pc? ? 3 : 1
    if @tag.size > 0
      song_ids = Tag.search('s' , @tag)
      song_ids.size > 0 and @song_list = Song.list(:artist_info => true, :songs => song_ids , :sort => 'name')
    end
    erb :search_tag
  end

  # get '/search/tag_list' - タグ一覧
  # あまり良いRoutingではないかもしれない
  #--------------------------------------------------------------------
  get '/tag_list/?' do
    @tags = Tag.tags_with_objects_count
    erb :tag_list
  end

end
