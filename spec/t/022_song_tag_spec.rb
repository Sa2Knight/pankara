require_relative '../rbase'
include Rbase

# テスト用データベース構築
init = proc do
  `zenra init -d 2016_08_18_07_12`
end

# テスト実行
describe 'タグ機能' , :js => true do
  before(:all , &init)
  before do
    login 'sa2knight'
  end

  # タグを登録
  def add_tag(tag)
    js "$('#add_tag').click();"; wait_for_ajax
    script = "$('#popup_prompt').val('#{tag}')"
    js script; wait_for_ajax
    find('#popup_ok').click; wait_for_ajax
  end

  describe 'タグ登録' do
    it '単一登録' do
      visit '/song/83'; wait_for_ajax
      islack 'シンフォギア'
      iscontain 'タグが登録されていません'
      islack '登録済みタグ'
      add_tag 'シンフォギア'
      iscontain ['シンフォギア' , '登録済みタグ']
      islack 'タグが登録されていません'
      visit '/search/tag/?tag=%E3%82%B7%E3%83%B3%E3%83%95%E3%82%A9%E3%82%AE%E3%82%A2'
      iscontain 'タグ "シンフォギア" が登録された楽曲一覧(1件)'
    end
    it '複数登録' do
      tags = ['サザンオールスターズ' , '桑田佳祐' , 'my_dream' , 'TSUNAMI' , '２０００年']
      visit '/song/163'; wait_for_ajax
      islack tags
      add_tag tags.join(' ')
      iscontain tags
    end
    it '複数登録(10個以上)' do
      visit '/song/276'; wait_for_ajax
      add_tag "001 002 003 004 005 006 007 008 009 010 011 012 013"
      iscontain ['001' , '002' , '003' , '004' , '005' , '006' , '007' , '008' , '009' , '010']
      islack ['011' , '012' , '013']
      islack '追加'
    end
    it '空白を含んだ登録' do
      visit '/song/242'
      add_tag "A B   C　D　　　E"
      tags = `zenra mysql -se "select name from tag where object = 242;"`.lines.each {|l| l.chomp!}
      expect(tags.length).to eq 5
      expect(tags.include?('')).to eq false
    end
    it 'キャンセル' do
      visit '/song/354'; wait_for_ajax
      islack '新しいタグ'
      js "$('#add_tag').click();"; wait_for_ajax
      script = "$('#popup_prompt').val('新しいタグ')"
      js script; wait_for_ajax
      find('#popup_cancel').click; wait_for_ajax
      islack '新しいタグ'
    end
    it 'ログインしていないと登録できない' do
      visit '/song/1'; wait_for_ajax
      iscontain '追加'
      visit '/auth/logout'
      visit '/song/1'; wait_for_ajax
      islack '追加'
    end
  end

  describe 'タグ削除' do
    it '削除' do
      visit '/search/tag/?tag=%E5%B7%A1%E9%9F%B3%E3%83%AB%E3%82%AB' #巡音ルカ
      iscontain 'タグ "巡音ルカ" が登録された楽曲一覧(8件)'
      examine_songlink 'Reboot' , 'ジミーサムP'; wait_for_ajax
      all('#tag_list_table > tbody > tr > td > img')[2].click; wait_for_ajax
      iscontain 'タグ [巡音ルカ] を削除します。よろしいですか？'
      find('#popup_ok').click; wait_for_ajax
      islack '巡音ルカ'
      visit '/search/tag/?tag=%E5%B7%A1%E9%9F%B3%E3%83%AB%E3%82%AB' #巡音ルカ
      iscontain 'タグ "巡音ルカ" が登録された楽曲一覧(7件)'
    end
    it 'キャンセル' do
      visit '/song/270'; wait_for_ajax
      iscontain 'がくっぽいど'
      all('#tag_list_table > tbody > tr > td > img')[1].click; wait_for_ajax
      find('#popup_cancel').click; wait_for_ajax
      iscontain 'がくっぽいど'
    end
    it '他の人が登録したタグは削除できない' do
      login 'sa2knight'
      visit '/song/270'; wait_for_ajax
      expect(all('#tag_list_table > tbody > tr > td > img').count).to eq 2
      login 'hetare'
      visit '/song/270'; wait_for_ajax
      expect(all('#tag_list_table > tbody > tr > td > img').count).to eq 0
      visit '/logout'
      visit '/song/270'; wait_for_ajax
      expect(all('#tag_list_table > tbody > tr > td > img').count).to eq 0
    end
  end

  describe 'タグ検索' do
    it 'タグ検索へのリンク' do
      visit '/song/231'
      iscontain ['VOCALOID' , '初音ミク']
      all('.song-tag')[0].click
      iscontain 'タグ "VOCALOID" が登録された楽曲一覧(109件)'
    end
    it '楽曲ページヘのリンク' do
      visit '/search/tag/?tag=VOCALOID'
      examine_songlink 'カミサマネジマキ' , 'kemu'
    end
    it '歌手ページヘのリンク' do
      visit '/search/tag/?tag=VOCALOID'
      examine_artistlink 'ジミーサムP'
    end
  end
end
