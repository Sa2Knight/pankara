require_relative '../rbase'
include Rbase

# テスト用データベース構築
init = proc do
  `zenra init -d 2016_02_14_17_39`
end

def prove(url , h2 , length , tostring)
  visit url
  table = table_to_hash('karaokelist_table')
  expect(page.find('h2').text).to eq h2
  expect(table.length).to eq length
  expect(table[0]['tostring']).to eq tostring
end

# テスト実行
describe 'カラオケ一覧機能' do
  before(:all , &init)
  before { login 'sa2knight' }
  it '全カラオケ一覧表示' do
    prove(
      'karaoke/list' , 'カラオケ一覧' , 5 , 
      '2016-02-05,ヒトカラ専用ルーム,1.5,快活CLUB 甚目寺店,DAM(LIVE DAM),,13')
  end
  it 'ログインユーザのカラオケ一覧表示' do
    prove(
      'karaoke/user' , 'ないとさんのカラオケ一覧' , 3 , 
      '2016-01-30,2016年 3/24回目,3.0,歌広場 亀戸店,JOYSOUND(CROSSO),,40,')
  end
  it '指定したユーザのカラオケ一覧表示' do
    prove(
      'karaoke/user/worry' , 'ウォーリーさんのカラオケ一覧' , 1 , 
      '2016-01-08,新年初カラオケ,5.0,JOYJOY 甚目寺店,JOYSOUND(MAX),,42')
  end
  describe 'カラオケの件数' do
    it '全カラオケ' do
      visit '/karaoke/list'
      expect(find('#karaoke_num').text()).to eq '5'
    end
    it 'ユーザのカラオケ' do
      visit '/karaoke/user/sa2knight'
      expect(find('#karaoke_num').text()).to eq '3'
    end
  end
  it 'リンクが正常か' , :js => true do
    visit '/karaoke/list'
    find('#karaokelist_table').all('tr')[3].click
    iscontain '2016年 2/24回目'
  end
end
