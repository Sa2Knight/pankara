require_relative '../rbase'
include Rbase

# テスト用データベース構築
init = proc do
	`zenra init`
	User.create('sa2knight' , 'sa2knight' , 'ないと')
	user = User.new('sa2knight')

	register = Register.new(user)
	register.with_url = false
	register.create_karaoke(
		'2016-01-01 13:00:00' , '歌唱履歴テスト用カラオケ1' , 5 ,
		{'name' => 'カラオケ館' , 'branch' => '亀戸店'} ,
		{'brand' => 'JOYSOUND' , 'product' => 'MAX'} ,
	)
	register.attend_karaoke(1200 , '歌唱履歴テスト用attend1')
	register.create_history('BUMP OF CHICKEN' , '天体観測' , 0)
	register.create_history('SEKAI NO OWARI' , 'RPG' , -1)

	register.create_karaoke(
		'2016-01-02 13:00:00' , '歌唱履歴テスト用カラオケ2' , 5 ,
		{'name' => 'カラオケ館' , 'branch' => '亀戸店'} ,
		{'brand' => 'JOYSOUND' , 'product' => 'MAX'} ,
	)
	register.attend_karaoke(1500 , '歌唱履歴テスト用attend2')
	register.create_history('島谷ひとみ' , '亜麻色の髪の乙女' , -5)
end

# 定数定義
url = '/history'

# テスト実行
describe '歌唱履歴ページ' do
	before(&init)
	it '歌唱履歴が正常に表示されるか' do
		login 'sa2knight'
		visit url
		tables = table_to_hash('history_table')
		expect(tables[0]['tostring']).to eq "2016-01-02 13:00:00,歌唱履歴テスト用カラオケ2,亜麻色の髪の乙女,島谷ひとみ,-5"
		expect(tables[1]['tostring']).to eq "2016-01-01 13:00:00,歌唱履歴テスト用カラオケ1,天体観測,BUMP OF CHICKEN,0"
		expect(tables[2]['tostring']).to eq "2016-01-01 13:00:00,歌唱履歴テスト用カラオケ1,RPG,SEKAI NO OWARI,-1"
	end
	it 'リンクが正常に登録されているか' do
		login 'sa2knight'
		visit url
		examine_songlink('亜麻色の髪の乙女' , '島谷ひとみ')
		visit url
		examine_artistlink('SEKAI NO OWARI')
		#Todo カラオケへのリンクを検証
	end
end
