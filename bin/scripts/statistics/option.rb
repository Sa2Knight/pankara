#----------------------------------------------------------------------
# Option - コマンドライン引数によるオプションの指定を解析するクラス
#----------------------------------------------------------------------
require 'optparse'

class Option

  # initialize - オプションを設定する
  #---------------------------------------------------------------------
  def initialize
    OptionParser.new do |parser|
      @args = Hash.new

      parser.banner = 'Usage: zenra stat [--json] [--today] [--follow] [--from from] [--to to] [--list | --cnt [asc | desc] | --agg [-i | -n | -u | -r | -o | -b | -d] | --filter [-i | -n | -u | -r | -o | -b | -d] VALUE]'
      parser.on('--json', '指定するとJSON形式で標準出力を行う') {|v| @args['json'] = v}
      parser.on('--follow', '指定するとファイルの変更を監視してログを解析し続ける cnt, aggオプションと同時に指定した場合はこのオプションは無効になる') {|v| @args['follow'] = v}
      parser.on('--today', '指定すると本日のログのみを解析する') {|v| @args['today'] = v}
      parser.on('--from=DATE', 'YYYY-MM-DD 指定した日付を、解析するログの下限値に設定する') {|date| @args['from'] = date}
      parser.on('--to=DATE', 'YYYY-MM-DD 指定した日付を、解析するログの上限値に設定する') {|date| @args['to'] = date}
      parser.on('--list', '解析ログの一覧表示') {|v| @args['list'] = v}
      parser.on('--cnt [ORDER]',  ['asc', 'desc'], 
                'アクセス数の表示', 
                "\tasc\tアクセス数の昇順で並び替える",
                "\tdesc\tアクセス数の降順で並び替える") {|order| @args['cnt'] = order}
      parser.on('--agg=PARAM', ['-i', '-n', '-u', '-r', '-o', '-b', '-d', '-m'], 
                '指定したオプションに応じたリクエストの集計を行う', 
                "\ti\tIPアドレス別アクセス数", "\tn\tユーザ名別アクセス数",
                "\tu\tURL別アクセス数", "\tr\tリファラ別アクセス数",
                "\to\tOS別アクセス数", "\tb\tブラウザ別アクセス数",
                "\td\tデバイス別アクセス数", "\tm\tリクエストメソッド別アクセス数") {|value| @args['agg'] = convert_agg_option(value)}
      parser.on('--filter=PARAM VALUE',  ['-i', '-n', '-u', '-r', '-o', '-b', '-d', '-m'], 
                '指定したオプションと値に応じて集計するログにフィルタをかける', 
                "\ti\tIPアドレス", "\tn\tユーザ名",
                "\tu\tURL", "\tr\tリファラ",
                "\to\tOS", "\tb\tブラウザ",
                "\td\tデバイス", "\tm\tリクエストメソッド") {|value, a| @args['filter'] = {'param' => convert_agg_option(value), 'value' => ARGV.shift}}

      parser.parse!(ARGV)
    end 
  end

  # get - 指定されたオプションを取得する
  #---------------------------------------------------------------------
  def get(kind)
    return nil unless @args.key? kind
    
    if @args[kind]
      return @args[kind]
    else
      return 'none'
    end
  end

  # convert_agg_option - --aggの引数をdata_nameへ変換する
  #---------------------------------------------------------------------
  def convert_agg_option(value)
    case value
    when '-i'
      return 'ip'
    when '-n'
      return 'user'
    when '-u'
      return 'url'
    when '-r'
      return 'referer'
    when '-o'
      return 'os'
    when '-b'
      return 'blowser'
    when '-d'
      return 'device'
    when '-m'
      return 'request'
    when nil
      return nil
    else
      return 'error'
    end
  end

end
