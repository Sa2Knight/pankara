require 'capybara/rspec'
require 'simplecov'
require 'capybara-webkit'
require 'headless'
require 'tilt/erb'
require_relative '../app/controllers/index_route'

# テストカバレッジを実行
SimpleCov.start do
  add_filter "/vendor/" #ライブラリはカバレッジから除外
end

RSpec.configure do |config|
  
  # テストに失敗した時点で以降のテストを行わない
  config.fail_fast = true

  # 実行順に依存したテストを排除するために、テスト順をランダムに
  config.order = "random"

  # JavaScript対応のために、仮想ディスプレイを構築
  # Xvfb: X window systemの仮想ディスプレイを構築するソフトウェア
  config.before :suite do
    ENV['DISPLAY'] = 'localhost:1.0'
    system "Xvfb :1 -screen 0 1024x768x16 -nolisten inet6 &"
    system "sleep 1s"
  end
  config.after :suite do
    system "killall Xvfb"
    system "sleep 1s"
  end
  
  # ブラウザの挙動のシミュレートにCapybaraを用いる
  config.include Capybara::DSL          #Capybaraを使うことを宣言
  Capybara.app = Rack::Builder.parse_file("config.ru").first
  Capybara.javascript_driver = :webkit  #HTMLレンダリングにはwebkitを用いる
  Capybara.default_max_wait_time = 10   #最大待ち時間は10秒
  Capybara::Webkit.configure do |config|
    config.block_unknown_urls           #GETに失敗した際のエラーメッセージを抑制
  end                                   #Youtubeのサムネイル取得に失敗することが多々あるため
end
