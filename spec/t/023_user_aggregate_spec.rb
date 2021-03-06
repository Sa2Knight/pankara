require_relative '../rbase'
include Rbase

# テスト用データベース構築
init = proc do
  `zenra init -d 2017_07_02_17_42`
  User.create('test_user' , 'test_user' , 'test_user')
end

# テスト実行
describe '集計情報表示機能' do

  before(:all , &init)

  it '歌唱履歴のあるユーザ' do
    login 'sa2knight'
    visit '/user/userpage'
    iscontain '集計情報を表示'
    visit '/user/aggregate/sa2knight'
    iscontain ['カラオケ記録' , '歌唱記録' , '機種別集計' , '採点別集計' , 'その他']
    expect(table_to_hash('karaoke_aggregate_table')[0]['tostring']).to eq '総カラオケ時間,288.0 時間'
    expect(table_to_hash('sang_aggregate_table')[1]['tostring']).to eq '持ち歌手数,200 組'
    expect(table_to_hash('product_aggregate_table')[5]['tostring']).to eq 'LIVE DAM,8 回,282 曲'
    expect(table_to_hash('score_aggregate_table')[3]['tostring']).to eq 'DAM ランキングバトル,76 曲,92.03 点,83.25 点'
  end

  it '歌唱履歴のないユーザ' do
    login 'test_user'
    visit '/user/userpage'
    iscontain '集計情報を表示'
    visit '/user/aggregate/test'
    iscontain ['カラオケ記録' , '歌唱記録' , '機種別集計' , '採点別集計' , 'その他']
    expect(table_to_hash('karaoke_aggregate_table')[1]['tostring']).to eq '総出費,0 円'
    expect(table_to_hash('sang_aggregate_table')[1]['tostring']).to eq '持ち歌手数,0 組'
    expect(table_to_hash('product_aggregate_table')[4]['tostring']).to eq 'JOYSOUND WAVE,0 回,0 曲'
    expect(table_to_hash('score_aggregate_table')[2]['tostring']).to eq 'JOYSOUND その他,0 曲,0.0 点,0.0 点'
  end

end
