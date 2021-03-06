require_relative 'ajax_route'

class AjaxDialogRoute < AjaxRoute

  # get '/ajax/dialog/karaoke - カラオケ入力画面を表示
  #---------------------------------------------------------------------
  get '/karaoke' do
    @products = Product.list
    erb :_input_karaoke
  end

  # get '/ajax/dialog/karaoke/:karaoke_id/history - 歌唱履歴の入力画面を表示
  #---------------------------------------------------------------------
  get '/karaoke/:karaoke_id/history' do
    karaoke = Karaoke.new(params[:karaoke_id])
    @score_type = ScoreType.List(wantarray: true, product: karaoke['product_brand'])
    erb :_input_history
  end

  # get '/ajax/dialog/song' - 楽曲新規登録の入力画面を表示
  #--------------------------------------------------------------------
  get '/song' do
    erb :_input_song
  end

end
