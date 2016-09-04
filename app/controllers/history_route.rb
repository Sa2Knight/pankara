require_relative './march'
require_relative '../models/user'
require_relative '../models/pager'

class HistoryRoute < March

  # get '/history - ログイン中のユーザの歌唱履歴を表示
  #---------------------------------------------------------------------
  get '/' do
    @current_user and redirect "/history/#{@current_user['username']}"
  end

  # get '/history/:username - ユーザの歌唱履歴を表示
  #---------------------------------------------------------------------
  get '/:username' do

    # ページャ準備
    page = params[:page] ? params[:page].to_i : 1
    @pager = Pager.new(50 , page)
    opt = {:pager => @pager , :song_info => true}

    # ユーザクラスから歌唱履歴を取得して一覧表示
    @user = User.new(params[:username])
    @histories = @user.histories(opt)

    # 表示範囲の情報
    @history_size = @pager.data_num
    @show_from = @pager.data_num - @histories[0]['number'].to_i + 1
    @show_to = @pager.data_num - @histories[-1]['number'].to_i + 1

    erb :history

  end

end
